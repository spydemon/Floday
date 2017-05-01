package Floday::Deploy;

use v5.20;

use Floday::Helper::Config;
use Floday::Helper::Runlist;
use Floday::Lib::Linux::LXC;
use Log::Any qw($log);
use Moo;
use YAML::Tiny;

$Data::Dumper::Indent = 1;

has config => (
	default => sub {
		Floday::Helper::Config->instance();
	},
	is => 'ro',
	reader => 'getConfig'
);

has runfile => (
	default => sub {
		my ($this) = @_;
		$this->getConfig()->getFlodayConfig('floday', 'runfile')
	},
	is => 'ro',
	reader => 'getRunfile',
	required => 1,
	isa => sub {
		die "Runfile '$_[0]' is not readable" unless -r $_[0];
	}
);

has hostname => (
	is => 'ro',
	reader => 'getHostname',
	required => 1,
	isa => sub {
		die 'invalid hostname to run' unless $_[0] =~ /^[\w+]*$/;
	}
);

has runlist => (
	is => 'rw',
	lazy => 1,
	builder => sub {
	  Floday::Helper::Runlist->instance();
	},
	reader => 'getRunlist'
);

has log => (
	is => 'ro',
	default => sub {
	  Log::Any->get_logger;
  }
);

sub launch {
	my ($this, $instancePath) = @_;
	my %parameters = $this->getRunlist->getParametersForApplication($instancePath);
	$log->warningf('Launching %s application.', $parameters{instance_path});
	$this->log->{adapter}->indent_inc();
	my $container = Floday::Lib::Linux::LXC->new('utsname' => $parameters{instance_path});
	if ($container->is_existing) {
		$container->destroy;
	}
	$container->set_template($parameters{template});
	my ($state, $stdout, $stderr) = $container->deploy;
	die $stderr unless $state;
	$this->_runScripts($parameters{instance_path}, 'setups');
	$container->stop if $container->is_running;
	$container->start;
	for ($this->getRunlist->getApplicationsOf($parameters{instance_path})) {
		$this->launch($_);
	}
	$this->_runScripts($parameters{instance_path}, 'end_setups');
	$this->log->{adapter}->indent_dec();
}

#TODO: redundant with launch subroutine.
sub startDeployment {
	my ($this) = @_;
	my $yaml = YAML::Tiny->new(%{$this->getRunlist()->getCleanRunlist()});
	`mkdir -p /var/lib/floday` unless -d '/var/lib/floday';
	$yaml->write('/var/lib/floday/runlist.yml');
	unless ($this->getRunlist->getCleanRunlist->{hosts}{$this->getHostname}) {
		die $this->log->errorf('Host %s is unknown.', $this->getHostname);
	}
	$this->log->warningf('Deploying %s host', $this->getHostname);
	$this->log->{adapter}->indent_inc();
	$this->_runScripts($this->getHostname(), 'setups');
	for($this->getRunlist->getApplicationsOf($this->getHostname)) {
		$this->log->warningf('Start deployment of %s applications.', $this->getHostname);
		$this->log->{adapter}->indent_inc();
		$this->launch($_);
		$this->log->{adapter}->indent_dec();
		$this->log->warningf('End deployment of %s applications.', $this->getHostname);
	}
	$this->_runScripts($this->getHostname, 'end_setups');
	$this->log->{adapter}->indent_dec();
	$this->log->warningf('%s deployed.', $this->getHostname);
}

sub _runScripts {
	my ($this, $hostname, $family) = @_;
	$this->log->warningf('Start running %s scripts.', $family);
	my %scripts = $this->getRunlist()->getExecutionListByPriorityForApplication($hostname, $family);
	my $containersFolder = $this->getConfig()->getFlodayConfig('containers', 'path');
	for(sort {$a cmp $b} keys %scripts) {
		my $scriptPath = "$containersFolder/" . $scripts{$_}->{exec};
		$this->log->{adapter}->indent_inc();
		$this->log->infof('Running script: %s', $scriptPath);
		`$scriptPath --container $hostname`;
		$this->log->{adapter}->indent_dec();
	}
	$this->log->warningf('End running %s scripts.', $family);
}

1

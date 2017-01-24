package Floday::Deploy;

use v5.20;

use Data::Dumper;
use Floday::Helper::Config;
use Floday::Helper::Runlist;
use Log::Any qw($log);
use Moo;
use Virt::LXC;
use YAML::Tiny;

$Data::Dumper::Indent = 1;

has runfile => (
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
	builder => '_initializeRunlist',
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
	$this->log->{adapter}->indent_inc();
	my %parameters = $this->getRunlist->getParametersForApplication($instancePath);
	my $containersFolder = Floday::Helper::Config->new()->getFlodayConfig('containers', 'path');
	$log->infof('Launching %s application.', $parameters{instance_path});
	my $container = Virt::LXC->new('utsname' => $parameters{instance_path});
	my %startupScripts = $this->getRunlist->getSetupsByPriorityForApplication($parameters{instance_path});
	if ($container->is_existing) {
		$container->destroy;
	}
	$container->set_template($parameters{template});
	my ($state, $stdout, $stderr) = $container->deploy;
	die $stderr unless $state;
	for(sort {$a <=> $b} keys %startupScripts) {
		my $scriptPath = "$containersFolder/" . $startupScripts{$_}->{exec};
		$this->log->{adapter}->indent_inc();
		$this->log->infof('Running script: %s', $scriptPath);
		`$scriptPath --container $parameters{instance_path}`;
		$this->log->{adapter}->indent_dec();
	}
	$container->stop if $container->is_running;
	$container->start;
	for ($this->getRunlist->getApplicationsOf($parameters{instance_path})) {
		$this->launch($_);
	}
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
	$this->log->infof('Running %s host', $this->getHostname);
	$this->log->{adapter}->indent_inc();
	my %startupScripts = $this->getRunlist->getSetupsByPriorityForApplication($this->getHostname);
	my $containersFolder = Floday::Helper::Config->new()->getFlodayConfig('containers', 'path');
	for(sort {$a <=> $b} keys %startupScripts) {
		my $scriptPath = "$containersFolder/" . $startupScripts{$_}->{exec};
		my $hostname = $this->getHostname();
		$this->log->{adapter}->indent_inc();
		$this->log->infof('Running script: %s', $scriptPath);
		`$scriptPath --container $hostname`;
		$this->log->{adapter}->indent_dec();
	}
	for($this->getRunlist->getApplicationsOf($this->getHostname)) {
		$this->log->warningf('Starting deployment of %s host.', $this->getHostname);
		$this->launch($_);
	}
	$this->log->{adapter}->indent_dec();
	$this->log->infof('%s deployed.', $this->getHostname);
}

sub _initializeRunlist {
	my ($this) = @_;
	my $runlist = Floday::Helper::Runlist->new(runfile => $this->getRunfile);
	$runlist->getRawRunlist();
	if (@{$runlist->getRunlistErrors()}) {
		foreach (@{$runlist->getRunlistErrors()}) {
			$this->log->fatalf($_);
		}
		die $this->log->fatalf('Died because invalid runfile');
	}
	return $runlist;
}

1

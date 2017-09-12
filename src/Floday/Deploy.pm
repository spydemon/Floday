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
	reader => 'get_config'
);

has runfile => (
	default => sub {
		my ($this) = @_;
		$this->get_config()->get_floday_config('floday', 'runfile')
	},
	is => 'ro',
	reader => 'get_runfile',
	required => 1,
	isa => sub {
		die "Runfile '$_[0]' is not readable" unless -r $_[0];
	}
);

has hostname => (
	is => 'ro',
	reader => 'get_hostname',
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
	reader => 'get_runlist'
);

has log => (
	is => 'ro',
	default => sub {
	  Log::Any->get_logger;
  }
);

sub launch {
	my ($this, $instance_path) = @_;
	my %parameters = $this->get_runlist->get_parameters_for_application($instance_path);
	$log->warningf('Launching %s application.', $parameters{instance_path});
	$this->log->{adapter}->indent_inc();
	my $container = Floday::Lib::Linux::LXC->new('utsname' => $parameters{instance_path});
	if ($container->is_existing) {
		$container->destroy;
	}
	$container->set_template($parameters{template});
	my ($state, $stdout, $stderr) = $container->deploy;
	die $stderr unless $state;
	$this->_run_scripts($parameters{instance_path}, 'setups');
	$container->stop if $container->is_running;
	$container->start;
	for ($this->get_runlist->get_applications_of($parameters{instance_path})) {
		$this->launch($_);
	}
	$this->_run_scripts($parameters{instance_path}, 'end_setups');
	$this->log->{adapter}->indent_dec();
}

#TODO: redundant with launch subroutine.
sub start_deployment {
	my ($this) = @_;
	my $yaml = YAML::Tiny->new(%{$this->get_runlist()->get_clean_runlist()});
	`mkdir -p /var/lib/floday` unless -d '/var/lib/floday';
	$yaml->write('/var/lib/floday/runlist.yml');
	unless ($this->get_runlist->get_clean_runlist->{hosts}{$this->get_hostname}) {
		die $this->log->errorf('Host %s is unknown.', $this->get_hostname);
	}
	$this->log->warningf('Deploying %s host', $this->get_hostname);
	$this->log->{adapter}->indent_inc();
	$this->_run_scripts($this->get_hostname(), 'setups');
	$this->log->warningf('Start deployment of %s applications.', $this->get_hostname);
	$this->log->{adapter}->indent_inc();
	for($this->get_runlist->get_applications_of($this->get_hostname)) {
		$this->launch($_);
	}
	$this->log->{adapter}->indent_dec();
	$this->log->warningf('End deployment of %s applications.', $this->get_hostname);
	$this->_run_scripts($this->get_hostname, 'end_setups');
	$this->log->{adapter}->indent_dec();
	$this->log->warningf('%s deployed.', $this->get_hostname);
}

sub _run_scripts {
	my ($this, $hostname, $family) = @_;
	$this->log->warningf('Start running %s scripts.', $family);
	my %scripts = $this->get_runlist()->get_execution_list_by_priority_for_application($hostname, $family);
	my $containers_folder = $this->get_config()->get_floday_config('containers', 'path');
	for(sort {$a cmp $b} keys %scripts) {
		my $scriptPath = "$containers_folder/" . $scripts{$_}->{exec};
		$this->log->{adapter}->indent_inc();
		$this->log->infof('Running script: %s', $scriptPath);
		$this->log->{adapter}->indent_inc();
		print `$scriptPath --container $hostname`;
		$this->log->{adapter}->indent_dec();
		$this->log->{adapter}->indent_dec();
	}
	$this->log->warningf('End running %s scripts.', $family);
}

1

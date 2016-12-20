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
	for(sort keys %startupScripts) {
		say `$containersFolder/$startupScripts{$_}->{exec} --container $parameters{instance_path}`;
	}
	$container->stop if $container->is_running;
	$container->start;
	for ($this->getRunlist->getApplicationsOf($parameters{instance_path})) {
		$this->launch($_);
	}
}

sub startDeployment {
	my ($this) = @_;
	$this->log->warningf('Deploying %s host.', $this->getHostname);
	my $yaml = YAML::Tiny->new(%{$this->getRunlist()->getCleanRunlist()});
	$yaml->write('/var/lib/floday/runlist.yml');
	for($this->getRunlist->getApplicationsOf($this->getHostname)) {
		$this->launch($_);
	}
	$this->log->warningf('%s deployed.', $this->getHostname);
}

sub _initializeRunlist {
	my ($this) = @_;
	Floday::Helper::Runlist->new(runfile => $this->getRunfile);
}

1

package Floday::Deploy;

use v5.20;

use Data::Dumper;
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
		die 'runfile is not readable' unless -r $_[0];
	}
);

has hostname => (
	is => 'ro',
	reader => 'getHostname',
	required => 1,
	isa => sub {
		die 'invalid hostname to run' unless $_[0] =~ /^[a-zA-Z0-9]*$/;
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
	my ($this, $applicationName) = @_;
	my %parameters = $this->getRunlist->getParametersForApplication($applicationName);
	$log->infof('Launching %s application.', $parameters{name});
	my $container = Virt::LXC->new('utsname' => $parameters{name});
	my %startupScripts = $this->getRunlist->getSetupsByPriorityForApplication($parameters{name});
	if ($container->isExisting) {
		$container->destroy;
	}
	$container->setTemplate($parameters{template});
	my ($state, $stdout, $stderr) = $container->deploy;
	die $stderr unless $state;
	for(sort keys %startupScripts) {
		say `$startupScripts{$_}->{exec} --container $parameters{name}`;
	}
	$container->stop if $container->isRunning;
	$container->start;
	for ($this->getRunlist->getApplicationsOf($parameters{name})) {
		$this->launch ($_);
	}
}

sub startDeployment {
	my ($this) = @_;
	$this->log->warningf('Deploying %s host.', $this->getHostname);
	my $runlist = $this->getRunlist;
	my $plainRunlist = $runlist->getPlainData;
	my $yaml = YAML::Tiny->new(%{$runlist->getPlainData});
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

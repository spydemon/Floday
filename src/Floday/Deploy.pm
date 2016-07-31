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

sub getScriptsByPriorities {
	my ($scripts) = @_;
	my %output;
	while(my ($key, $value) = each %$scripts) {
		$output{$value->{priority}} = {
			'exec' => $value->{exec},
			'name' => $key
		};
	}
	return %output;
}

sub launch {
	my ($c) = @_;
	$log->infof('%s: launching', $c->{parameters}{name});
	my $container = Virt::LXC->new('utsname' => $c->{parameters}{name});
	my %startupScripts = getScriptsByPriorities($c->{setup});
	if ($container->isExisting) {
			$container->destroy;
	}
	$container->setTemplate($c->{parameters}{template});
	my ($state, $stdout, $stderr) = $container->deploy;
	die $stderr unless $state;
	for(sort keys %startupScripts) {
		say `$startupScripts{$_}->{exec} --container $c->{parameters}{name}`;
	}
	$container->stop if $container->isRunning;
	$container->start;
	for (values %{$c->{applications}}) {
		launch ($_);
	}
}

sub startDeployment {
	my ($this) = @_;
	$this->log->warningf('Deploying %s host.', $this->getHostname);
	my $runlist = $this->getRunlist;
	my $plainRunlist = $runlist->getPlainData;
	my $yaml = YAML::Tiny->new(%{$runlist->getPlainData});
	$yaml->write('/var/lib/floday/runlist.yml');
	my $applications = $plainRunlist->{hosts}{$this->getHostname}{applications};
	$this->log->info(Dumper $applications);
	for (values %{$applications}) {
		launch($_);
	}
}

sub _initializeRunlist {
	my ($this) = @_;
	Floday::Helper::Runlist->new(runfile => $this->getRunfile);
}

1

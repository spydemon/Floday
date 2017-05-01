package Floday::Helper::Runlist;

use v5.20;

use Floday::Helper::Config;
use Floday::Helper::Host;

use Data::Dumper;
use Log::Any;
use Moo;
use YAML::Tiny;

with 'MooX::Singleton';

has config => (
	is => 'ro',
	default => sub {
		Floday::Helper::Config->instance();
	},
	reader => 'getConfig'
);

has log => (
	is => 'ro',
	default => sub {
		Log::Any->get_logger;
	}
);

has runfile => (
	default => sub {
		my ($this) = @_;
		$this->getConfig->getFlodayConfig('floday', 'runfile')
	},
	is => 'ro',
	isa => sub {
		die 'runfile is not readable' unless -r $_[0];
	},
	reader => 'getRunFile',
	required => 1,
);

has runlistErrors => (
	default => sub{[]},
	is => 'rw',
	reader => 'getRunlistErrors'
);

has rawRunlist => (
	is => 'rw',
	lazy => 1,
	builder => '_initializeRunlist',
	reader => 'getRawRunlist'
);

has cleanRunlist => (
	is => 'rw',
	lazy => 1,
	builder => '_cleanRunlist',
	reader => 'getCleanRunlist'
);

sub BUILD {
	my ($this) = @_;
	$this->getRawRunlist();
	if (@{$this->getRunlistErrors()}) {
		foreach (@{$this->getRunlistErrors()}) {
			$this->log->fatalf($_);
		}
		die $this->log->fatalf('Died because invalid runfile');
	}
	return $this;
}

sub getApplicationsOf {
	my ($this, $applicationName) = @_;
	my $definition = $this->getDefinitionOf($applicationName);
	sort map{$_ = $applicationName . '-' . $_; $_} keys %{$definition->{applications}};
}

sub getDefinitionOf {
	my ($this, $applicationName) = @_;
	my @containerPath = split /-/, $applicationName;
	my $definition->{'applications'} = $this->getRunlist()->{'hosts'};
	for (@containerPath) {
		$definition = $definition->{'applications'}{$_};
	}
	return $definition;
}

sub getRunlist {
	my ($this) = @_;
	my $rn = $this->getCleanRunlist();
	return $rn;
}

sub getParametersForApplication {
	my ($this, $applicationName) = @_;
	%{$this->getDefinitionOf($applicationName)->{parameters}};
}

sub getExecutionListByPriorityForApplication {
	my ($this, $applicationName, $executionTypeFirstLevel, $executionTypeSecondLevel) = @_;
	return unless defined $this->getDefinitionOf($applicationName)->{$executionTypeFirstLevel};
	my %setups = %{$this->getDefinitionOf($applicationName)->{$executionTypeFirstLevel}};
	if (defined $executionTypeSecondLevel) {
		my $setupsRef = $setups{$executionTypeSecondLevel};
		return unless $setupsRef;
		%setups = %$setupsRef;
	}
	my %sortedScripts;
	while (my($key, $value) = each %setups) {
		$sortedScripts{$value->{priority}} = {
		  'exec' => $value->{exec},
		  'name' => $key
	  };
  }
  return %sortedScripts;
}

sub _cleanRunlist {
	my ($this, $rawData) = @_;
	my $first = 0;
	my $cleanRunlist;
	if (not defined $rawData) {
		$rawData = $this->getRawRunlist()->{'hosts'};
		$first = 1;
	}
	foreach $a (keys %$rawData) {
		foreach (keys %{$rawData->{$a}{'parameters'}}) {
			if (defined $rawData->{$a}{'parameters'}{$_}{'value'}) {
				$cleanRunlist->{$a}{'parameters'}{$_} = $rawData->{$a}{'parameters'}{$_}{'value'};
			}
		}
		if (defined $rawData->{$a}{'applications'}) {
			$cleanRunlist->{$a}{'applications'} = $this->_cleanRunlist($rawData->{$a}{'applications'});
		}
		if (defined $rawData->{$a}{'end_setups'}) {
			$cleanRunlist->{$a}{'end_setups'} = $rawData->{$a}{'end_setups'};
		}
		if (defined $rawData->{$a}{'hooks'}) {
			$cleanRunlist->{$a}{'hooks'} = $rawData->{$a}{'hooks'};
		}
		if (defined $rawData->{$a}{'setups'}) {
			$cleanRunlist->{$a}{'setups'} = $rawData->{$a}{'setups'};
		}
	}
	return {'hosts' => $cleanRunlist} if ($first);
	return $cleanRunlist;
}

sub _initializeRunlist {
	my ($this) = @_;
	my $hosts = YAML::Tiny->read($this->getRunFile())->[0]{hosts};
	my $hostsInitialized;
	for (keys %$hosts) {
		my $attributes = $hosts->{$_};
		$attributes->{parameters}{name} = $_;
		my $host = Floday::Helper::Host->new('runfile' => $attributes);
		$hostsInitialized->{'hosts'}{$_} = $host->toHash();
		push @{$this->getRunlistErrors()}, @{$host->getAllErrors()};
	}
	return $hostsInitialized;
}

1

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
	reader => 'get_config'
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
		$this->get_config->get_floday_config('floday', 'runfile')
	},
	is => 'ro',
	isa => sub {
		die 'runfile is not readable' unless -r $_[0];
	},
	reader => 'get_run_file',
	required => 1,
);

has runlist_errors => (
	default => sub{[]},
	is => 'rw',
	reader => 'get_runlist_errors'
);

has raw_runlist => (
	is => 'rw',
	lazy => 1,
	builder => '_initialize_runlist',
	reader => 'get_raw_runlist'
);

has clean_runlist => (
	is => 'rw',
	lazy => 1,
	builder => '_clean_runlist',
	reader => 'get_clean_runlist'
);

sub BUILD {
	my ($this) = @_;
	$this->get_raw_runlist();
	if (@{$this->get_runlist_errors()}) {
		foreach (@{$this->get_runlist_errors()}) {
			$this->log->fatalf($_);
		}
		die $this->log->fatalf('Died because invalid runfile');
	}
	return $this;
}

sub get_applications_of {
	my ($this, $application_name) = @_;
	my $definition = $this->get_definition_of($application_name);
	sort map{$_ = $application_name . '-' . $_; $_} keys %{$definition->{applications}};
}

sub get_definition_of {
	my ($this, $application_name) = @_;
	my @container_path = split /-/, $application_name;
	my $definition->{'applications'} = $this->get_runlist()->{'hosts'};
	for (@container_path) {
		$definition = $definition->{'applications'}{$_};
	}
	return $definition;
}

sub get_runlist {
	my ($this) = @_;
	my $rn = $this->get_clean_runlist();
	return $rn;
}

sub get_parameters_for_application {
	my ($this, $application_name) = @_;
	%{$this->get_definition_of($application_name)->{parameters}};
}

sub get_execution_list_by_priority_for_application {
	my ($this, $application_name, $execution_type_first_level, $execution_type_second_level) = @_;
	return unless defined $this->get_definition_of($application_name)->{$execution_type_first_level};
	my %setups = %{$this->get_definition_of($application_name)->{$execution_type_first_level}};
	if (defined $execution_type_second_level) {
		my $setups_ref = $setups{$execution_type_second_level};
		return unless $setups_ref;
		%setups = %$setups_ref;
	}
	my %sorted_scripts;
	while (my($key, $value) = each %setups) {
		$sorted_scripts{$value->{priority}} = {
		  'exec' => $value->{exec},
		  'name' => $key
	  };
  }
  return %sorted_scripts;
}

sub _clean_runlist {
	my ($this, $raw_data) = @_;
	my $first = 0;
	my $clean_runlist;
	if (not defined $raw_data) {
		$raw_data = $this->get_raw_runlist()->{'hosts'};
		$first = 1;
	}
	foreach $a (keys %$raw_data) {
		foreach (keys %{$raw_data->{$a}{'parameters'}}) {
			if (defined $raw_data->{$a}{'parameters'}{$_}{'value'}) {
				$clean_runlist->{$a}{'parameters'}{$_} = $raw_data->{$a}{'parameters'}{$_}{'value'};
			}
		}
		if (defined $raw_data->{$a}{'applications'}) {
			$clean_runlist->{$a}{'applications'} = $this->_clean_runlist($raw_data->{$a}{'applications'});
		}
		if (defined $raw_data->{$a}{'end_setups'}) {
			$clean_runlist->{$a}{'end_setups'} = $raw_data->{$a}{'end_setups'};
		}
		if (defined $raw_data->{$a}{'hooks'}) {
			$clean_runlist->{$a}{'hooks'} = $raw_data->{$a}{'hooks'};
		}
		if (defined $raw_data->{$a}{'setups'}) {
			$clean_runlist->{$a}{'setups'} = $raw_data->{$a}{'setups'};
		}
	}
	return {'hosts' => $clean_runlist} if ($first);
	return $clean_runlist;
}

sub _initialize_runlist {
	my ($this) = @_;
	my $hosts = YAML::Tiny->read($this->get_run_file())->[0]{hosts};
	my $hosts_initialized;
	for (keys %$hosts) {
		my $attributes = $hosts->{$_};
		$attributes->{parameters}{name} = $_;
		my $host = Floday::Helper::Host->new('runfile' => $attributes);
		$hosts_initialized->{'hosts'}{$_} = $host->to_hash();
		push @{$this->get_runlist_errors()}, @{$host->get_all_errors()};
	}
	return $hosts_initialized;
}

1

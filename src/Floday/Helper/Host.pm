package Floday::Helper::Host;

use v5.20;

use Carp;
use Floday::Helper::Container;
use Hash::Merge;
use Moo;

has runfile => (
  is => 'ro',
  isa => sub {
     no warnings 'uninitialized';
     my $hostName = $_[0]->{parameters}{name};
     my $hostType = $_[0]->{parameters}{type};
     die "Invalid name '$hostName' for host initialization" if $hostName !~ /^\w+$/;
     die "Invalid type '$hostType' for host initialization" if $hostType !~ /^\w+$/;
  },
  reader => '_get_attributes_from_runfile'
);

has instance_path_to_manage => (
  default => sub {
    my ($this) = @_;
    $this->_get_attributes_from_runfile()->{parameters}{name};
  },
  is => 'ro',
  isa => sub {
    die if $_[0] !~ /^[\w-]+$/;
  },
  lazy => 1, #The lazyness is a trick for ensuring us that this attribute is load after "runfile" one.
  reader => '_get_instance_path_to_manage'
);

has errors => (
  default => sub {[]},
  is => 'rw',
  reader => 'get_all_errors'
);

sub generate_runlist {
	my ($this) = @_;
	my $runlist = $this->to_hash();
	my @errors = @{$this->get_all_errors()};
	if (@errors > 0) {
		die(map{$_ . "\n"} @errors);
	}
	return $runlist;
}

sub to_hash {
	my ($this) = @_;
	my $runlist = $this->_get_instance_definition();
	my $current_instance_attributes_from_runfile = $this->_get_instance_to_manage_runfile_attributes();
	if (defined $current_instance_attributes_from_runfile->{applications}) {
		for (keys %{$current_instance_attributes_from_runfile->{applications}}) {
			$current_instance_attributes_from_runfile->{applications}{$_}{parameters}{name} =  $_;
			$runlist->{applications}{$_} =
			my $child = Floday::Helper::Host->new(
			  'runfile' => $this->_get_attributes_from_runfile,
			  'instance_path_to_manage' => $this->_get_instance_path_to_manage() . '-' . $_
			);
			$runlist->{applications}{$_} = $child->to_hash();
			push @{$this->get_all_errors()}, @{$child->get_all_errors};
		}
	}
	push @{$this->get_all_errors()}, $this->_check_runlist_integrity($runlist);
	return $runlist;
}

sub _check_runlist_integrity {
	my ($this, $runlist) = @_;
	my @_errors;
	for my $curr_param (keys %{$runlist->{parameters}}) {
		my $params_attributes = $runlist->{parameters}->{$curr_param};
		#TODO: boolean are not managed with YAML::Tiny! It could be nice to user real Yaml boolean instead of a string equals to "true".
		if (defined $params_attributes->{mandatory}
		  and $params_attributes->{mandatory} eq 'true'
		  and not (defined $params_attributes->{value})
		) {
			push @_errors, "The '$curr_param' mandatory parameter is missing in '$runlist->{parameters}{instance_path}{value}' application.";
		}
		if (defined $params_attributes->{pattern}
		  and defined $params_attributes->{value}
		  and $params_attributes->{value} !~ qr/$params_attributes->{pattern}/
		) {
			push @_errors, "'$curr_param' parameter in '$runlist->{parameters}{instance_path}{value}' has value '$params_attributes->{value}' that doesn't respect the '$params_attributes->{pattern}' regex.";
		}
	}
	return @_errors;
}

sub _get_instance_definition {
	my ($this) = @_;
	my $container_definition = Floday::Helper::Container->new()->get_container_definition($this->_get_container_path());
	$this->_merge_definition($container_definition);
}

sub _get_instance_to_manage_runfile_attributes {
	my $attributes_from_runfile;
	eval {
		use warnings FATAL => 'uninitialized';
		my ($this) = @_;
		$attributes_from_runfile->{applications}{$this->_get_attributes_from_runfile->{parameters}{name}} = $this->_get_attributes_from_runfile();
		for (split '-', $this->_get_instance_path_to_manage()) {
			$attributes_from_runfile = $attributes_from_runfile->{applications}{$_};
		}
	};
	die ("Missing name or type for an application") if $@ ne '';
	return $attributes_from_runfile;
}

sub _get_container_path {
	my $container_path;
	eval {
		use warnings FATAL => 'uninitialized';
		my ($this) = @_;
		my @container_type_path;
		my $runfile_config->{applications}{$this->_get_attributes_from_runfile()->{parameters}{name}} = $this->_get_attributes_from_runfile();
		for (split ('-', $this->_get_instance_path_to_manage())) {
			$runfile_config = $runfile_config->{applications}{$_};
			push @container_type_path, $runfile_config->{parameters}{type};
		}
		$container_path = join '-', @container_type_path;
	};
	die ("Missing name or type for an application") if $@ ne '';
	return $container_path;
}

sub _merge_definition {
	my ($this, $container_definition) = @_;
	my $runfile_attributes = $this->_get_instance_to_manage_runfile_attributes();
	$runfile_attributes = $runfile_attributes->{'parameters'};
	$container_definition->{parameters}{name}{value} = undef;
	$container_definition->{parameters}{name}{required} = 'true';
	$container_definition->{parameters}{type}{value} = undef;
	$container_definition->{parameters}{type}{required} = 'true';
	for (keys %$runfile_attributes) {
		croak ("Parameter '$_' present in runfile but that doesn't exist in container definition")
		  unless defined $container_definition->{parameters}{$_};
		$container_definition->{parameters}{$_}{value} = $runfile_attributes->{$_};
	}
	$container_definition->{parameters}{instance_path}{value} = $this->_get_instance_path_to_manage();
	$container_definition->{parameters}{container_path}{value} = $this->_get_container_path();
	return $container_definition;
}

1
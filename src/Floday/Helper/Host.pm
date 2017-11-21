package Floday::Helper::Host;

use v5.20;

use Carp;
use Floday::Helper::Container;
use Hash::Merge;
use Moo;

# Warning, the notion of "runlist" in this module is not exactly the same as in the rest of the application.
# Here, "drunlist" mean "dirty drunlist" : it's a representation of the runfile but inside a Perl hash.
# Outside of this module, "runlist" mean "clean drunlist" as it is produced in the Helper::Runlist module.
# It's for this reason that the name of the hash is "drunlist", instead of "runlist".
has drunlist => (
  is => 'ro',
  isa => sub {
     no warnings 'uninitialized';
     my $hostName = $_[0]->{parameters}{name};
     my $hostType = $_[0]->{parameters}{type};
     die "Invalid name '$hostName' for host initialization" if $hostName !~ /^\w+$/;
     die "Invalid type '$hostType' for host initialization" if $hostType !~ /^\w+$/;
  },
  reader => '_get_attributes_from_drunlist'
);

has application_path_to_manage => (
  default => sub {
    my ($this) = @_;
    $this->_get_attributes_from_drunlist()->{parameters}{name};
  },
  is => 'ro',
  isa => sub {
    die if $_[0] !~ /^[\w-]+$/;
  },
  lazy => 1, #The lazyness is a trick for ensuring us that this attribute is load after "drunlist" one.
  reader => '_get_application_path_to_manage'
);

has errors => (
  default => sub {[]},
  is => 'rw',
  reader => 'get_all_errors'
);

sub to_hash {
	my ($this) = @_;
	my $drunlist = $this->_get_application_definition();
	my $current_application_attributes_from_drunlist = $this->_get_application_to_manage_drunlist_attributes();
	if (defined $current_application_attributes_from_drunlist->{applications}) {
		for (keys %{$current_application_attributes_from_drunlist->{applications}}) {
			$current_application_attributes_from_drunlist->{applications}{$_}{parameters}{name} =  $_;
			$drunlist->{applications}{$_} =
			my $child = Floday::Helper::Host->new(
			  'drunlist' => $this->_get_attributes_from_drunlist,
			  'application_path_to_manage' => $this->_get_application_path_to_manage() . '-' . $_
			);
			$drunlist->{applications}{$_} = $child->to_hash();
			push @{$this->get_all_errors()}, @{$child->get_all_errors};
		}
	}
	push @{$this->get_all_errors()}, $this->_check_drunlist_integrity($drunlist);
	return $drunlist;
}

sub _check_drunlist_integrity {
	my ($this, $drunlist) = @_;
	my @_errors;
	for my $curr_param (keys %{$drunlist->{parameters}}) {
		my $params_attributes = $drunlist->{parameters}->{$curr_param};
		#TODO: boolean are not managed with YAML::Tiny! It could be nice to user real Yaml boolean instead of a string equals to "true".
		if (defined $params_attributes->{mandatory}
		  and $params_attributes->{mandatory} eq 'true'
		  and not (defined $params_attributes->{value})
		) {
			push @_errors, "The '$curr_param' mandatory parameter is missing in '$drunlist->{parameters}{application_path}{value}' application.";
		}
		if (defined $params_attributes->{pattern}
		  and defined $params_attributes->{value}
		  and $params_attributes->{value} !~ qr/$params_attributes->{pattern}/
		) {
			push @_errors, "'$curr_param' parameter in '$drunlist->{parameters}{application_path}{value}' has value '$params_attributes->{value}' that doesn't respect the '$params_attributes->{pattern}' regex.";
		}
	}
	return @_errors;
}

sub _get_application_definition {
	my ($this) = @_;
	my $container_definition = Floday::Helper::Container->new()->get_container_definition($this->_get_container_path());
	$this->_merge_definition($container_definition);
}

sub _get_application_to_manage_drunlist_attributes {
	my $attributes_from_drunlist;
	eval {
		use warnings FATAL => 'uninitialized';
		my ($this) = @_;
		$attributes_from_drunlist->{applications}{$this->_get_attributes_from_drunlist->{parameters}{name}} = $this->_get_attributes_from_drunlist();
		for (split '-', $this->_get_application_path_to_manage()) {
			$attributes_from_drunlist = $attributes_from_drunlist->{applications}{$_};
		}
	};
	die ("Missing name or type for an application") if $@ ne '';
	return $attributes_from_drunlist;
}

sub _get_container_path {
	my $container_path;
	eval {
		use warnings FATAL => 'uninitialized';
		my ($this) = @_;
		my @container_type_path;
		my $drunlist_config->{applications}{$this->_get_attributes_from_drunlist()->{parameters}{name}} = $this->_get_attributes_from_drunlist();
		for (split ('-', $this->_get_application_path_to_manage())) {
			$drunlist_config = $drunlist_config->{applications}{$_};
			push @container_type_path, $drunlist_config->{parameters}{type};
		}
		$container_path = join '-', @container_type_path;
	};
	die ("Missing name or type for an application") if $@ ne '';
	return $container_path;
}

sub _merge_definition {
	my ($this, $container_definition) = @_;
	my $drunlist_attributes = $this->_get_application_to_manage_drunlist_attributes();
	$drunlist_attributes = $drunlist_attributes->{'parameters'};
	$container_definition->{parameters}{name}{value} = undef;
	$container_definition->{parameters}{name}{mandatory} = 'true';
	$container_definition->{parameters}{type}{value} = undef;
	$container_definition->{parameters}{type}{mandatory} = 'true';
	for (keys %$drunlist_attributes) {
		croak ("Parameter '$_' present in drunlist but that doesn't exist in container definition")
		  unless defined $container_definition->{parameters}{$_};
		$container_definition->{parameters}{$_}{value} = $drunlist_attributes->{$_};
	}
	$container_definition->{parameters}{application_path}{value} = $this->_get_application_path_to_manage();
	$container_definition->{parameters}{container_path}{value} = $this->_get_container_path();
	return $container_definition;
}

1;

=head1 NAME

Floday::Helper::Host - Manage the Floday host.

=head1 VERSION

1.0.0

=head1 DESCRIPTION

This is an internal module used by Floday for managing the host.
You should not work directly with this module if you are not currently developing on Floday core.

=head1 AUTHORS

Floday team - http://dev.spyzone.fr/floday

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by the Floday team.

This program is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.

You should have received a copy of the GNU General Public License along
with this program. If not, see <http://www.gnu.org/licenses/>.

=cut
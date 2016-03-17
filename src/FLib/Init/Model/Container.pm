package FLib::Init::Model::Container;

#{{{POD
=pod

=head1 NAME

FLib::Init::Model::Container - Manage a single Floday container.

=head1 SYNOPSYS

 use FLib::Init::Model::Container;
 my $container = FLib::Init::Model::Container->new(<invocationAttributes>, <containerPath>);
 $container->boot();

=head1 DESCRIPTION

Manage a container unit.

=head2 Methods

=head3 new($invocationAttributes, $containerPath)

Initialize a container object.

=over 15

=item $invocationAttributes

A hash with the attribute name as key, and his value as value.
Those attributes will overload the ones present in container definition.
Usually, this hash represent container attributes present in the runfile.

=item $containerPath

The $containerPath string is used for identifying this container in the entire runlist.
It's thank to it that we know his parent and children.

=item return

An Flib::Init::Model::Container object.

=back

=head3 boot()

Will boot all child applications and containers.

=over 15

=item return

Nothing.

=back

=head1 AUTHOR

Kevin Hagner

=head1 SEE ALSO

Wiki and bug tracker of the entire Floday project can be found at: https://dev.spyzone.fr/floday.

=cut
#}}}

use v5.20;
use FLib::Init::Helper::DefinitionParser;
use FLib::Init::Model::Application;

sub new {
	my ($class, $containerInvocationAttributes, $containerPath) = @_;
	my %this;
	bless(\%this, $class);
	$this{path} = {$containerPath};
	$this{attributes} = {_getContainerAttributes($containerInvocationAttributes)};
	$this{containers} = _getChildContainers($containerInvocationAttributes, $containerPath);
	$this{definition} = FLib::Init::Helper::DefinitionParser->new($this{attributes}{type});
	$this{applications} = {_getChildApplications(\%this, $containerInvocationAttributes)};
	$this{parameters} = _initializeParameters(\%this);
	return \%this;
}

sub boot {
	my ($this) = @_;
	for (values %{$this->{applications}}) {
		$_->execute();
	}
	#TODO manage containers execution.
}

sub getChildContainers {
	my ($this) = @_;
	return $this->{containers};
}

sub _checkAttributes {
	my ($attributes) = @_;
	defined $attributes->{type} or die ("Mandatory type parameter is missing");
}

sub _getChildApplications {
	my ($this, $attributes) = @_;
	my %applications;
	foreach (keys %$attributes) {
		if (ref $attributes->{$_} eq 'HASH' && $attributes->{$_}{action} eq 'application') {
			$applications{$_} = $attributes->{$_};
			$applications{$_} = FLib::Init::Model::Application->new($attributes->{$_}, $this->{definition}{applications}{$applications{$_}{type}});
		}
	}
	return %applications;
}

sub _getChildContainers {
	my ($attributes, $currentPath) = @_;
	my @containers;
	foreach (keys %$attributes) {
		if (ref $attributes->{$_} eq 'HASH' && $attributes->{$_}{action} eq 'container') {
			push @containers, $currentPath . '-' . $_;
		}
	}
	return \@containers;
}

sub _getContainerAttributes {
	my ($nodes) = @_;
	my %attributes;
	foreach (keys %$nodes) {
		/["-]/ and die("Invalid character in $_ attribute");
		if (ref $nodes->{$_} ne 'HASH') {
			$nodes->{$_} =~ /[-"]/ and die("Invalid character in $_ value");
			$attributes{$_} = $nodes->{$_};
		}
	}
	_checkAttributes(\%attributes);
	return %attributes;
}

sub _initializeParameters {
	my ($this) = @_;
	my %attributes;
	for (keys %{$this->{definition}{parameters}}) {
		$attributes{$_} = $this->{definition}{parameters}{$_}{default};
		#$attributes{$_} = $this->{attributes}{$_};
		defined $this->{attributes}{$_} and $attributes{$_} = $this->{attributes}{$_};
		defined $this->{definition}{parameters}{$_}{mandatory} && !defined $this->{attributes}{$_}
		  and die ("Mandatory \"$_\" parameter is missing but required");
	}
	return %attributes;
}

1

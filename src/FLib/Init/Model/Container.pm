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

sub new {
	my ($class, $containerInvocationAttributes, $containerPath) = @_;
	my %this;
	bless(\%this, $class);
	$this{path} = {$containerPath};
	$this{parameters} = {_getContainerParameters($containerInvocationAttributes)};
	$this{applications} = {_getChildApplications($containerInvocationAttributes)};
	$this{containers} = _getChildContainers($containerInvocationAttributes, $containerPath);
	$this{definition} = FLib::Init::Helper::DefinitionParser->new($this{parameters}{type});
	return \%this;
}

sub boot {
	my ($this) = @_;
	#TODO manage applications execution.
	#TODO manage containers execution.
}

sub getChildContainers {
	my ($this) = @_;
	return $this->{containers};
}

sub _getChildApplications {
	my ($attributes) = @_;
	my %applications;
	foreach (keys %$attributes) {
		if (ref $attributes->{$_} eq 'HASH' && $attributes->{$_}{action} eq 'application') {
			$applications{$_} = $attributes->{$_};
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


sub _getContainerParameters {
	my ($attributes) = @_;
	my %parameters;
	foreach (keys %$attributes) {
		$parameters{$_} = $attributes->{$_} if (ref $attributes->{$_} ne 'HASH');
	}
	return %parameters;
}

1

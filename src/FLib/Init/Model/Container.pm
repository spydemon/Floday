package FLib::Init::Model::Container;

use v5.20;

sub new {
	my ($class, $containerInvocationAttributes, $containerPath) = @_;
	my %this;
	bless(\%this, $class);
	$this{path} = {$containerPath};
	$this{parameters} = {_getContainerParameters($containerInvocationAttributes)};
	$this{applications} = {_getChildApplications($containerInvocationAttributes)};
	$this{containers} = {_getChildContainers($containerInvocationAttributes, $containerPath)};
	return %this;
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
	return @containers;
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

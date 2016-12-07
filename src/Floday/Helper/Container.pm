package Floday::Helper::Container;

use v5.20;

use Floday::Helper::Config;
use Hash::Merge;
use Moo;
use YAML::Tiny;

sub getContainerDefinition {
	my ($this, $containerPath) = @_;
	my $containerDefinition = YAML::Tiny->read(
	  $this->getContainerDefinitionFilePath($containerPath)
	)->[0];
	for (@{$containerDefinition->{inherit}}) {
		$containerDefinition = Hash::Merge
		  ->new('LEFT_PRECEDENT')
		  ->merge($containerDefinition, $this->getContainerDefinition($_))
		;
	}
	return $containerDefinition;
}

sub getContainerDefinitionFilePath {
	my ($this, $containerPath) = @_;
	$this->getContainerDefinitionFolder($containerPath) . '/config.yml';
}

sub getContainerDefinitionFolder {
	my ($this, $containerPath) = @_;
	my @containersType = split '-', $containerPath;
	join('/',
	  Floday::Helper::Config->new()->getFlodayConfig('containers', 'path'),
	  shift @containersType,
	  (map {'children/' . $_} @containersType)
	);
}

1
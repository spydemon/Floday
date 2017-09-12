package Floday::Helper::Container;

use v5.20;

use Floday::Helper::Config;
use Hash::Merge;
use Moo;
use YAML::Tiny;

has config => (
	default => sub {
		Floday::Helper::Config->instance();
	},
	is => 'ro',
	reader => 'get_config'
);

sub get_container_definition {
	my ($this, $container_path) = @_;
	my $container_definition = YAML::Tiny->read(
	  $this->get_container_definition_file_path($container_path)
	)->[0];
	for (@{$container_definition->{inherit}}) {
		$container_definition = Hash::Merge
		  ->new('LEFT_PRECEDENT')
		  ->merge($container_definition, $this->get_container_definition($_))
		;
	}
	return $container_definition;
}

sub get_container_definition_file_path {
	my ($this, $container_path) = @_;
	$this->get_container_definition_folder($container_path) . '/config.yml';
}

sub get_container_definition_folder {
	my ($this, $container_path) = @_;
	my @containers_type = split '-', $container_path;
	join('/',
	  $this->get_config()->get_floday_config('containers', 'path'),
	  shift @containers_type,
	  (map {'children/' . $_} @containers_type)
	);
}

1
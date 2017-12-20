package Floday::Helper::Container;

use v5.20;

use Floday::Helper::Config;
use Floday::Helper::Schema::Container;
use Hash::Merge;
use Moo;
use YAML::Tiny;

#TODO: removing the word "container" in each subroutine?

has config => (
	default => sub {
		Floday::Helper::Config->instance();
	},
	is => 'ro',
	reader => 'get_config'
);

has schema => (
	default => sub {
		Floday::Helper::Schema::Container->new();
	},
	is => 'ro',
	reader => 'get_schema'
);

has container_path => (
	is => 'ro',
	reader => 'get_container_path',
	required => 1
);

has container_definition_file_content => (
	is => 'ro',
	lazy => 1,
	reader => 'get_container_definition_file_content',
	default => sub {
		my ($this) = @_;
		my $content = YAML::Tiny->read(
		  $this->get_container_definition_file_path()
		)->[0];
		$this->_validate_json_format($content);
		return $content;
	}
);

sub get_container_definition {
	my ($this) = @_;
	my $container_definition = $this->get_container_definition_file_content();
	for ($this->get_container_parents()) {
		$container_definition = Hash::Merge
		  ->new('LEFT_PRECEDENT')
		  ->merge($container_definition, $_->get_container_definition())
		;
	}
	return $container_definition;
}

sub get_container_definition_file_path {
	my ($this) = @_;
	$this->get_container_definition_folder() . '/config.yml';
}

sub get_container_definition_folder {
	my ($this) = @_;
	my @containers_type = split '-', $this->get_container_path();
	join('/',
	  $this->get_config()->get_floday_config('containers', 'path'),
	  shift @containers_type,
	  (map {'children/' . $_} @containers_type)
	);
}

sub get_container_parents {
	my ($this) = @_;
	my @parents;
	my $container_definition = $this->get_container_definition_file_content();
	for (@{$container_definition->{inherit}}) {
		push @parents, __PACKAGE__->new('container_path' => $_);
	}
	return @parents;
}

sub _validate_json_format {
	my ($this, $json) = @_;
	my @errors;
	push @errors, $this->get_schema()->validate($json);
	if (@errors > 0) {
		@errors = sort @errors;
		my $errors_string;
		my $container_path = $this->get_container_path();
		map {$errors_string .= $_->path . ': ' . $_->message . "\n"} @errors;
		die ("Errors in $container_path definition:\n", $errors_string);
	}
}

1;

=head1 NAME

Floday::Helper::Container - Manage the Floday containers.

=head1 VERSION

1.1.1

=head1 SYNOPSYS

  use Floday::Helper::Container;

  my $container = Floday::Helper::Container->new(
    'container_path' => 'riuk-web-integration'
  );
  say $container->get_container_definition();
  say $container->get_container_definition_file_path();
  say $container->get_container_definition_folder();

=head1 DESCRIPTION

This module is used for managing a Floday container.
It is mainly used internally but could also by used for "meta" tasks on applications depending of its containers implementation.

=head2 Object instantiation

=head3 new('container_path' => $container_path)

=over 17

=item $container_path

A string representing the container path that the object will manage.

=back

=head2 Object methods

=head3 get_container_definition_file_content()

Return in a "dummy" way, the content of the the "config.yml" definition file associated to the current container.
"Dummy" means that no processing is done on it but conversion into a hash.

=head3 get_container_definition()

Will iterate through the configuration file that define the current container and will merge it with all its parents.
The resulting hash is given back and represent all attributes (setups, end_setup, parameters, etc.) available for the given container.

=head3 get_container_definition_file_path()

Will return a string that represents the path to the definition file of the given container.

=head3 get_container_definition_folder()

Will return a string that reprents the path to the root folder of the container definition.
This folder contains the "config.yml" file with all the container definition, but it should also contains all external scripts like setups and end_setups ones that are "owned" by this container.
It's not mandatory for the moment that those external scripts are in this folder (or in its sub-folder) but it's strongly recommended for avoiding mess.

=head3 get_container_parents()

Will return an array with new Floday::Helper::Container objects for each parent containers that the current one has.

=head3 get_container_path()

Return a string that represents the container path of the current container.

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

package Floday::Helper::Container;

use v5.20;

use Floday::Helper::Config;
use Floday::Helper::Schema::Container;
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

has schema => (
	default => sub {
		Floday::Helper::Schema::Container->new();
	},
	is => 'ro',
	reader => 'get_schema'
);

sub get_container_definition {
	my ($this, $container_path) = @_;
	my @errors;
	my $container_definition = YAML::Tiny->read(
	  $this->get_container_definition_file_path($container_path)
	)->[0];
	push @errors, $this->get_schema()->validate($container_definition);
	if (@errors > 0) {
		@errors = sort @errors;
		my $errors_string;
		map {$errors_string .= $_->path . ': ' . $_->message . "\n"} @errors;
		die ("Errors in $container_path definition:\n", $errors_string);
	}
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

1;

=head1 NAME

Floday::Helper::Container - Manage the Floday containers.

=head1 VERSION

1.1.2

=head1 DESCRIPTION

This is an internal module used by Floday for managing the containers.
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

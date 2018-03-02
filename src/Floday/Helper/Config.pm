package Floday::Helper::Config;

use v5.20;

use Config::Tiny;
use File::Temp;
use Moo;

with 'MooX::Singleton';

has floday_config_file => (
  is => 'lazy',
  reader => '_get_floday_config_file'
);

has floday_config_root_folder => (
  default => '/etc/floday',
  is => 'ro',
  reader => '_get_floday_config_root_folder',
  required => 1
);

sub get_floday_config {
	my ($this, $section, $key) = @_;
	die ("Undefined key") unless defined $key;
	my $value = $this->_get_floday_config_file()->{$section}{$key};
	die ("Undefined '$key' key in Floday configuration '$section' section")
	  unless defined $value;
	return $value;
}

sub _build_floday_config_file {
	my ($this) = @_;
	my $unified_file = new File::Temp();
	my $config_folder = $this->_get_floday_config_root_folder() . '/config.d';
	my $config_old_file = $this->_get_floday_config_root_folder() . '/floday.cfg';
	my @config_files;
	if (-d $config_folder) {
		opendir(my $config_folder_fh, $config_folder);
		push @config_files,
		  map {"$config_folder/$_"}
		  grep {/\.cfg$/}
		  readdir($config_folder_fh);
		@config_files = sort @config_files;
	}
	if (-f $config_old_file) {
		unshift @config_files, $config_old_file;
	}
	`cat $_ >> $unified_file && echo "\n" >> $unified_file`
	  for (@config_files);
	my $cfg = Config::Tiny->read($unified_file);
	close $unified_file;
	die ("Unable to load Floday configuration file ($Config::Tiny::errstr)")
	  unless defined $cfg;
	return $cfg;
}

1;

=head1 NAME

Floday::Helper::Config - Manage the Floday configuration.

=head1 VERSION

1.2.0

=head1 SYNOPSIS

  #!/usr/bin/env perl

  use strict;
  use warnings;
  use v5.20;

  use Floday::Helper::Config;

  my $config = Floday::Helper::Config->instance();
  my $import_folder = $config->get_floday_config('jaxe', 'import_folder');

=head1 DESCRIPTION

This is a helper that allows you to fetch data from the Floday "/etc/floday/floday.cfg" configuration file.
This file has to be in the .ini format.

=head2 Module subroutines

=head3 instance()

Subroutine that return the Floday::Helper::Config singleton.

=head3 get_floday_config($self, $section, $key)

=over 15

=item $section

String that represents the section into which the key should be fetch.

=back

=over 15

=item $key

String that represents the key to fetch.

=back

=over 15

=item return

A string with the parameter value, if it exists.
The subroutine will die if the parameter was not found.

=back

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

package Floday::Helper::Config;

use v5.20;

use Config::Tiny;
use Moo;

with 'MooX::Singleton';

has floday_config_file => (
  builder => sub {
    my $cfg = Config::Tiny->read('/etc/floday/floday.cfg');
    die ("Unable to load Floday configuration file ($Config::Tiny::errstr)") unless defined $cfg;
    return $cfg;
  },
  is => 'ro',
  reader => '_get_floday_config_file'
);

sub get_floday_config {
	my ($this, $section, $key) = @_;
	die ("Undefined key") unless defined $key;
	my $value = $this->_get_floday_config_file()->{$section}{$key};
	die ("Undefined '$key' key in Floday configuration '$section' section") unless defined $value;
	return $value;
}

1;

=head1 NAME

Floday::Helper::Config - Manage the Floday configuration.

=head1 VERSION

1.0.2

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

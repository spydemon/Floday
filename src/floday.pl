#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;

use FindBin;
use lib ($FindBin::Bin);
chdir $FindBin::Bin;

my $message_version = '1.1.2';
my $message_help = <<EOF
Usage: Floday --host <hostname> [--loglevel <loglevel>] [--help] [--version]

Version: $message_version

Options:
  --help     : print this help.
  --host     : provide the host to deploy.
  --loglevel : logging level to display, default: info.
  --version  : print only the actual version number.

Read the doc for knowing more about Floday!
EOF
;

use Floday::Deploy;
use Floday::Helper::Config;
use Getopt::Long;
use Log::Any;
use Log::Any::Adapter('+Floday::Helper::Logging');

my $host;
my $loglevel;
my $help;
my $version;
GetOptions('host=s', \$host, 'loglevel=s', \$loglevel, 'help', \$help, 'version', \$version);

say $message_help and exit 1 if $help;
say $message_version and exit 1 if $version;

$host // die('Host to launch is missing');
$loglevel //= 'info';

Log::Any->get_logger()->{adapter}->reset();
Log::Any->get_logger()->{adapter}->loglevel_set($loglevel);

$0 = "floday --host $host";
my $floday = Floday::Deploy->new(hostname => $host);
$floday->start_deployment;

=pod

=head1 NAME

Floday - Server manager.

=head1 VERSION

1.1.2

=head1 DESCRIPTION

Floday manage all your servers by running LXC containers for each of your applications!
Read the documentation in PDF provided with this version of the software for knowing more about it!

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

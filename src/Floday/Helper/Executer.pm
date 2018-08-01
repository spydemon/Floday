package Floday::Helper::Executer;

use strict;
use warnings;
use v5.20;

use Backticks;
use Carp;
use Moo;

$Backticks::autodie = 0;

our @EXPORT = ('execute_script');

has config => (
	default => sub {
		Floday::Helper::Config->instance();
	},
	is => 'ro',
	reader => 'get_floday_config'
);

has log => (
	is => 'ro',
	default => sub { Log::Any->get_logger },
);

sub execute_script {
	my ($this, $relative_path, $application_path) = @_;
	unless($application_path) {
		croak("Application name is missing for the execution of the $relative_path script");
	}
	my $working_directory = $this->get_floday_config()->get_floday_config('containers', 'path');
	$this->log->infof('Running script: %s', $relative_path);
	$this->log->{adapter}->indent_inc();
	my $result = `$working_directory/$relative_path --application $application_path`;
	unless ($result->success()) {
		$this->log->errorf("Error occurred: %s\n%s", $result->error(), $result->stderr());
	}
	$this->log->debugf('Stdout: %s', $result->stdout());
	$this->log->{adapter}->indent_dec();
}

1;

=head1 NAME

Floday::Helper::Executer - Code factorisation module for executing a script on an application.

=head1 VERSION

1.3.0

=head1 DESCRIPTION

This is an internal module used by Floday for deploying a host.
You should not work directly with this module if you are not currently developing on Floday core.

=head1 AUTHORS

Floday team - http://dev.spyzone.fr/floday

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by the Floday team.

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

package Floday::Helper::Logging;

use strict;
use warnings;
use v5.20;

use Log::Any::Adapter::Base;
use Log::Any::Adapter::Util qw(logging_methods detection_methods numeric_level);
our @ISA = qw(Log::Any::Adapter::Base);

use Floday::Helper::Config;
use Unix::Syslog qw{:macros :subs};

my $CONFIG = new Floday::Helper::Config->new();

my %SYSLOG_PRIORITY_MAPPER = (
  trace     => LOG_DEBUG,
  debug     => LOG_DEBUG,
  info      => LOG_INFO,
  inform    => LOG_INFO,
  notice    => LOG_NOTICE,
  warning   => LOG_WARNING,
  warn      => LOG_WARNING,
  error     => LOG_ERR,
  err       => LOG_ERR,
  critical  => LOG_CRIT,
  crit      => LOG_CRIT,
  fatal     => LOG_CRIT,
  alert     => LOG_ALERT,
  emergency => LOG_EMERG,
);

my %PREFFIX_PRIORITY_MAPPER = (
  trace => 'DBG',
  debug => 'DBG',
  info => 'INFO',
  inform => 'INFO',
  notice => 'INFO',
  warning => 'WARN',
  warn => 'WARN',
  error => 'ERR',
  err => 'ERR',
  critical => 'CRIT',
  crit => 'CRIT',
  fatal => 'CRIT',
  alert => 'EMGY',
  emergency => 'EMGY'
);

my $PATH = $CONFIG->get_floday_config('logging', 'metadata_folder');
my $INDENT_FILE = 'indent';
my $LOGLEVEL_FILE = 'loglevel';
my $FATAL_FLAG_FILE = 'fatal';
my $FATAL_FLAG_LEVEL = numeric_level('error');

sub indent_dec {
	my $indent = indent_get();
	$indent -= 1;
	$indent = 1 if $indent < 1;
	`echo $indent > $PATH/$INDENT_FILE`;
}

sub indent_get {
	`mkdir -p $PATH` unless -d $PATH;
	`touch $PATH/$INDENT_FILE` unless -f "$PATH/$INDENT_FILE";
	my $indent = `cat $PATH/$INDENT_FILE`;
	chomp $indent;
	$indent || 1;
}

sub indent_inc {
	my $indent = indent_get();
	$indent += 1;
	`echo $indent > $PATH/$INDENT_FILE`;
}

sub flag_fatal_set {
	`echo 1 > $PATH/$FATAL_FLAG_FILE`;
}

sub flag_fatal_get {
	-f "$PATH/$FATAL_FLAG_FILE";
}

sub identifier_set {
	# If no new identifier was given in parameter, we keep the old one present in the environment variable.
	# If nothing is present in the environment variable, we take the default "floday" identifier.
	my ($self, $identifier) = (@_);
	$identifier = $identifier // $ENV{'FLODAY_LOGGING_IDENTIFIER'} // 'floday';
	$ENV{'FLODAY_LOGGING_IDENTIFIER'}  = $identifier;
	closelog();
	openlog($identifier, 0, 0);
}

sub init {
	my ($self) = @_;
	$self->{log_level} = numeric_level('trace') unless defined $self->{log_level};
	$self->{log_level} = numeric_level($self->{log_level}) unless $self->{log_level} =~ /^\d+$/;
	$self->identifier_set();
	die ('The logging level provided is unknown') unless defined $self->{log_level};
}

sub loglevel_get {
	my $loglevel = `cat $PATH/$LOGLEVEL_FILE 2>/dev/null`;
	chomp $loglevel;
	$loglevel ? $loglevel : numeric_level('debug');
}

sub loglevel_set {
	my ($self, $loglevel) = @_;
	my $numeric_loglevel = numeric_level($loglevel);
	die ("Unexisting $loglevel loglevel") unless $numeric_loglevel;
	`echo $numeric_loglevel > $PATH/$LOGLEVEL_FILE`;
}

sub reset {
	`mkdir -p $PATH` unless -d $PATH;
	`rm -r $PATH/*`;
}

#TODO: text formater should be splitted in a single subroutine.
foreach my $method (logging_methods()) {
	no strict 'refs';
	*{$method} = sub {
		my $self = shift @_;
		my $text = join(' ', @_);
		my $bold = ($text =~ s/^(BOLD )//) ? 1 : 0;
		if (numeric_level($method) <= $FATAL_FLAG_LEVEL) {
			flag_fatal_set();
			$bold = 1;
		}
		my @text_lines = split "\n", $text;
		my ($mod) = caller(2) // '';
		if (@text_lines == 1) {
			$text = sprintf('%6s %30s: %s %s',
			  '[' . $PREFFIX_PRIORITY_MAPPER{$method} . ']',
			  substr($mod, -30),
			  ' ' x indent_get($self),
			  $text
			);
			syslog($SYSLOG_PRIORITY_MAPPER{$method}, '%s', $text);
			$text = `tput bold` . $text . `tput sgr0` if ($bold);
			say STDOUT $text if numeric_level($method) <= loglevel_get();
		} else {
			my $first_line = 1;
			for (@text_lines) {
				if ($first_line) {
					$text = sprintf('%6s %30s: %s %s',
					  '[' . $PREFFIX_PRIORITY_MAPPER{$method} . ']',
					  substr($mod, -30),
					  ' ' x indent_get($self),
					  $_
					);
					$first_line = 0;
				} else {
					$text = sprintf('%6s %30s| %s %s',
					  '',
					  '',
					  ' ' x indent_get($self),
					  $_
					);
				}
				say STDOUT $text if numeric_level($method) <= loglevel_get();
				syslog($SYSLOG_PRIORITY_MAPPER{$method}, '%s', $text);
			}
		}
	}
}

foreach my $method (detection_methods()) {
	no strict 'refs';
	my $name = substr($method, 3);
	my $numeric_level = numeric_level($name);
	*{$method} = sub {
		my ($self) = @_;
		return $self->{log_level} >= $numeric_level;
	}
}

1;

=head1 NAME

Floday::Helper::Logging - Log::Any Floday adapter.

=head1 VERSION

1.2.1

=head1 SYNOPSIS

  #!/usr/bin/env perl
  use strict;
  use warnings;
  use v5.20;

  use Log::Any;
  use Log::Any::Adapter('+Floday::Helper::Logging');

  my $log = Log::Any->get_logger;
  Log::Any->get_logger()->{adapter}->reset();
  $log->{adapter}->identifier_set('My_script');
  $log->info('Start script');
  $log->{adapter}->indent_inc();
  $log->notice('Doing something.');
  $log->{adapter}->indent_dec();
  $log->info('End updater');

=head1 DESCRIPTION

You can use this module if you want to extends Floday logging manager to your custom scripts.
Of course, this should only be done if your script has something to do with the deployment.

=head2 The indentation notion

For a clarification purpose, an indentation notion exists in Floday for allowing log reader to directly see in which
context a log message occurs.
Here is an example:

  [WARN]                 Floday::Deploy:   Deploying websites host
  [WARN]                 Floday::Deploy:    Start running setups scripts.
  [INFO]                 Floday::Deploy:     Running script: /etc/floday/containers/jaxe/setups/iptables_flush.pl
  [INFO]                 Floday::Deploy:     Running script: /etc/floday/containers/jaxe/setups/dns.pl
   [ERR]        Floday::Lib::Linux::LXC:      lxc-attach: failed to get the init pid
  [INFO]                 Floday::Deploy:     Running script: /etc/floday/containers/jaxe/setups/updater.pl
  [WARN]                 Floday::Deploy:    End running setups scripts.
  [WARN]                 Floday::Deploy:    Start deployment of websites applications.
  [WARN]                 Floday::Deploy:     Launching website-web_application application.
  [WARN]                 Floday::Deploy:      Start running setups scripts.
  [INFO]                 Floday::Deploy:       Running script: /etc/floday/containers/jaxe/children/core/setups/networking.pl
  [INFO]                 Floday::Deploy:       Running script: /etc/floday/containers/jaxe/children/core/setups/cleaning.pl
  [INFO]                 Floday::Deploy:       Running script: /etc/floday/containers/jaxe/children/core/setups/updater.pl
  [INFO]                 Floday::Deploy:       Running script: /etc/floday/containers/jaxe/children/www/setups/lighttpd.pl

We can directly conclude that the "failed to get the init pid" error occurs in the setup script "dns.pl" that was running
for the "websites" host.

=head2 Write bold messages

If the first word present in the log message is "BOLD", the entire line will be write in bold on stdout.
By default, all messages with a log level higher or equal than "error" will also be display in bold.

=head2 Object methods

=head3 identifier_set($self, $identifier)

The identifier is the first word that will be put on each Syslog message.
It's in general the name of the program.
This field is the equivalent of the $programname rsyslog variable.

This subroutine set in fact a FLODAY_LOGGING_IDENTIFIER environment variable that is concretly used by the logger.
It means that this variable could also be set by hand and should be passed to LXC containers when we attach a new
process in them (it's the Floday default behavior).

=head3 indent_dec($self)

Decrease the logging indentation.

=head3 indent_get($self)

Get the current level of indentation.

=head3 indent_inc($self)

Increment the logging indentation.

=head3 init($self)

Internal subroutine for Log::Any.

=head3 loglevel_get($self)

Return the numeric value corresponding to the smalest log level that will be displayed.

=head3 loglevel_set($self, $loglevel)

Define the smalest log level that will be displayed in logs.
This subroutine should be called in floday main file.
Eg: if set to 'warning', the log messages of severity 'info', 'notice' and 'debug' will not be shown.

=head3 reset($self)

Bring the indentation level to zero.
It's useful when we start a new deployment for avoiding log shifting if a previous one crashes but it should not be used
in the middle of them.
This mean you should never use this subroutine.

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

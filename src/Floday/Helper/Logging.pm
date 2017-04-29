package Floday::Helper::Logging;

use strict;
use warnings;
use v5.20;

use Log::Any::Adapter::Base;
use Log::Any::Adapter::Util qw(logging_methods detection_methods numeric_level);
our @ISA = qw(Log::Any::Adapter::Base);

use Term::ANSIColor;
use Unix::Syslog qw{:macros :subs};

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

my %COLOR_PRIORITY_MAPPER = (
  trace     => 'bright_cyan',
  debug     => 'bright_cyan',
  info      => 'yellow',
  inform    => 'yellow',
  notice    => 'green',
  warning   => 'yellow',
  warn      => 'yellow',
  error     => 'red',
  err       => 'red',
  critical  => 'red',
  crit      => 'red',
  fatal     => 'bold red',
  alert     => 'bold red',
  emergency => 'bold red'
);

our $INDENT = 1;

sub indent_dec {
	$INDENT--;
}

sub indent_get {
	$INDENT;
}

sub indent_inc {
	$INDENT++;
}

sub init {
	my ($self) = @_;
	$self->{log_level} = 'trace' unless defined $self->{log_level};
	$self->{log_level} = numeric_level($self->{log_level}) unless $self->{log_level} =~ /^\d+$/;
	die ('The logging level provided is unknown') unless defined $self->{log_level}
}

foreach my $method (logging_methods()) {
	no strict 'refs';
	*{$method} = sub {
		my $self = shift @_;
		my $text = join(' ', @_);
		my @text_lines = split "\n", $text;
		my ($mod) = caller(2) // '';
		if (@text_lines == 1) {
			$text = '•' x indent_get($self) . ' ' . $mod . ': ' . $text;
			say STDOUT colored($text, $COLOR_PRIORITY_MAPPER{$method});
			syslog($SYSLOG_PRIORITY_MAPPER{$method}, '%s', $text);
		} else {
			my $first_line = 1;
			for (@text_lines) {
				if ($first_line) {
					$text = '•' x indent_get($self). '|' .$mod;
					$text .= "\n" . ' ' x indent_get($self). '|' . $_;
					$first_line = 0;
				} else {
					$text = ' ' x indent_get($self).'|'.$_;
				}
				say STDOUT colored($text, $COLOR_PRIORITY_MAPPER{$method});
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
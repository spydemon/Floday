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

sub init {
	my ($self) = @_;
	$self->{log_level} = numeric_level('trace') unless defined $self->{log_level};
	$self->{log_level} = numeric_level($self->{log_level}) unless $self->{log_level} =~ /^\d+$/;
	die ('The logging level provided is unknown') unless defined $self->{log_level}
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
		my @text_lines = split "\n", $text;
		my ($mod) = caller(2) // '';
		if (@text_lines == 1) {
			$text = sprintf('%6s %30s: %s %s',
			  '[' . $PREFFIX_PRIORITY_MAPPER{$method} . ']',
			  substr($mod, -30),
			  ' ' x indent_get($self),
			  $text
			);
			say STDOUT $text if numeric_level($method) <= loglevel_get();
			syslog($SYSLOG_PRIORITY_MAPPER{$method}, '%s', $text);
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
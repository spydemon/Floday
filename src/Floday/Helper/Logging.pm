package Floday::Helper::Logging;

use strict;
use warnings;
use v5.20;

use Log::Any::Adapter::Base;
use Log::Any::Adapter::Util qw(logging_methods detection_methods numeric_level);
our @ISA = qw(Log::Any::Adapter::Base);

sub init {
	my ($self) = @_;
	#I don't know how to set this log_level from the adapter initialisation… If you know the answer, please write me an email. ^^"
	$self->{log_level} = 'trace' unless defined $self->{log_level};
	$self->{log_level} = numeric_level($self->{log_level}) unless $self->{log_level} =~ /^\d+$/;
	die ('The logging level provided is unknown') unless defined $self->{log_level}
}

foreach my $method (logging_methods()) {
	no strict 'refs';
	*{$method} = sub {
		my ($self, $text) = @_;
		say STDOUT $text;
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
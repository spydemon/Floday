#!/usr/bin/perl

use strict;
use warnings;

use v5.20;

use Getopt::Long;
use TAP::Harness;

my $debug = 0;
GetOptions('debug', \$debug);

my %args = (
	verbosity => $debug ? 1 : 0,
	lib => [$ENV{FLODAY_T_SRC}],
	color => 1
);

my $harness = TAP::Harness->new(\%args);
my @testFiles;
my $filter = $ARGV[0] // '.*';
opendir(DIR,$ENV{FLODAY_T}.'integration/');
while (readdir DIR) {
	/^$filter\.t$/ and push @testFiles, $ENV{FLODAY_T}.'integration/'.$_
}

$harness->runtests(@testFiles);

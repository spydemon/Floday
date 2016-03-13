#!/usr/bin/perl

use strict;
use warnings;

use v5.20;

use TAP::Harness;

my %args = (
	verbosity => 1,
	lib => [$ENV{FLODAY_T_SRC}],
	color => 1
);

my $harness = TAP::Harness->new(\%args);
my @testFiles;
opendir(DIR,$ENV{FLODAY_T});
while (readdir DIR) {
	/\.t$/ and push @testFiles, $ENV{FLODAY_T}.$_
}

$harness->runtests(@testFiles);

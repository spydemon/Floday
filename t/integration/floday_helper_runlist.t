#!/usr/bin/env perl

use v5.20;

use Test::More;

use Floday::Helper::Runlist;

my $test = Floday::Helper::Runlist->new(runfile => 'floday.d/runfile.yml');

done_testing;

#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;

use Log::Any::Adapter('+Floday::Helper::Logging', 'log_level', 'trace');
use Test::Exception;
use Test::More;

use Floday::Deploy;

my $runlist = '/var/lib/floday/runlist.yml';
-f $runlist and `rm $runlist`;

throws_ok {Floday::Deploy->new()}
  qr/Missing required arguments: hostname/, 'Check if the hostname attribut is set.';
throws_ok {Floday::Deploy->new(hostname => 'not-valid')}
  qr/invalid hostname to run/, 'Check if the hostname attribut has a filter.';
my $test = Floday::Deploy->new(hostname => 'integration');
$test->startDeployment;

`rm $runlist`;
done_testing;

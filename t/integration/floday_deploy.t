#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;

use Data::Dumper;
use Log::Any::Adapter('File', 'log.txt');
use Test::Exception;
use Test::More;

use Floday::Deploy;

my $runlist = '/var/lib/floday/runlist.yml';
-f $runlist and `rm $runlist`;

throws_ok {Floday::Deploy->new(runfile => 'floday.d/runfile.yml')}
  qr/Missing required arguments: hostname/, 'Check if the hostname attribut is set.';
throws_ok {Floday::Deploy->new(hostname => 'not-valid', runfile => 'floday.d/runfile.yml')}
  qr/invalid hostname to run/, 'Check if the hostname attribut has a filter.';
throws_ok {Floday::Deploy->new(hostname => 'integration')}
  qr/Missing required arguments: runfile/, 'Check if the hostname attribut has a filter.';
throws_ok {Floday::Deploy->new(hostname => 'integration', runfile => 'floday.d/nonexisting.yml')}
  qr/runfile is not readable/, 'Check if the runfile attribut has a filter.';
my $test = Floday::Deploy->new(hostname => 'integration', runfile => 'floday.d/runfile.yml');
$test->startDeployment;

`rm $runlist`;
done_testing;

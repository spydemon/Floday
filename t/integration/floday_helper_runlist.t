#!/usr/bin/env perl

use v5.20;

use Data::Dumper;
use Log::Any::Adapter('File', 'log.txt');
use Test::Deep;
use Test::More;

use Floday::Helper::Runlist;

$Data::Dumper::Indent = 1;

my $test = Floday::Helper::Runlist->new(runfile => 'floday.d/runfile.yml');
my @children = $test->getApplicationsOf('integration-web');
cmp_deeply(\@children, ['integration-web-secondtest', 'integration-web-test']), 'Test of getApplicationsOf seems good.';
my %parameters = $test->getParametersForApplication('integration-web-secondtest');
is $parameters{bridge}, 'lxcbr0', 'Test of getParametersForApplication seems good.';
my %scripts = $test->getSetupsByPriorityForApplication('integration-web-test');
cmp_deeply([sort keys %scripts], [10, 20, 30], 'getSetupsByPriorityForApplication seems to correctly apply priorities.');

done_testing;

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
say Dumper @children;
cmp_deeply(\@children, ['integration-web-secondtest', 'integration-web-test']);

done_testing;

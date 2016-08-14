#!/usr/bin/env perl

use lib '/opt/floday/src/';

use v5.20;
use Floday::Setup;
use Log::Any::Adapter('File', 'log.txt');

my $application = Floday::Setup->new('applicationName' => $ARGV[1]);
my $lxc = $application->getLxcInstance;
my $data_in = $application->getParameter('data_in');
my $data_out = $application->getParameter('data_out');

$lxc->start if $lxc->isStopped;
$lxc->put($data_in, $data_out);

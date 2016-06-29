#!/usr/bin/env perl

use lib '/opt/floday/src/';

use v5.20;
use Floday::Setup;
use Log::Any::Adapter('File', 'log.txt');

my $container = Floday::Setup->new('containerName' => $ARGV[1]);
my $lxc = $container->getLxcInstance;
my $data_in = $container->getParameter('data_in');
my $data_out = $container->getParameter('data_out');

$lxc->start if $lxc->isStopped;
$lxc->put($data_in, $data_out);

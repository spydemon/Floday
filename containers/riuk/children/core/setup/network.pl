#!/usr/bin/env perl

use lib '/opt/floday/src/';

use v5.20;
use strict;
use Floday::Setup;
use Log::Any::Adapter('File', 'log.txt');

my $container = Floday::Setup->new('containerName', $ARGV[1]);
my $lxc = $container->getLxcInstance;
my $definition = $container->getDefinition;
$lxc->start if $lxc->isStopped;

$container->generateFile('/opt/floday/containers/riuk/children/core/setup/network.tt', $definition->{parameters}, '/etc/network/interfaces');

$lxc->exec('rc-update add networking');
$lxc->stop;

#!/usr/bin/env perl

use lib '/opt/floday/src/';

use v5.20;
use strict;
use Floday::Setup;
use Log::Any::Adapter('File', 'log.txt');

my $application = Floday::Setup->new('instancePath', $ARGV[1]);
my $lxc = $application->getLxcInstance;
my $definition = $application->getDefinition;
$lxc->start if $lxc->is_stopped;

$application->generateFile('/opt/floday/containers/riuk/children/core/setups/network.tt', $definition->{parameters}, '/etc/network/interfaces');
$lxc->exec('echo "nameserver 8.8.8.8" > /etc/resolv.conf');

$lxc->exec('rc-update add networking');
$lxc->stop;

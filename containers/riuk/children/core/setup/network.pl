#!/usr/bin/env perl

use lib '/opt/floday/src/';

use v5.20;
use strict;
use Floday::Setup;
use Template::Alloy;
use Log::Any::Adapter('File', 'log.txt');

my $container = Floday::Setup->new('containerName', $ARGV[1]);
my $lxc = $container->getLxcInstance;
my $definition = $container->getDefinition;
$lxc->start if $lxc->isStopped;

## Parse in a user-friendly way a configuration file with an hash.
my $interface = File::Temp->new();
my $t = Template::Alloy->new(
	ABSOLUTE => 1,
);
$t->process('/opt/floday/containers/riuk/children/core/setup/network.tt', $definition->{parameters}, $interface) or die $t->error;
die 'The container doesn\'t exist' if !$lxc->isExisting;
$lxc->put($interface, '/etc/network/interfaces');

## Other setup instructions.
$lxc->exec('rc-update add networking');
$lxc->stop;

#!/usr/bin/env perl

use lib '/opt/floday/src/';

use v5.20;
use strict;
use Floday::Setup;
use Log::Any::Adapter('File', 'log.txt');

my $lxc = $APP->get_lxc_instance;
my $definition = $APP->get_definition;
$lxc->start if $lxc->is_stopped;

$APP->generate_file('riuk/children/core/setups/network.tt', $definition->{parameters}, '/etc/network/interfaces');
$lxc->exec('echo "nameserver 8.8.8.8" > /etc/resolv.conf');

$lxc->exec('rc-update add networking');
$lxc->stop;

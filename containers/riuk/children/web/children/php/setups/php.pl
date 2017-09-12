#!/usr/bin/env perl

use lib '/opt/floday/src/';

use v5.20;
use strict;
use Floday::Setup;
use Log::Any::Adapter('File', 'log.txt');

my $lxc = $APP->get_lxc_instance;
my $definition = $APP->get_definition;
$lxc->start if $lxc->is_stopped;

my @cmd = ('apk update', 'apk upgrade', 'apk add php5-fpm', 'rc-update add php-fpm');
for (@cmd) {
	$lxc->exec($_);
}

$APP->generate_file('riuk/children/web/children/php/setups/php/php-fpm.conf.tt', $definition->{parameters}, '/etc/php5/php-fpm.conf');
$lxc->stop and $lxc->start;

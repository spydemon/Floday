#!/usr/bin/env perl

use lib '/opt/floday/src/';

use v5.20;
use strict;
use Floday::Setup;
use YAML::Tiny;
use Template::Alloy;
use Log::Any::Adapter('File', 'log.txt');

my $container = Floday::Setup->new('containerName', $ARGV[1]);
my $lxc = $container->getLxcInstance;
my $definition = $container->getDefinition;
$lxc->start if $lxc->isStopped;

my @cmd = ('apk update', 'apk upgrade', 'apk add php5-fpm', 'rc-update add php-fpm');
for (@cmd) {
	$lxc->exec($_);
}

my $phpConf = File::Temp->new();
my $t = Template::Alloy->new(
	ABSOLUTE => 1,
);
$t->process('/opt/floday/containers/riuk/children/web/children/php/setup/php/php-fpm.conf.tt', $definition, $phpConf) or die $t->error;
$lxc->put($phpConf, '/etc/php/php-fpm.conf');

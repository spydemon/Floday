#!/usr/bin/env perl

use lib '/opt/floday/src/';

use v5.20;
use YAML::Tiny;
use Data::Dumper;
use Getopt::Long;
use File::Temp;
use Virt::LXC;
use Template::Alloy;
use strict;

$Data::Dumper::Indent = 1;

my $runlist = YAML::Tiny->read('/var/lib/floday/runlist.yml');
my $c;
GetOptions(
	"container=s" => \$c
);

my ($h, $a) = $c =~ /(.*?)-(.*)/;
my $definition = $runlist->[1]->{$h};

for (split /-/, $a) {
	$definition = $definition->{applications}->{$_};
}

my $container = Virt::LXC->new($definition->{parameters}{name});
$container->start if $container->isStopped;

my @cmd = ('apk update', 'apk upgrade', 'apk add php-fpm', 'rc-update add php-fpm');
for (@cmd) {
	$container->exec($_);
}

my $phpConf = File::Temp->new();
my $t = Template::Alloy->new(
	ABSOLUTE => 1,
);
$t->process('/opt/floday/containers/riuk/children/web/children/php/setup/php/php-fpm.conf.tt', $definition->{parameters}, $phpConf) or die $t->error;
$container->put($phpConf, '/etc/php/php-fpm.conf');

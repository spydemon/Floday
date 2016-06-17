#!/usr/bin/env perl

use v5.20;
use strict;
use Virt::LXC;
use Test::More;

my @containers = ('integration-web', 'integration-web-test', 'integration-web-secondtest');
for (@containers) {
	my $c = Virt::LXC->new('utsname' => $_);
	$c->isExisting and $c->destroy;
}

`../../src/floday.pl --host integration` or die $!;

sleep 5;
ok `lxc-info -n integration-web -i -H`, '10.0.3.5';
ok `lxc-info -n integration-web-test -i -H`, '10.0.3.6';
ok `lxc-info -n integration-web-secondtest -i -H`, '10.0.3.7';
is `curl -s test.keh.keh/index.php`, 'Dans test.', 'Container integration-web-test is working.';
is `curl -s test2.keh.keh/index.php`, 'Dans secondtest.', 'Container integration-web-testsecond is working.';

my @containers = ('integration-web', 'integration-web-test', 'integration-web-secondtest');
for (@containers) {
	my $c = Virt::LXC->new('utsname' => $_);
	$c->isExisting and $c->destroy;
}

done_testing;

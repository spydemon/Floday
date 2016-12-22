#!/usr/bin/env perl

use v5.20;
use strict;

use Virt::LXC;
use Test::More;
use Test::Exception;
use Log::Any::Adapter('File', 'log.txt');

my $runlist = '/var/lib/floday/runlist.yml';
-f $runlist and `rm $runlist`;

my @containers = ('integration-web', 'integration-web-test', 'integration-web-secondtest');
for (@containers) {
	my $c = Virt::LXC->new('utsname' => $_);
	$c->is_existing and $c->destroy;
}

my $err = `../../src/floday.pl 2>&1 1>/dev/null`;
ok $err =~ /Host to launch is missing/, 'Error throwed because host cli parameter is missing.';
$err = `../../src/floday.pl --host integration 2>&1 1>/dev/null`;
ok $err =~ /Runfile is missing/, 'Error throwed because runfile cli parameter is missing.';
$err = `../../src/floday.pl --host integration --runfile /notexisting 2>&1 1>/dev/null`;
ok $err =~ /Runfile is not readable/, 'Error throwed because runfile is not readable.';

`../../src/floday.pl --host integration --runfile /opt/floday/t/integration/floday.d/runfile.yml` or die $!;

sleep 5;
ok `lxc-info -n integration-web -i -H`, '10.0.3.5';
ok `lxc-info -n integration-web-test -i -H`, '10.0.3.6';
ok `lxc-info -n integration-web-secondtest -i -H`, '10.0.3.7';
is `curl -s test.keh.keh/index.php`, 'Dans test.', 'Container integration-web-test is working.';
is `curl -s test2.keh.keh/index.php`, 'Dans secondtest.', 'Container integration-web-testsecond is working.';

my @containers = ('integration-web', 'integration-web-test', 'integration-web-secondtest');
#for (@containers) {
#	my $c = Virt::LXC->new('utsname' => $_);
#	$c->isExisting and $c->destroy;
#}

`rm $runlist`;

done_testing;

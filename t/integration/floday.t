#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;

use Backticks;
use Floday::Lib::Linux::LXC;
use Test::More;
use Test::Exception;
use Log::Any::Adapter('+Floday::Helper::Logging', 'log_level', 'trace');

$Backticks::autodie = 0;

my $runlist = '/var/lib/floday/runlist.yml';
-f $runlist and `rm $runlist`;

my @containers = ('integration-web', 'integration-web-test', 'integration-web-secondtest');
for (@containers) {
	my $c = Floday::Lib::Linux::LXC->new('utsname' => $_);
	$c->is_existing and $c->destroy;
}
`rm /tmp/floday/test_lxc_hooks` if -r '/tmp/floday/test_lxc_hooks';
my $err = `../../src/floday.pl 2>&1 1>/dev/null`;
ok $err =~ /Host to launch is missing/, 'Error throwed because host cli parameter is missing.';

`../../src/floday.pl --host integration` or die $!;

sleep 5;
ok (`lxc-info -n integration-web -i -H`->stdout(), '10.0.3.5');
ok (`lxc-info -n integration-web-test -i -H`->stdout(), '10.0.3.6');
ok (`lxc-info -n integration-web-secondtest -i -H`->stdout(), '10.0.3.7');
is (`curl -s test.keh.keh/index.php`->stdout(), 'Dans test.', 'Container integration-web-test is working.');
is (`curl -s test2.keh.keh/index.php`->stdout(), 'Dans secondtest.', 'Container integration-web-testsecond is working.');

`rm $runlist`;

my $log_testing = Backticks->new('../../src/floday.pl --host integration --loglevel notexisting');
eval { $log_testing->run(); };
like($log_testing->stderr(), qr/Unexisting notexisting loglevel/, 'Check that the --loglevel parameter is taken into account.');

cmp_ok(`../../src/floday.pl --version`->stdout(), 'eq', "1.1.2\n", 'Check the --version option.');
like(`../../src/floday.pl --help`->stdout(), qr/^Usage: Floday/, 'Check the --help option.');

done_testing;

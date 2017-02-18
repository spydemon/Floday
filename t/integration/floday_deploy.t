#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;
use threads;

use Log::Any::Adapter('+Floday::Helper::Logging', 'log_level', 'trace');
use Test::Exception;
use Test::More;

use Floday::Deploy;

my $runlist = '/var/lib/floday/runlist.yml';
-f $runlist and `rm $runlist`;

throws_ok {Floday::Deploy->new()}
  qr/Missing required arguments: hostname/, 'Check if the hostname attribut is set.';
throws_ok {Floday::Deploy->new(hostname => 'not-valid')}
  qr/invalid hostname to run/, 'Check if the hostname attribut has a filter.';
my $test = Floday::Deploy->new(hostname => 'integration');

my $hook_lxc_deploy_before_test = threads->create(sub {
  sleep 5;
  -f '/tmp/floday/test_lxc_hooks'
});

$test->startDeployment;

ok ($hook_lxc_deploy_before_test->join(), 'The test file was correctly created by the lxc_deploy_before hook.');
ok ((!-f '/tmp/floday/test_lxc_hooks'), 'The test file was correctly removed by the lxc_deploy_after hook.');

like(`cat /var/lib/lxc/integration-web/rootfs/etc/endsetup`, qr/end_setup works/, 'end_setups scripts seem to work.');

`rm $runlist`;
done_testing;

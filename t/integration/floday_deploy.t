#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;
use threads;

use File::stat;
use Linux::LXC;
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
  my $application_path = `cat /tmp/floday/test_lxc_hooks`;
  chomp $application_path;
  return $application_path;
});

$test->start_deployment;

cmp_ok ($hook_lxc_deploy_before_test->join(), 'eq', 'integration-web', 'lxc_deploy_before seems to have acces to the $APP variable.');
ok ((!-f '/tmp/floday/test_lxc_hooks'), 'The test file was correctly removed by the lxc_deploy_after hook.');

like(`cat /var/lib/lxc/integration-web/rootfs/etc/endsetup`, qr/end_setup works/, 'end_setups scripts seem to work.');

`rm $runlist`;

#We rerun the deployement for testing lxc hook on container destruction.
$test->start_deployment;
my $containers_before_last_destruction = `cat /tmp/floday/lxc_destroy_before`;
my $containers_after_last_destruction = `cat /tmp/floday/lxc_destroy_after`;
chomp $containers_before_last_destruction;
chomp $containers_after_last_destruction;
cmp_ok (($containers_before_last_destruction - $containers_after_last_destruction), '==' , 1, 'Hooks on lxc destroy action seems broken.');
`rm /tmp/floday/lxc_destroy_before`;
`rm /tmp/floday/lxc_destroy_after`;

#Test of the avoidance

my @containers = ('avoidance-skipped_nonexisting');
for (@containers) {
	my $c = Linux::LXC->new('utsname' => $_);
	$c->is_existing and $c->stop && $c->destroy;
}
`rm -rf /tmp/floday/avoidance` if -d '/tmp/floday/avoidance';

my $avoidance_test = Floday::Deploy->new(hostname => 'avoidance');
my $as_container_config_path = '/var/lib/lxc/avoidance-successful/config';
my $as_container_initial_timestamp = stat($as_container_config_path)->mtime;
eval{$avoidance_test->start_deployment};

my $was_as_container_redeployed = $as_container_initial_timestamp - stat($as_container_config_path)->mtime;
ok (!-r '/tmp/floday/avoidance/avoidance-skipped_nonexisting/avoidance_script_lanched', 'Check that avoidable scripts are not executed when and application is not existing');
ok ($was_as_container_redeployed == 0, 'If an application is flagged as avoidable, it\'s not deployed anymore.');
ok (-f '/tmp/floday/avoidance/avoidance-completely_failed/avoidable', 'Check that avoidable scripts are launched if application is considered as unavoidable.');
ok (-f '/tmp/floday/avoidance/avoidance-completely_failed/mandatory', 'Check that mandatory scripts are launched if application is considered as unavoidable.');
ok (-f '/tmp/floday/avoidance/avoidance-partially_failed/avoidable', 'Check that avoidable scripts are launched if application is considered as partially avoidable.');
ok (-f '/tmp/floday/avoidance/avoidance-partially_failed/mandatory', 'Check that mandatory scripts are launched if application is considered as partially avoidable.');
ok (!-r '/tmp/floday/avoidance/avoidance-successful/avoidable', 'Check that avoidable scripts are NOT launched if application is considered as fully avoidable.');
ok (-f '/tmp/floday/avoidance/avoidance-successful/mandatory',  'Check that mandatory scripts are launched if application is considered as fully avoidable.');
ok (-f '/tmp/floday/avoidance/avoidance-default/default', 'Check that a container without avoidance scripts are always considered as unavoidable.');

throws_ok {Floday::Deploy->new(hostname => 'avoidance', 'force_unavoidable' => 2)}
  qr/invalid value for force_unavoidable/,
  'Check the validity of the force_unavoidable flag';
Floday::Deploy->new(hostname => 'avoidance', 'force_unavoidable' => 1)->start_deployment;
$was_as_container_redeployed = $as_container_initial_timestamp - stat($as_container_config_path)->mtime;
ok ($was_as_container_redeployed < 0, 'Check that the force_unavoidable flag works.');
say "$was_as_container_redeployed";

my $test_log_fatal_flag = Floday::Deploy->new('hostname' => 'fatal_log');
my $result = $test_log_fatal_flag->start_deployment;
cmp_ok ($result, '==', 2, 'Check that if we log something with the "error" level or higher, Floday will return 2.');

done_testing;

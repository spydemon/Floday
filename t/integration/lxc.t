#!/usr/bin/env perl

use v5.20;
use strict;
use Virt::LXC;
use Test::More;
use Test::Exception;
use Log::Any::Adapter('File', 'log.txt');

my $container = Virt::LXC->new(utsname => 'lxc-test');
$container->setTemplate('alpine');
$container->destroy if $container->isExisting;
ok !$container->isExisting, 'isExisting return false.';
is $container->getLxcPath, '/var/lib/lxc/lxc-test', 'LxcPath has the good default value.';
throws_ok {$container->getConfig('lxc.network.ipv4')}
  qr/Container lxc-test doesn't exist/, 'Error throwed because container is not existing.';

$container->deploy;
ok $container->isExisting, 'isExisting returns true.';
ok grep{'lxc-test'} `lxc-ls -1`, 'Container is not created.';
ok grep{'lxc-test'} $container->getExistingContainers, 'Container is present in getExistingContainers.';
ok grep{'lxc-test'} $container->getStoppedContainers, 'Container is present in getStoppedContainers.';
ok grep{'lxc-test'} $container->getRunningContainers == 0, 'Container is absent of getRunningContainers.';
ok !$container->isRunning, 'isRunning returns false.';
ok $container->isStopped, 'Container is considered as stopped.';
my @containerConfig = $container->getConfig('lxc.utsname');
is $containerConfig[0], 'lxc-test', 'Can fetch a configuration value.';

$container->start;
ok !$container->isStopped, 'Container is not considered as stopped.';
ok grep{'lxc-test'} $container->getStoppedContainers == 0, 'Container is not present is getStoppedContainers.';
ok $container->isRunning, 'Container is considered as running.';
ok grep{'lxc-test'} $container->getRunningContainers, 'Container is present in getRunningContainers.';

`echo testing > /tmp/lxc-test.txt`;
$container->put('/tmp/lxc-test.txt', '/etc/random/lxc-test.txt');
ok -f '/var/lib/lxc/lxc-test/rootfs/etc/random/lxc-test.txt', 'A file was correctly put into the container.';
my $cmd = $container->exec('cat /someting/that/doesnt/exist');
ok !$cmd, 'Scalar retured by exec is correct.';
my ($status, $stdout, $stderr) = $container->exec('cat /etc/random/lxc-test.txt');
ok $status, 'Execution return status of exec is correct.';
ok (chomp $stdout) eq 'testing', 'Stdout return of exec is correct.';
ok $stderr eq '', 'Stderr of exec is correct.';

$container->stop;
ok $container->isStopped, 'Container is stopped';

$container->setConfig('newnode', '42');
my @configValues = $container->getConfig('newnode');
is $configValues[0], '42', 'Creation of a new configuration attribute.';
$container->setConfig('lxc.network.ipv4', '42.42.42.42');
@configValues = $container->getConfig('lxc.network.ipv4');
is $configValues[0], '42.42.42.42', 'Update of a configuration attribute.';

$container->destroy;
ok grep{'lxc-test'} $container->getExistingContainers == 0, 'Container is absent of getExistingContainers.';
ok grep{'lxc-test'} `lxc-ls -1` == 0, 'Container doesn\'t exist anymore.';

$container->setLxcPath('/tmp/randomdest/container');
is $container->getLxcPath, '/tmp/randomdest/container', 'New container path was assigned.';

TODO: {
	local $TODO = 'Creation of container somewhere else but the default location is not supported yet.';
	$container->deploy;
	ok -f '/tmp/randomdest/container/config', 'New container config is at the good emplacement.';
	ok -d '/tmp/randomdest/container/rootfs', 'New container rootfs is at the good emplacement.';
	$container->destroy;
}

done_testing;

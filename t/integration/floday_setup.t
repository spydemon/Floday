#!/usr/bin/env perl

use v5.20;
use warnings;
use Cwd;
use Floday::Setup;
use Test::More;
use Test::Exception;
use Log::Any::Adapter('File', 'log.txt');
use Data::Dumper;

my $container = Floday::Setup->new(containerName => 'integration-web-test', runfilePath => '/opt/floday/t/integration/floday.d/runfile.yml');
my $lxc = $container->getLxcInstance;
$lxc->destroy if $lxc->isExisting;
$lxc->setTemplate($container->getParameter('template'));
$lxc->deploy;

my $iface = $container->getParameter('iface');

like($iface, qr/eth0/, 'Container parameter fetched.');
throws_ok { $container->getParameter('invalid name'); }
	qr/Parameter "invalid name" asked has an invalid name/, 'Espaces in parameter name is invalid.';
throws_ok { $container->getParameter('invalid~~{name'); }
	qr/Parameter "invalid~~{name" asked has an invalid name/, 'All non alphanumeric chars should be invalid';
throws_ok { $container->getParameter('yolooo'); }
	qr/undefined "yolooo" parameter asked for integration-web-test container./, 'Error throwed when unexsting parameter is asked.';

like($lxc->getUtsname, qr/integration-web-test/, 'Virt::LXC instance fetched seems good.');

my $parentType = $container->getParentContainer->getParameter('type');
like($parentType, qr/riuk-http/, 'Parent fetch seems to work.');

$container->generateFile(getcwd . '/floday_setup.d/test.tt', {$container->getParameters}, '/tmp/test.txt');
like(`cat /var/lib/lxc/integration-web-test/rootfs/tmp/test.txt`, qr/Hello integration-web-test !/, 'generateFile seems to work.');

$lxc->destroy;
done_testing;

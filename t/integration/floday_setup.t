#!/usr/bin/env perl

use v5.20;
use warnings;
use Cwd;
use Floday::Setup 'ALLOW_UNDEF';
use Test::More;
use Test::Exception;
use Log::Any::Adapter('File', 'log.txt');
use Data::Dumper;

my $application = Floday::Setup->new(instancePath => 'integration-web-test', runfilePath => '/opt/floday/t/integration/floday.d/runfile.yml');
my $lxc = $application->getLxcInstance;
$lxc->destroy if $lxc->isExisting;
$lxc->setTemplate($application->getParameter('template'));
$lxc->deploy;

my $iface = $application->getParameter('iface');

like($iface, qr/eth0/, 'Application parameter fetched.');
throws_ok { $application->getParameter('invalid name'); }
	qr/Parameter "invalid name" asked has an invalid name/, 'Espaces in parameter name is invalid.';
throws_ok { $application->getParameter('invalid~~{name'); }
	qr/Parameter "invalid~~{name" asked has an invalid name/, 'All non alphanumeric chars should be invalid';
throws_ok { $application->getParameter('yolooo'); }
	qr/undefined "yolooo" parameter asked for integration-web-test application./, 'Error throwed when unexsting parameter is asked.';
$application->getParameter('yolooo', ALLOW_UNDEF);
like($lxc->getUtsname, qr/integration-web-test/, 'Virt::LXC instance fetched seems good.');

my $parentType = $application->getParentApplication->getParameter('type');
like($parentType, qr/web/, 'Parent fetch seems to work.');

$application->generateFile(getcwd . '/floday_setup.d/test.tt', {$application->getParameters}, '/tmp/test.txt');
like(`cat /var/lib/lxc/integration-web-test/rootfs/tmp/test.txt`, qr/Hello test !/, 'generateFile seems to work.');

$lxc->destroy;
done_testing;

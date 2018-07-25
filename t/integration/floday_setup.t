#!/usr/bin/env perl

use v5.20;
use warnings;
use experimental 'smartmatch';

BEGIN {
	push @ARGV, qw/--application integration-web/;
}

use Backticks;
use Cwd;
use Floday::Setup ('$APP', 'ALLOW_UNDEF');
use Test::More;
use Test::Exception;
use Log::Any::Adapter('+Floday::Helper::Logging', 'log_level', 'trace');

my $lxc = $APP->get_lxc_instance;
$lxc->destroy if $lxc->is_existing;
$lxc->set_template($APP->get_parameter('template'));
$lxc->deploy;

my $iface = $APP->get_parameter('iface');

like($iface, qr/eth0/, 'Application parameter fetched.');
throws_ok { $APP->get_parameter('invalid name'); }
	qr/Parameter "invalid name" asked has an invalid name/, 'Espaces in parameter name is invalid.';
throws_ok { $APP->get_parameter('invalid~~{name'); }
	qr/Parameter "invalid~~{name" asked has an invalid name/, 'All non alphanumeric chars should be invalid';
throws_ok { $APP->get_parameter('yolooo'); }
	qr/undefined "yolooo" parameter asked for integration-web application./, 'Error throwed when unexsting parameter is asked.';
$APP->get_parameter('yolooo', ALLOW_UNDEF);
like($lxc->get_utsname, qr/integration-web/, 'Linux::LXC instance fetched seems good.');

my $parentType = $APP->get_manager->get_parameter('type');
like($parentType, qr/riuk/, 'Parent fetch seems to work.');

$APP->generate_file('riuk/children/web/children/php/setups/test/test.tt', {$APP->get_parameters}, '/tmp/test.txt');
like(`cat /var/lib/lxc/integration-web/rootfs/tmp/test.txt`, qr/Hello web !/, 'generate_file seems to work.');
$APP->generate_file('riuk/children/web/children/php/setups/test/test.tt', {$APP->get_parameters}, '/tmp/perm_test.txt', '100');
like(`ls -l /var/lib/lxc/integration-web/rootfs/tmp/perm_test.txt`, qr/^---x------/, 'Permission management from generate_file subroutine on application file.');
throws_ok { $APP->generate_file('riuk/children/web/children/php/setups/test/test.tt', {$APP->get_parameters}, '/tmp/perm_test.txt', '108') }
	qr/^Invalid permission set for the generated file: 108/, 'Check permission validity on generate_file subroutine.';

like ($APP->get_root_folder(), qr#/var/lib/lxc/integration-web/rootfs#, 'get_root_path seems to work');

for ($APP->get_sub_applications()) {
	ok($_->get_application_path() ~~ ['integration-web-test', 'integration-web-secondtest'], 'Test get_applications seems to work');
}

ok ($APP->is_host() == 0, 'Test is_host on application that is not a host.');
my $host = Floday::Setup->new('application_path' => 'integration');
ok ($host->is_host() == 1, 'Test is_host on the host.');
throws_ok { $host->get_lxc_instance(); }
	qr/We can not invocate LXC container from host/, 'Test that get_lxc_instance dies when done from a application that represents the host.';

$lxc->destroy;

my $setup = Backticks->new('/etc/floday/containers/riuk/children/web/setups/lighttpd.pl --application integration-nonexistent');
eval {$setup->run()};
like ($setup->stderr(), qr/Floday "integration-nonexistent" application was not found in the runfile./, 'Test that the application existance is checked.');
cmp_ok($setup->exitcode(), '!=', 0);


`rm -rf /tmp/a`;
`/etc/floday/containers/riuk/setups/folder_creation_on_host.pl --application integration`;
ok (-f '/tmp/a/creation/test/on/host.txt', 'Test generate_file subroutine on the host.');
like (
  `ls -l /tmp/a/creation/test/on/host.txt`,
  qr/^---x--x--t/,
  'Test rights management from the generate_file subroutine on host.'
);

cmp_ok (
  $APP->get_container()->get_container_path(),
  'eq',
  'riuk-web',
  'Test access to Floday::Helper::Container through $APP.'
);

done_testing;

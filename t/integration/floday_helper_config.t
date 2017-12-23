use v5.20;
use strict;
use warnings;

use Test::Deep;
use Test::Exception;
use Test::More;

use Floday::Helper::Config;

my $config = Floday::Helper::Config->new();
cmp_ok (
  $config->get_floday_config('containers', 'path'),
  'eq',
  '/etc/floday/containers',
  'Check Floday configuration fetching.'
);
cmp_ok (
  $config->get_floday_config('lxc', 'cache_folder'),
  'eq',
  '/tmp/floday/lxc-flodayalpine',
  'Check configuration rewriting.'
);
throws_ok {$config->get_floday_config('containers', 'nonexisting')}
  qr/Undefined 'nonexisting' key in Floday configuration 'containers' section/,
  'Check Floday configuration fetch with non existing key';

done_testing;

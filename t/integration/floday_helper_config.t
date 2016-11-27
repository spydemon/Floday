use v5.20;
use strict;
use warnings;

use Test::Deep;
use Test::Exception;
use Test::More;

use Floday::Helper::Config;

`mv /etc/floday/floday.cfg /etc/floday/floday.cfg.back`;
throws_ok {Floday::Helper::Config->new()}
  qr/Unable to load Floday configuration/,
  'Check exception when configuration file is missing.';
`mv /etc/floday/floday.cfg.back /etc/floday/floday.cfg`;

my $config = Floday::Helper::Config->new();
cmp_ok ($config->getFlodayConfig('containers', 'path'), 'eq', '/etc/floday/containers', 'Check Floday configuration fetching.');
throws_ok {$config->getFlodayConfig('containers', 'nonexisting')}
  qr/Undefined 'nonexisting' key in Floday configuration 'containers' section/,
  'Check Floday configuration fetch with non existing key';

done_testing;

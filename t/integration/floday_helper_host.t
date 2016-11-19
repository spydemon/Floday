#!/usr/bin/env perl

use v5.20;
use warnings;
use strict;

use Data::Dumper;

use Log::Any::Adapter('File', 'log.txt');
use Test::More;
use Test::Exception;

use Floday::Helper::Host;

my $attributesWithGoodName = {
  'parameters' => {
    'name' => 'agoodname',
    'type' => 'riuk',
    'external_ipv4' => '10.11.22.33'
  }
};

my $attributesWithWrongType = {
  'parameters' => {
    'name' => 'agoodname',
    'type' => 'riuk-xx'
  }
};

my $attributesWithWrongName = {
  'parameters' => {
    'name' => 'yol0~~',
    'type' => 'riuk'
  }
};

my $attributesWithoutName = {
  'parameters' => {
    'type' => 'riuk-php',
    'type' => 'riuk'
  }
};

my $attributesWithUnexistingParam = {
  'parameters' => {
    'name' => 'agoodname',
    'type' => 'riuk',
    'external_ipv4' => '10.11.22.33',
    'unknown_param' => 'a value'
  }
};

ok (Floday::Helper::Host->new('attributesFromRunfile' => $attributesWithGoodName), 'A instance is correctly created.');
throws_ok {Floday::Helper::Host->new('attributesFromRunfile' => $attributesWithWrongName)}
  qr/Invalid name 'yol0~~' for host initialization/,
  'Check exception at invalid hostname.';
throws_ok {Floday::Helper::Host->new('attributesFromRunfile' => $attributesWithoutName)}
  qr/Invalid name '' for host initialization/,
  'Check exception at invalid hostname.';
throws_ok {Floday::Helper::Host->new('attributesFromRunfile' => $attributesWithWrongType)}
  qr/Invalid type 'riuk-xx' for host initialization/,
  'Check exception at invalid container type.';

`mv /etc/floday/floday.cfg /etc/floday/floday.cfg.back`;
throws_ok {my $host = Floday::Helper::Host->new('attributesFromRunfile' => $attributesWithGoodName)}
  qr/Unable to load Floday configuration/,
  'Check exception when configuration file is missing.';
`mv /etc/floday/floday.cfg.back /etc/floday/floday.cfg`;

my $host = Floday::Helper::Host->new('attributesFromRunfile' => $attributesWithGoodName);
ok ($host->_getFlodayConfig('path') eq '/etc/floday/containers', 'Check Floday configuration fetching.');
throws_ok {$host->_getFlodayConfig('nonexisting')}
  qr/Undefined 'nonexisting' key in Floday configuration container section/,
  'Check Floday configuration fetch with non existing key';

#Test _mergeConfig function:
cmp_ok ($host->toHash()->{'parameters'}{'external_ipv4'}{'value'}, 'eq', '10.11.22.33', 'Check runfile parameters integration in runlist.');
cmp_ok ($host->toHash()->{'parameters'}{'useless_param'}{'value'}, 'eq', 'we dont care', 'Check default runlist parameters values.');
throws_ok {Floday::Helper::Host->new('attributesFromRunfile' => $attributesWithUnexistingParam)->toHash()}
  qr/Parameter 'unknown_param' present in runfile but that doesn't exist in container definition/,
  'Check exception on unexisting parameter in container definition.';

done_testing;

#!/usr/bin/env perl

use v5.20;

use Log::Any::Adapter('File', 'log.txt');
use Test::More;
use Test::Exception;

use Floday::Helper::Host;

my $attributesWithGoodName = {
  'parameters' => {
    'name' => 'agoodname'
  }
};

my $attributesWithWrongName = {
  'parameters' => {
    'name' => 'yol0~~'
  }
};

my $attributesWithoutName = {
  'parameters' => {
    'type' => 'riuk-php'
  }
};

ok (Floday::Helper::Host->new('attributesFromRunfile' => $attributesWithGoodName), 'A instance is correctly created.');
throws_ok {Floday::Helper::Host->new('attributesFromRunfile' => $attributesWithWrongName)}
  qr/Invalid name 'yol0~~' for host initialization/,
  'Check exception at invalid hostname.';
throws_ok {Floday::Helper::Host->new('attributesFromRunfile' => $attributesWithoutName)}
  qr/Invalid name '' for host initialization/,
  'Check exception at invalid hostname.';

done_testing;

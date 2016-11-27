use v5.20;
use strict;
use warnings;

use Test::Deep;
use Test::More;

use Floday::Helper::Container;

use Data::Dumper ('Dumper');
$Data::Dumper::Indent = 1;

my $expectedResult1 = {
  'setups' => {
    'network' => {
      'priority' => '10',
      'exec' => '/opt/floday/containers/riuk/children/core/setups/network.pl'
    },
    'data' => {
      'priority' => '50',
      'exec' => '/opt/floday/containers/riuk/children/core/setups/data.pl'
    }
  },
  'inherit' => [
    'riuk-core'
  ],
  'parameters' => {
    'arbitrary_param' => {
      'mandatory' => 'false'
    },
    'second_arbitrary_param' => {
      'mandatory' => 'false'
    },
    'shouby' => {
      'mandatory' => 'true'
    }
  }
};

cmp_ok (Floday::Helper::Container->new()->getContainerDefinitionFilePath('riuk-web-php'),
  'eq',
  '/etc/floday/containers/riuk/children/web/children/php/config.yml',
  'Definition file path corectly fetched.'
);

cmp_deeply (Floday::Helper::Container->new()->getContainerDefinition('riuk-sftp'),
  $expectedResult1,
  'Definition of container correctly fetched.'
);

done_testing;

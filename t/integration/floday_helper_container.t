use v5.20;
use strict;
use warnings;

use Test::Deep;
use Test::More;

use Floday::Helper::Container;

my $expectedResult1 = {
  'setups' => {
    'network' => {
      'priority' => '10',
      'exec' => 'riuk/children/core/setups/network.pl'
    },
    'data' => {
      'priority' => '30',
      'exec' => 'riuk/children/core/setups/data.pl'
    }
  },
  'hooks' => {
    'lxc_deploy_before' => {
      'open_firewall' => {
        'exec' => 'riuk/children/core/hooks/lxc_deploy_before/open_firewall.pl',
        'priority' => 10
      }
    },
    'lxc_deploy_after' => {
      'close_firewall' => {
        'exec' => 'riuk/children/core/hooks/lxc_deploy_after/close_firewall.pl',
        'priority' => 10
      }
    }
  },
  'inherit' => [
    'riuk-core'
  ],
  'parameters' => {
    'data_out' => {
      'mandatory' => 'false'
    },
    'second_arbitrary_param' => {
      'mandatory' => 'false'
    },
    'data_in' => {
      'mandatory' => 'false'
    },
    'iface' => {
      'mandatory' => 'true',
      'value' => 'eth0'
    },
    'ipv4' => {
      'mandatory' => 'true'
    },
    'template' => {
      'mandatory' => 'true',
      'value' => 'flodayalpine -- version 3.4'
    },
    'netmask' => {
      'value' => '255.255.255.0',
      'mandatory' => 'true'
    },
    'arbitrary_param' => {
      'mandatory' => 'false'
    },
    'bridge' => {
      'mantatory' => 'true',
      'value' => 'lxcbr0'
    },
    'gateway' => {
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

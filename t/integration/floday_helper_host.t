#!/usr/bin/env perl

use v5.20;
use warnings;
use strict;

use Data::Dumper;
$Data::Dumper::Indent = 1;

use Log::Any::Adapter('File', 'log.txt');
use Test::Deep;
use Test::Exception;
use Test::More;

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

my $attributesWithChild = {
  'parameters' => {
    'name' => 'agoodname',
    'type' => 'riuk',
    'external_ipv4' => '10.11.22.35'
  },
  'applications' => {
    'website1' => {
      'parameters' => {
        'type' => 'web',
      }
    },
    'website2' => {
      'parameters' => {
        'type' => 'sftp',
        'arbitrary_param' => '1'
      }
    }
  }
};

my $complexHostToHashResult = {
  'applications' => {
    'website2' => {
      'parameters' => {
        'data_out' => {
          'mandatory' => 'false'
        },
        'type' => {
          'value' => 'sftp'
        },
        'gateway' => {
          'mandatory' => 'true'
        },
        'ipv4' => {
          'mandatory' => 'true'
        },
        'arbitrary_param' => {
          'mandatory' => 'false',
          'value' => '1'
        },
        'second_arbitrary_param' => {
          'mandatory' => 'false'
        },
        'iface' => {
          'mandatory' => 'true',
          'value' => 'eth0'
        },
        'bridge' => {
          'mantatory' => 'true',
          'value' => 'lxcbr0'
        },
        'template' => {
          'mandatory' => 'true',
          'value' => 'flodayalpine -- version 3.4'
        },
        'netmask' => {
          'value' => '255.255.255.0',
          'mandatory' => 'true'
        },
        'name' => {
          'value' => 'website2'
        },
          'data_in' => {
          'mandatory' => 'false'
        }
      },
      'setups' => {
        'data' => {
          'priority' => '30',
          'exec' => '/opt/floday/containers/riuk/children/core/setups/data.pl'
        },
        'network' => {
          'exec' => '/opt/floday/containers/riuk/children/core/setups/network.pl',
          'priority' => '10'
        }
      },
      'inherit' => [
        'riuk-core'
      ]
    },
    'website1' => {
      'setups' => {
        'network' => {
          'exec' => '/opt/floday/containers/riuk/children/core/setups/network.pl',
          'priority' => '10'
        },
        'lighttpd' => {
          'priority' => '20',
          'exec' => '/opt/floday/containers/riuk/children/web/setups/lighttpd.pl'
        },
        'data' => {
          'priority' => '30',
          'exec' => '/opt/floday/containers/riuk/children/core/setups/data.pl'
        }
      },
      'inherit' => [
        'riuk-core'
      ],
      'parameters' => {
        'iface' => {
          'value' => 'eth0',
          'mandatory' => 'true'
        },
        'bridge' => {
          'mantatory' => 'true',
          'value' => 'lxcbr0'
        },
        'template' => {
          'mandatory' => 'true',
          'value' => 'flodayalpine -- version 3.4'
        },
        'name' => {
          'value' => 'website1'
        },
        'netmask' => {
          'value' => '255.255.255.0',
          'mandatory' => 'true'
        },
        'data_in' => {
          'mandatory' => 'false'
        },
        'data_out' => {
          'mandatory' => 'false'
        },
        'gateway' => {
          'mandatory' => 'true'
        },
        'type' => {
          'value' => 'web'
        },
        'ipv4' => {
          'mandatory' => 'true'
        }
      }
    }
  },
  'inherit' => [],
  'parameters' => {
    'type' => {
      'value' => 'riuk'
    },
    'useless_param' => {
      'value' => 'we dont care',
      'required' => 'false'
    },
    'name' => {
      'value' => 'agoodname'
    },
    'external_ipv4' => {
      'required' => 'true',
      'value' => '10.11.22.35'
    }
  }
};

ok (Floday::Helper::Host->new('runfile' => $attributesWithGoodName), 'A instance is correctly created.');
throws_ok {Floday::Helper::Host->new('runfile' => $attributesWithWrongName)}
  qr/Invalid name 'yol0~~' for host initialization/,
  'Check exception at invalid hostname.';
throws_ok {Floday::Helper::Host->new('runfile' => $attributesWithoutName)}
  qr/Invalid name '' for host initialization/,
  'Check exception at invalid hostname.';
throws_ok {Floday::Helper::Host->new('runfile' => $attributesWithWrongType)}
  qr/Invalid type 'riuk-xx' for host initialization/,
  'Check exception at invalid container type.';


#Test _mergeDefinition function:
my $host= Floday::Helper::Host->new('runfile' => $attributesWithGoodName);
cmp_ok ($host->toHash()->{'parameters'}{'external_ipv4'}{'value'}, 'eq', '10.11.22.33', 'Check runfile parameters integration in runlist.');
cmp_ok ($host->toHash()->{'parameters'}{'useless_param'}{'value'}, 'eq', 'we dont care', 'Check default runlist parameters values.');
throws_ok {Floday::Helper::Host->new('runfile' => $attributesWithUnexistingParam)->toHash()}
  qr/Parameter 'unknown_param' present in runfile but that doesn't exist in container definition/,
  'Check exception on unexisting parameter in container definition.';

#Test _getContainerPath:
my $complexHost = Floday::Helper::Host->new('runfile' => $attributesWithChild);
$complexHost->{instancePathToManage} = 'agoodname-website1';
cmp_ok $complexHost->_getContainerPath(), 'eq', 'riuk-web', 'Check containerTypePath resolution.';
$complexHost->{instancePathToManage} = 'agoodname-website2';
cmp_ok $complexHost->_getContainerPath(), 'eq', 'riuk-sftp', 'Check containerTypePath resolution.';
$complexHost->{instancePathToManage} = 'agoodname';

#Test toHash
cmp_deeply $complexHost->toHash(), $complexHostToHashResult, 'Check toHash result.';

done_testing;

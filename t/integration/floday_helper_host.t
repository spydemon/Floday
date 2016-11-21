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
  'parameters' => {
    'external_ipv4' => {
      'value' => '10.11.22.35',
      'required' => 'true'
    },
    'useless_param' => {
      'value' => 'we dont care',
      'required' => 'false'
    },
    'name' => {
      'value' => 'agoodname'
    },
    'type' => {
      'value' => 'riuk'
    }
  },
  'applications' => {
    'website2' => {
      'parameters' => {
        'type' => {
          'value' => 'sftp'
        },
        'arbitrary_param' => {
          'mandatory' => 'false',
          'value' => '1'
        },
        'shouby' => {
          'mandatory' => 'true'
        },
        'name' => {
          'value' => 'website2'
        },
        'second_arbitrary_param' => {
          'mandatory' => 'false'
        }
      },
      'setups' => {
        'network' => {
          'priority' => '10',
          'exec' => '/opt/floday/containers/riuk/children/core/setups/network.pl'
        },
        'data' => {
          'exec' => '/opt/floday/containers/riuk/children/core/setups/data.pl',
          'priority' => '50'
        }
      },
      'inherit' => [
        'riuk-core'
      ]
    },
    'website1' => {
      'parameters' => {
        'type' => {
          'value' => 'web'
        },
        'name' => {
          'value' => 'website1'
        }
      },
      'inherit' => []
    }
  },
  'inherit' => []
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

`mv /etc/floday/floday.cfg /etc/floday/floday.cfg.back`;
throws_ok {my $host = Floday::Helper::Host->new('runfile' => $attributesWithGoodName)}
  qr/Unable to load Floday configuration/,
  'Check exception when configuration file is missing.';
`mv /etc/floday/floday.cfg.back /etc/floday/floday.cfg`;

my $host = Floday::Helper::Host->new('runfile' => $attributesWithGoodName);
cmp_ok ($host->_getFlodayConfig('path'), 'eq', '/etc/floday/containers', 'Check Floday configuration fetching.');
throws_ok {$host->_getFlodayConfig('nonexisting')}
  qr/Undefined 'nonexisting' key in Floday configuration container section/,
  'Check Floday configuration fetch with non existing key';

#Test _mergeDefinition function:
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

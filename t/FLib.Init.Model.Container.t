#/bin/perl

use strict;
use warnings;

use v5.20;

use Test::More;
use Test::Exception;
use Data::Dumper;

use FLib::Init::Model::Container;

$ENV{FLODAY_CONTAINERS} = '/opt/floday/t/FLib.Init.Model.Container.d/';

#{{{ Test variables
my $TEST_1 = {
  'name' => 'testContainer-invalid',
  'type' => 'valid',
};

my $TEST_2 = {
  'name' => 'testContainer',
  'attribute' => 'value',
  'childContainer' => {
    'name' => 'child',
    'type' => 'valid'
  },
  'childApplication' => {
    'name' => 'childApplication',
    'type' => 'php'
  }
};

my $TEST_3 = {
  'name' => 'testContainer',
  'type' => 'valid',
  'attributes' => {
    'port' => '100'
  }
};

my $TEST_4 = {
  'name' => 'testContainer',
  'type' => 'valid',
  'attribute' => {
    'port' => '100',
    'to' => '127.0.0.1:60',
    'path' => '/tank/application'
  },
  'childContainer' => {
    'name' => 'child',
    'type' => 'valid',
    'action' => 'container'
  },
  'childApplication' => {
    'name' => 'childApplication',
    'type' => 'php',
    #'action' => 'application'
  }
};

my $RESULT_4 = bless( {
  'applications' => {},
  'definition' => bless( {
    'containerType' => 'valid',
    'uninstall' => {
      'script' => {
        'priority' => '10',
        'path' => 'uninstall/destroy.pl'
      }
    },
    'setup' => {
      'script' => {
        'path' => 'setup/zabbix.pl',
        'priority' => '20'
      }
    },
    'parameters' => {
      'port' => {
        'mandatory' => 'true',
        'value' => '5000'
      },
      'data' => {
        'mandatory' => 'true'
      }
    },
    'applications' => {
      'bridge' => {
        'path' => 'applications/bridge.pl',
        'parameters' => {
          'to' => {
            'mandatory' => 'true'
          },
          'port' => {
            'mandatory' => 'true',
            'default' => '80'
          },
          'name' => {
            'mandatory' => 'true'
          }
        },
        'containerType' => 'valid'
      }
    },
    'shutdown' => {
      'script' => {
        'path' => 'shutdown/something.pl',
        'priority' => '10'
      }
    },
    'startup' => {
      'script' => {
        'hello' => 'coucou',
        'priority' => '50',
        'path' => 'startup/backup.pl'
      }
    }
  }, 'FLib::Init::Helper::DefinitionParser' ),
  'path' => {
    'level1-level2' => undef
  },
  'parameters' => {
    'name' => 'testContainer',
    'type' => 'valid'
  },
  'containers' => [
    'level1-level2-childContainer'
  ]
}, 'FLib::Init::Model::Container' );
#}}}

throws_ok {FLib::Init::Model::Container->new($TEST_1, 'level1-level2')}
  qr/Invalid character in name value at /;

throws_ok { FLib::Init::Model::Container->new($TEST_2, 'level1-level2')}
  qr/Mandatory type parameter is missing at /;

#throws_ok { FLib::Init::Model::Container->new($TEST_3, 'level1-level2')}
#  qr/Mandatory "field" is missing at /;

my $container = FLib::Init::Model::Container->new($TEST_4, 'level1-level2');
ok eq_hash $container, $RESULT_4;

done_testing;

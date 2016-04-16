#/bin/perl

use strict;
use warnings;

use v5.20;

use Test::More;
use Test::Exception;
use Data::Dumper;
$Data::Dumper::Indent = 1;

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
  'port' => '100'
};

my $TEST_4 = {
  'name' => 'testContainer',
  'type' => 'valid',
  'port' => '100',
  'to' => '127.0.0.1:60',
  'data' => 'yolo',
  'path' => '/tank/application',
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
  'attributes' => {
    'name' => 'testContainer',
    'data' => 'yolo',
    'port' => '100',
    'to' => '127.0.0.1:60',
    'type' => 'valid',
    'path' => '/tank/application'
  },
  'applications' => {},
  'definition' => bless( {
    'template' => '',
    'shutdown' => {
      'script' => {
        'path' => 'shutdown/something.pl',
        'priority' => '10'
      }
    },
    'startup' => {
      'script' => {
        'priority' => '50',
        'path' => 'startup/backup.pl',
        'hello' => 'coucou'
      }
    },
    'containerType' => 'valid',
    'parameters' => {
      'data' => {
        'mandatory' => 'true'
      },
      'port' => {
        'mandatory' => 'true',
        'default' => '5000'
      }
    },
    'setup' => {
      'script' => {
        'path' => 'setup/zabbix.pl',
        'priority' => '20'
      }
    },
    'applications' => {
      'bridge' => {
        'containerType' => 'valid',
        'path' => 'applications/bridge.pl',
        'parameters' => {
          'to' => {
            'mandatory' => 'true'
          },
          'name' => {
            'mandatory' => 'true'
          },
          'port' => {
            'mandatory' => 'true',
            'default' => '80'
          }
        }
      }
    },
    'uninstall' => {
      'script' => {
        'priority' => '10',
        'path' => 'uninstall/destroy.pl'
      }
    }
  }, 'FLib::Init::Helper::DefinitionParser' ),
  'parameters' => '2/8',
  'containers' => [
    'level1-level2-childContainer'
  ],
  'path' => {
    'level1-level2' => undef
  }
}, 'FLib::Init::Model::Container' );
#}}}

throws_ok {FLib::Init::Model::Container->new($TEST_1, 'level1-level2')}
  qr/Invalid character in name attribute at /;

throws_ok { FLib::Init::Model::Container->new($TEST_2, 'level1-level2')}
  qr/Mandatory type parameter is missing at /;

throws_ok { FLib::Init::Model::Container->new($TEST_3, 'level1-level2')}
  qr/Mandatory "data" parameter is missing but required /;

my $container = FLib::Init::Model::Container->new($TEST_4, 'level1-level2');
ok eq_hash $container, $RESULT_4;

done_testing;

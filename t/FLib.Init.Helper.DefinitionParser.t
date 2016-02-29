#!/usr/bin perl

use strict;
use warnings;

use v5.20;

use Test::More;
use Test::Exception;

use FLib::Init::Helper::DefinitionParser;
use Data::Dumper;

#{{{Test variables
my $TEST_1 = bless( {
  'uninstall' => {
    'script' => {
      'path' => 'uninstall/a-script.pl',
      'priority' => '400'
    }
  },
  'setup' => {
    'script' => {
      'path' => 'setup/a-script.pl',
      'priority' => '100'
    }
  },
  'containerType' => 'correct',
  'startup' => {
    'script' => {
      'path' => 'startup/a-script.pl',
      'priority' => '200'
    }
  },
  'applications' => {
    'app_name' => {
      'containerType' => 'correct',
      'path' => 'somewhere/else.hs',
      'parameters' => {
        'param1' => {
          'mandatory' => 'true'
        },
        'param3' => {
          'default' => '42'
        },
        'param2' => {
          'default' => '666',
          'mandatory' => 'false'
        }
      }
    }
  },
  'parameters' => {
    'port' => {
      'value' => '80',
      'mandatory' => 'true'
    },
      'name' => {
      'mandatory' => 'true'
    }
  },
  'shutdown' => {
    'script' => {
      'priority' => '300',
      'path' => 'shutdown/a-script.pl'
    }
  }
}, 'FLib::Init::Helper::DefinitionParser' );
#}}}

#Test _getContainersPath
$ENV{FLODAY_CONTAINERS} = undef;
throws_ok {FLib::Init::Helper::DefinitionParser->new('root')}
  qr/^The environment variable FLODAY_CONTAINERS is not set at/;
$ENV{FLODAY_CONTAINERS} = '/yolo';
throws_ok {FLib::Init::Helper::DefinitionParser->new('root')}
  qr/^FLODAY_CONTAINERS have to end with a slash at/;
$ENV{FLODAY_CONTAINERS} = '/yolo/';
throws_ok {FLib::Init::Helper::DefinitionParser->new('root')}
  qr/is not an existing directory/;

$ENV{FLODAY_CONTAINERS} = $ENV{FLODAY_T} . 'FLib.Init.Helper.DefinitionParser.d/';

#Test _initializeXml
throws_ok {FLib::Init::Helper::DefinitionParser->new('nonexistingContainer')}
  qr/^Could not create file parser context for file/;

#Test _fetchAttributes
#Test _fetchApplications
throws_ok {FLib::Init::Helper::DefinitionParser->new('withHyphenInParameterName')}
  qr/^Invalid character in parameter name: /;
throws_ok {FLib::Init::Helper::DefinitionParser->new('withHyphenInParameterValue')}
  qr/^Invalid character in parameter value: /;
my $obj = FLib::Init::Helper::DefinitionParser->new('correct');
ok eq_hash $obj, $TEST_1;

#Test _mergeAttributesWithDependencies
#TODO with issue #16

done_testing;

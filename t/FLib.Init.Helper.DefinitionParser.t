#!/usr/bin perl

use strict;
use warnings;

use v5.20;

use Test::More;
use Test::Exception;

use FLib::Init::Helper::DefinitionParser;
use Data::Dumper;
$Data::Dumper::Indent = 1;

#{{{Test variables
my $TEST_1 = bless( {
  'shutdown' => {
    'script' => {
      'priority' => '300',
      'path' => 'shutdown/a-script.pl'
    }
  },
  'startup' => {
    'script' => {
      'path' => 'startup/a-script.pl',
      'priority' => '200'
    }
  },
  'parameters' => {
    'log' => {
      'default' => '1'
    },
    'name' => {
      'mandatory' => 'true'
    },
    'port' => {
      'mandatory' => 'true',
      'default' => '80'
    }
  },
  'containerType' => 'correct',
  'setup' => {
    'script' => {
      'priority' => '100',
      'path' => 'setup/a-script.pl'
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
          'mandatory' => 'false',
          'default' => '666'
        }
      }
    }
  },
  'uninstall' => {
    'script' => {
      'path' => 'uninstall/a-script.pl',
      'priority' => '400'
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

done_testing;

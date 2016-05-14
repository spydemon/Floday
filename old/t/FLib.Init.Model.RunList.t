#!/bin/perl

use strict;
use warnings;

use Data::Dumper;
$Data::Dumper::Indent = 1;

#{{{Test variables
my $TEST_1 = bless( {
  'containers' => {
    'valid-database-blog' => bless( {
      'definition' => bless( {
        'applications' => {},
        'startup' => {},
        'uninstall' => {},
        'shutdown' => {},
        'parameters' => {},
        'setup' => {},
        'template' => '',
        'containerType' => 'wordpress'
      }, 'FLib::Init::Helper::DefinitionParser' ),
      'attributes' => {
        'type' => 'wordpress',
        'name' => 'blog',
        'action' => 'container',
        'vhost' => 'myblog.mysite.fr'
      },
      'applications' => {},
      'path' => {
        'valid-database-blog' => undef
      },
      'parameters' => 0,
      'containers' => []
    }, 'FLib::Init::Model::Container' ),
    'valid-database' => bless( {
      'definition' => bless( {
        'template' => '',
        'applications' => {
          'app' => {
            'containerType' => 'postgressql',
            'path' => 'applications/app.sh',
            'parameters' => {}
          }
        },
        'startup' => {},
        'uninstall' => {},
        'shutdown' => {},
        'parameters' => {},
        'setup' => {},
        'containerType' => 'postgressql'
      }, 'FLib::Init::Helper::DefinitionParser' ),
      'attributes' => {
        'action' => 'container',
        'name' => 'database',
        'ipv4' => '10.0.3.13',
        'type' => 'postgressql'
      },
      'applications' => {
        'goodapp' => bless( {
          'name' => 'goodapp',
          'parameters' => {},
          'path' => '/opt/floday/t/FLib.Init.Model.RunList.d/containers/postgressql/applications/app.sh',
          'containerType' => 'postgressql',
          'type' => 'app'
        }, 'FLib::Init::Model::Application' )
      },
      'path' => {
        'valid-database' => undef
      },
      'parameters' => 0,
      'containers' => [
        'valid-database-blog'
      ]
    }, 'FLib::Init::Model::Container' ),
    'valid' => bless( {
      'definition' => bless( {
        'template' => '',
        'setup' => {},
        'containerType' => 'root',
        'shutdown' => {},
        'applications' => {},
        'uninstall' => {},
        'startup' => {},
        'parameters' => {}
      }, 'FLib::Init::Helper::DefinitionParser' ),
      'attributes' => {
        'type' => 'root',
        'name' => 'valid'
      },
      'applications' => {},
      'path' => {
        'valid' => undef
      },
      'parameters' => 0,
      'containers' => [
        'valid-database'
      ]
    }, 'FLib::Init::Model::Container' )
  },
  'currentContainerPath' => 'valid'
}, 'FLib::Init::Model::RunList' );
#}}}

use v5.20;

use Test::More;
use Test::Exception;

use FLib::Init::Model::RunList;

$ENV{FLODAY_CONTAINERS} = '/opt/floday/t/FLib.Init.Model.RunList.d/containers/';
`chmod u+x $ENV{FLODAY_CONTAINERS}postgressql/applications/app.sh`;
my $runlist = FLib::Init::Model::RunList->new('/opt/floday/t/FLib.Init.Model.RunList.d/correct.xml', 'valid');
ok eq_hash $runlist, $TEST_1;

done_testing;

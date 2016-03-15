#!/bin/perl

use strict;
use warnings;

#{{{Test variables
my $TEST_1 = bless( {
  'containers' => {
    'valid-database-blog' => bless( {
      'path' => {
        'valid-database-blog' => undef
      },
      'containers' => [],
      'parameters' => {
        'vhost' => 'myblog.mysite.fr',
        'name' => 'blog',
        'type' => 'wordpress',
        'action' => 'container'
      },
      'applications' => {},
      'definition' => bless( {
        'setup' => {},
        'containerType' => 'wordpress',
        'uninstall' => {},
        'parameters' => {},
        'shutdown' => {},
        'applications' => {},
        'startup' => {}
      }, 'FLib::Init::Helper::DefinitionParser' )
    }, 'FLib::Init::Model::Container' ),
    'valid-database' => bless( {
      'applications' => {
        'goodapp' => bless( {
          'path' => '/opt/floday/t/FLib.Init.Model.RunList.d/containers/postgressql/applications/app.sh',
          'containerType' => 'postgressql',
          'parameters' => {},
          'type' => 'app',
          'name' => 'goodapp'
        }, 'FLib::Init::Model::Application' )
      },
      'definition' => bless( {
        'uninstall' => {},
        'parameters' => {},
        'containerType' => 'postgressql',
        'setup' => {},
        'startup' => {},
        'shutdown' => {},
        'applications' => {
          'app' => {
            'parameters' => {},
            'containerType' => 'postgressql',
            'path' => 'applications/app.sh'
          }
        }
      }, 'FLib::Init::Helper::DefinitionParser' ),
      'path' => {
        'valid-database' => undef
      },
      'containers' => [
        'valid-database-blog'
      ],
      'parameters' => {
        'type' => 'postgressql',
        'name' => 'database',
        'ipv4' => '10.0.3.13',
        'action' => 'container'
      }
    }, 'FLib::Init::Model::Container' ),
    'valid' => bless( {
      'containers' => [
        'valid-database'
      ],
      'parameters' => {
        'type' => 'root',
        'name' => 'valid'
      },
      'path' => {
        'valid' => undef
      },
      'definition' => bless( {
        'setup' => {},
        'containerType' => 'root',
        'parameters' => {},
        'uninstall' => {},
        'applications' => {},
        'shutdown' => {},
        'startup' => {}
      }, 'FLib::Init::Helper::DefinitionParser' ),
      'applications' => {}
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

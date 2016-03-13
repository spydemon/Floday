#!/bin/perl

use strict;
use warnings;

#{{{Test variables
my $TEST_1 = bless( {
    'containers' => {
        'valid-database' => bless( {
          'applications' => {
              'goodapp' => bless( {
                'name' => 'goodapp',
                'path' => '/opt/floday/t/FLib.Init.Model.RunList.d/containers/postgressql/applications/app.sh',
                'type' => 'app',
                'containerType' => 'postgressql',
                'parameters' => {}
              }, 'FLib::Init::Model::Application' )
            },
          'path' => {
              'valid-database' => undef
            },
          'containers' => [
              'valid-database-blog'
          ],
          'parameters' => {
            'action' => 'container',
            'ipv4' => '10.0.3.13',
            'name' => 'database',
            'type' => 'postgressql'
          },
          'definition' => bless( {
            'parameters' => {},
            'startup' => {},
            'setup' => {},
            'containerType' => 'postgressql',
            'applications' => {
              'app' => {
                'parameters' => {},
                'containerType' => 'postgressql',
                'path' => 'applications/app.sh'
              }
            },
            'shutdown' => {},
            'uninstall' => {}
            }, 'FLib::Init::Helper::DefinitionParser' )
        }, 'FLib::Init::Model::Container' ),
        'valid-database-blog' => bless( {
          'path' => {
            'valid-database-blog' => undef
          },
          'applications' => {},
          'definition' => bless( {
            'setup' => {},
            'containerType' => 'wordpress',
            'parameters' => {},
            'startup' => {},
            'uninstall' => {},
            'shutdown' => {},
            'applications' => {}
          }, 'FLib::Init::Helper::DefinitionParser' ),
          'containers' => [],
          'parameters' => {
            'type' => 'wordpress',
            'vhost' => 'myblog.mysite.fr',
            'name' => 'blog',
            'action' => 'container'
          }
        }, 'FLib::Init::Model::Container' ),
        'valid' => bless( {
          'definition' => bless( {
           'startup' => {},
           'parameters' => {},
           'setup' => {},
           'containerType' => 'root',
           'applications' => {},
           'uninstall' => {},
           'shutdown' => {}
          }, 'FLib::Init::Helper::DefinitionParser' ),
          'parameters' => {
            'type' => 'root',
            'name' => 'valid'
          },
          'containers' => [
            'valid-database'
          ],
          'path' => {
            'valid' => undef
          },
          'applications' => {}
        }, 'FLib::Init::Model::Container' )
      },
    'currentContainerPath' => 'valid'
}, 'FLib::Init::Model::RunList' );

#}}}
use v5.20;

use Test::More;
use Test::Exception;
use Data::Dumper;

use FLib::Init::Model::RunList;

$ENV{FLODAY_CONTAINERS} = '/opt/floday/t/FLib.Init.Model.RunList.d/containers/';
`chmod u+x $ENV{FLODAY_CONTAINERS}postgressql/applications/app.sh`;
my $runlist = FLib::Init::Model::RunList->new('/opt/floday/t/FLib.Init.Model.RunList.d/correct.xml', 'valid');

ok eq_hash $runlist, $TEST_1;


done_testing;

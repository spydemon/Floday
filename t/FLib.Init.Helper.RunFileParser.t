#!/bin/perl

use strict;
use warnings;

use v5.20;

use Test::More;
use Test::Exception;
use Data::Dumper;

use FLib::Init::Helper::RunFileParser;

#{{{Test variables
my $TEST_1 = bless( {
  'runFile' => {
    'valid' => {
        'name' => 'valid',
        'type' => 'root',
        'database' => {
            'action' => 'container',
            'ipv4' => '10.0.3.13',
            'goodapp' => {
                'action' => 'application',
                'attribute' => 'value',
                'type' => 'app',
                'otherattr' => 'otherv',
                'name' => 'goodapp'
             },
            'name' => 'database',
            'type' => 'postgressql',
            'blog' => {
              'action' => 'container',
              'vhost' => 'myblog.mysite.fr',
              'name' => 'blog',
              'type' => 'wordpress'
            }
          }
        }
    }
}, 'FLib::Init::Helper::RunFileParser' );

my @TEST_2 = ('valid-database-blog');

my $TEST_3 = {
  'type' => 'postgressql',
  'action' => 'container',
  'name' => 'database',
  'ipv4' => '10.0.3.13',
  'goodapp' => {
      'attribute' => 'value',
      'action' => 'application',
      'name' => 'goodapp',
      'type' => 'app',
      'otherattr' => 'otherv'
    },
  'blog' => {
    'action' => 'container',
    'name' => 'blog',
    'type' => 'wordpress',
    'vhost' => 'myblog.mysite.fr'
  }
};
#}}}

#Test new
throws_ok {FLib::Init::Helper::RunFileParser->new('../t/FLib.Init.Helper.RunFileParser.d/correct.xml', 'nonexisting')}
  qr/^Host nonexisting doesn't exists in the runfile at/;

my $runList = FLib::Init::Helper::RunFileParser->new('../t/FLib.Init.Helper.RunFileParser.d/correct.xml', 'valid');
ok eq_hash $runList, $TEST_1;

throws_ok {FLib::Init::Helper::RunFileParser->new('../t/FLib.Init.Helper.RunFileParser.d/correct.xml', 'unvalidName')}
  qr/^Invalid character in name attribute at/;

throws_ok {FLib::Init::Helper::RunFileParser->new('../t/FLib.Init.Helper.RunFileParser.d/correct.xml', 'nameMissing')}
  qr/^Node without name attribute can't exist at/;

#Test getContainerChildPaths
throws_ok {$runList->getContainerChildPaths('database-blog')}
  qr/^Container database-blog was not found in runfile at/;
my @children = $runList->getContainerChildPaths('valid-database');
ok eq_array @children, @TEST_2;

#Test getContainer
throws_ok {$runList->getContainer('valid-database-nonexisting')}
  qr/^Container valid-database-nonexisting was not found in runfile at/;
my $container  = $runList->getContainer('valid-database');
ok eq_hash $container, $TEST_3;

done_testing;

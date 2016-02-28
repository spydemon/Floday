#!/usr/bin perl

use strict;
use warnings;

use v5.20;

use Test::More;
use Test::Exception;

use FLib::Init::Helper::DefinitionParser;

my $obj = FLib::Init::Helper::DefinitionParser->new('root');

ok(1+1 ==2);

done_testing;

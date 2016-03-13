#!/usr/perl

use strict;
use warnings;

use v5.20;

use Test::More;
use Test::Exception;
use Data::Dumper;

use FLib::Init::Model::Application;

#{{{Test variables
my $DEF_1 = {
  'type' => 'bashStuff',
  'path' => 'startup/hello.sh',
  'containerType' => 'validContainer',
  'parameters' => {
    'param1' => {
      'mandatory' => 'true'
    },
    'param2' => {
      'manatory' => 'false',
      'default' => '666'
    },
    'param3' => {
      'default' => '42'
    }
  }
};

my $DEF_2 = {
  'type' => 'bashStuff',
  'path' => 'startup/nothere.sh',
  'containerType' => 'validContainer',
  'parameters' => {
    'param1' => {
      'mandatory' => 'true'
    },
    'param2' => {
      'manatory' => 'false',
      'default' => '666'
    },
    'param3' => {
      'default' => '42'
    }
  }
};

my $DEF_3 = {
  'type' => 'bashStuff',
  'path' => 'startup/hello.sh',
  'containerType' => 'unexistingContainer',
  'parameters' => {
    'param1' => {
      'mandatory' => 'true'
    },
    'param2' => {
      'manatory' => 'false',
      'default' => '666'
    },
    'param3' => {
      'default' => '42'
    }
  }
};

my $DEF_4 = {
  'type' => 'bashStuff',
  'path' => 'startup/hello.sh',
  'containerType' => 'validContainer',
  'parameters' => {
    'param1' => {
      'mandatory' => 'true'
    },
    'param2' => {
      'manatory' => 'false',
      'default' => '666'
    },
    'param3-invalid' => {
      'default' => '42'
    }
  }
};

my $DEF_5 = {
  'type' => 'bashStuff',
  'path' => 'startup/hello.sh',
  'parameters' => {
    'param1' => {
      'mandatory' => 'true'
    },
    'param2' => {
      'manatory' => 'false',
      'default' => '666'
    },
    'param3' => {
      'default' => '42'
    }
  }
};

my $DEF_6 = {
  'type' => 'bashStuff',
  'containerType' => 'validContainer',
  'parameters' => {
    'param1' => {
      'mandatory' => 'true'
    },
    'param2' => {
      'manatory' => 'false',
      'default' => '666'
    },
    'param3' => {
      'default' => '42'
    }
  }
};

my $DEF_7 = {
  'type' => 'bashStuff',
  'path' => 'startup/hello.sh',
  'parameters' => {
    'param1' => {
      'mandatory' => 'true'
    },
    'param2' => {
      'manatory' => 'false',
      'default' => '666'
    },
    'param3' => {
      'default' => '42'
    }
  }
};

my $PARAM_1 = {
  'name' => 'firstApp',
  'type' => 'bashStuff',
  'parameters' => {
    'param1' => '50',
    'param2' => '8',
    'param4' => 'notexisting'
  }
};

my $PARAM_2 = {
  'name' => 'firstApp',
  'type' => 'bashStuff',
  'parameters' => {
    'param1' => '"invalid',
    'param2' => '8',
    'param4' => 'notexisting'
  }
};

my $PARAM_3 = {
  'name' => 'firstApp',
  'type' => 'bashStuff',
  'parameters' => {
    'param2' => '8',
    'param4' => 'notexisting'
  }
};

my $RES_1 = bless( {
  'path' => '/opt/floday/t/FLib.Init.Model.Application.d/validContainer/startup/hello.sh',
  'parameters' => {
    'param1' => '50',
    'param3' => '42',
    'param2' => '8'
  },
  'containerType' => 'validContainer',
  'type' => 'bashStuff',
  'name' => 'firstApp'
}, 'FLib::Init::Model::Application' );
#}}}

$ENV{FLODAY_CONTAINERS} = '/opt/floday/t/FLib.Init.Model.Application.d/';

#Normal execution
`chmod u+x $ENV{FLODAY_CONTAINERS}validContainer/startup/hello.sh`;
my $application = FLib::Init::Model::Application->new($PARAM_1, $DEF_1);
ok eq_hash $application, $RES_1;

#Check executable right
`chmod u-x $ENV{FLODAY_CONTAINERS}validContainer/startup/hello.sh`;
throws_ok {FLib::Init::Model::Application->new($PARAM_1, $DEF_1)}
  qr/validContainer\/startup\/hello.sh can not be executed at /;
`chmod u+x $ENV{FLODAY_CONTAINERS}validContainer/startup/hello.sh`;

#Check unexistinig application file
throws_ok {FLib::Init::Model::Application->new($PARAM_1, $DEF_2)}
  qr/^Application startup\/nothere.sh was not found for firstApp container at /;

#Check unexisting container
throws_ok {FLib::Init::Model::Application->new($PARAM_1, $DEF_3)}
  qr/^Definition of unexistingContainer type was not found at /;

#Check parameters value validity
throws_ok {FLib::Init::Model::Application->new($PARAM_2, $DEF_1)}
  qr/^Invalid character in parameter param1 value at /;

#Check parameters name validity
throws_ok {FLib::Init::Model::Application->new($PARAM_1, $DEF_4)}
  qr/^Invalid character in parameter name: param3-invalid at /;

#Check application without container type
throws_ok {FLib::Init::Model::Application->new($PARAM_1, $DEF_5)}
  qr/^Application without container type was definied at /;

#Mandatory parameter is not provided
throws_ok {FLib::Init::Model::Application->new($PARAM_3, $DEF_1)}
  qr/^Mandatory \"param1\" parameter is not provided for firstApp application at /;

#Path of application is not set
throws_ok {FLib::Init::Model::Application->new($PARAM_1, $DEF_6)}
  qr/^Path of firstApp application not set at /;

#Type of container was not set
throws_ok {FLib::Init::Model::Application->new($PARAM_1, $DEF_7)}
  qr/^Application without container type was definied at/;

my $app = $application->execute();
ok $app =~ /param1 50/;
ok $app =~ /param2 8/;
ok $app =~ /param3 42/;

done_testing;

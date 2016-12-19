#!/usr/bin/env perl

use v5.20;
use warnings;
use strict;

use Data::Dumper;
$Data::Dumper::Indent = 1;

use Log::Any::Adapter('File', 'log.txt');
use Test::Deep;
use Test::Exception;
use Test::More;

use Floday::Helper::Host;

my $attributesWithGoodName = {
  'parameters' => {
    'name' => 'agoodname',
    'type' => 'riuk',
    'external_ipv4' => '10.11.22.33'
  }
};

my $attributesWithWrongType = {
  'parameters' => {
    'name' => 'agoodname',
    'type' => 'riuk-xx'
  }
};

my $attributesWithWrongName = {
  'parameters' => {
    'name' => 'yol0~~',
    'type' => 'riuk'
  }
};

my $attributesWithoutName = {
  'parameters' => {
    'type' => 'riuk-php',
    'type' => 'riuk'
  }
};

my $attributesWithUnexistingParam = {
  'parameters' => {
    'name' => 'agoodname',
    'type' => 'riuk',
    'external_ipv4' => '10.11.22.33',
    'unknown_param' => 'a value'
  }
};

my $attributesWithChild = {
  'parameters' => {
    'name' => 'agoodname',
    'type' => 'riuk',
    'external_ipv4' => '10.11.22.35'
  },
  'applications' => {
    'website1' => {
      'parameters' => {
        'type' => 'web',
        'ipv4' => '10.0.0.4',
        'gateway' => '10.0.0.1'
      }
    },
    'website2' => {
      'parameters' => {
        'type' => 'sftp',
        'arbitrary_param' => '1',
        'ipv4' => '10.0.0.5',
        'gateway' => '10.0.0.1'
      }
    }
  }
};

my $attributesWithMissingParams = {
  'parameters' => {
    'name' => 'integration',
    'type' => 'riuk'
  },
  'applications' => {
    'ctr' => {
      'parameters' => {
        'arbitrary_param' => 'hello',
        'type'=> 'mumble',
        'mandatory_param' => '1',
      }
    },
    'rnbw' => {
      'parameters' => {
        'mandatory_param_two' => 'AAooo',
        'type' => 'mumble'
      }
    }
  }
};

my $attributesWithMissingTypeInChildren = {
  'parameters' => {
    'name' => 'integration',
    'type' => 'riuk'
  },
  'applications' => {
    'ctr' => {
      'parameters' => {
        'arbitrary_param' => 'hello',
        'mandatory_param' => '1'
      }
    },
    'rnbw' => {
      'parameters' => {
        'mandatory_param_two' => 'AAAooo',
        'type' => 'mumble'
      }
    }
  }
};

my $complexHostToHashResult = {
  'applications' => {
    'website2' => {
      'parameters' => {
        'data_out' => {
          'mandatory' => 'false'
        },
        'type' => {
          'value' => 'sftp',
          'required' => 'true'
        },
        'gateway' => {
          'mandatory' => 'true',
          'value' => '10.0.0.1'
        },
        'ipv4' => {
          'mandatory' => 'true',
          'value' => '10.0.0.5'
        },
        'arbitrary_param' => {
          'mandatory' => 'false',
          'value' => '1'
        },
        'second_arbitrary_param' => {
          'mandatory' => 'false'
        },
        'iface' => {
          'mandatory' => 'true',
          'value' => 'eth0'
        },
        'bridge' => {
          'mantatory' => 'true',
          'value' => 'lxcbr0'
        },
        'template' => {
          'mandatory' => 'true',
          'value' => 'flodayalpine -- version 3.4'
        },
        'netmask' => {
          'value' => '255.255.255.0',
          'mandatory' => 'true'
        },
        'name' => {
          'value' => 'website2',
          'required' => 'true'
        },
        'data_in' => {
          'mandatory' => 'false'
        },
        'container_path' => {
          'value' => 'riuk-sftp'
        },
        'instance_path' => {
          'value' => 'agoodname-website2'
        }
      },
      'setups' => {
        'data' => {
          'priority' => '30',
          'exec' => 'riuk/children/core/setups/data.pl'
        },
        'network' => {
          'exec' => 'riuk/children/core/setups/network.pl',
          'priority' => '10'
        }
      },
      'inherit' => [
        'riuk-core'
      ]
    },
    'website1' => {
      'setups' => {
        'network' => {
          'exec' => 'riuk/children/core/setups/network.pl',
          'priority' => '10'
        },
        'lighttpd' => {
          'priority' => '20',
          'exec' => 'riuk/children/web/setups/lighttpd.pl'
        },
        'data' => {
          'priority' => '30',
          'exec' => 'riuk/children/core/setups/data.pl'
        }
      },
      'inherit' => [
        'riuk-core'
      ],
      'parameters' => {
        'iface' => {
          'value' => 'eth0',
          'mandatory' => 'true'
        },
        'bridge' => {
          'mantatory' => 'true',
          'value' => 'lxcbr0'
        },
        'template' => {
          'mandatory' => 'true',
          'value' => 'flodayalpine -- version 3.4'
        },
        'name' => {
          'value' => 'website1',
          'required' => 'true'
        },
        'netmask' => {
          'value' => '255.255.255.0',
          'mandatory' => 'true'
        },
        'data_in' => {
          'mandatory' => 'false'
        },
        'data_out' => {
          'mandatory' => 'false'
        },
        'gateway' => {
          'mandatory' => 'true',
          'value' => '10.0.0.1'
        },
        'type' => {
          'value' => 'web',
          'required' => 'true'
        },
        'ipv4' => {
          'mandatory' => 'true',
          'value' => '10.0.0.4'
        },
        'container_path' => {
          'value' => 'riuk-web'
        },
        'instance_path' => {
          'value' => 'agoodname-website1'
        }
      }
    }
  },
  'inherit' => [],
  'parameters' => {
    'type' => {
      'value' => 'riuk',
      'required' => 'true'
    },
    'useless_param' => {
      'value' => 'we dont care',
      'required' => 'false'
    },
    'name' => {
      'value' => 'agoodname',
      'required' => 'true'
    },
    'external_ipv4' => {
      'required' => 'true',
      'value' => '10.11.22.35'
    },
    'container_path' => {
      'value' => 'riuk'
    },
    'instance_path' => {
      'value' => 'agoodname'
    }
  }
};

my @missingParamsErrors = (
  'The \'mandatory_param\' mandatory parameter is missing in \'integration-rnbw\' application.',
  'The \'mandatory_param_two\' mandatory parameter is missing in \'integration-ctr\' application.',
  '\'mandatory_param_two\' parameter in \'integration-rnbw\' has value \'AAooo\' that doesn\'t respect the \'^[A|B]{3,5}\' regex.'
);

ok (Floday::Helper::Host->new('runfile' => $attributesWithGoodName), 'A instance is correctly created.');
throws_ok {Floday::Helper::Host->new('runfile' => $attributesWithWrongName)}
  qr/Invalid name 'yol0~~' for host initialization/,
  'Check exception at invalid hostname.';
throws_ok {Floday::Helper::Host->new('runfile' => $attributesWithoutName)}
  qr/Invalid name '' for host initialization/,
  'Check exception at invalid hostname.';
throws_ok {Floday::Helper::Host->new('runfile' => $attributesWithWrongType)}
  qr/Invalid type 'riuk-xx' for host initialization/,
  'Check exception at invalid container type.';
throws_ok {Floday::Helper::Host->new('runfile' => $attributesWithMissingTypeInChildren)->toHash()}
  qr/Missing name or type for an application/,
  'Check exception if child type is missing.';

#Test _mergeDefinition function:
my $host= Floday::Helper::Host->new('runfile' => $attributesWithGoodName);
cmp_ok ($host->toHash()->{'parameters'}{'external_ipv4'}{'value'}, 'eq', '10.11.22.33', 'Check runfile parameters integration in runlist.');
cmp_ok ($host->toHash()->{'parameters'}{'useless_param'}{'value'}, 'eq', 'we dont care', 'Check default runlist parameters values.');
throws_ok {Floday::Helper::Host->new('runfile' => $attributesWithUnexistingParam)->toHash()}
  qr/Parameter 'unknown_param' present in runfile but that doesn't exist in container definition/,
  'Check exception on unexisting parameter in container definition.';

#Test _getContainerPath:
my $complexHost = Floday::Helper::Host->new('runfile' => $attributesWithChild);
$complexHost->{instancePathToManage} = 'agoodname-website1';
cmp_ok $complexHost->_getContainerPath(), 'eq', 'riuk-web', 'Check containerTypePath resolution.';
$complexHost->{instancePathToManage} = 'agoodname-website2';
cmp_ok $complexHost->_getContainerPath(), 'eq', 'riuk-sftp', 'Check containerTypePath resolution.';
$complexHost->{instancePathToManage} = 'agoodname';

#Test toHash
cmp_deeply $complexHost->toHash(), $complexHostToHashResult, 'Check toHash result.';

#Test error management in runlist initialization.
my $testErrors = Floday::Helper::Host->new('runfile' => $attributesWithMissingParams);
$testErrors->toHash();
my @errorsFetched = @{$testErrors->getAllErrors()};
cmp_bag(\@errorsFetched, \@missingParamsErrors, 'Test mandatory parameters checker');

done_testing;

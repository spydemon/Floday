#!/usr/bin/env perl

use v5.20;
use warnings;
use strict;

use Log::Any::Adapter('+Floday::Helper::Logging', 'log_level', 'trace');
use Test::Deep;
use Test::Exception;
use Test::More;

use Floday::Helper::Host;

my $attributes_with_good_name = {
	'parameters' => {
		'name'          => 'agoodname',
		'type'          => 'riuk',
		'external_ipv4' => '10.11.22.33'
	}
};

my $attributes_with_wrong_type = {
	'parameters' => {
		'name' => 'agoodname',
		'type' => 'riuk-xx'
	}
};

my $attributes_with_wrong_name = {
	'parameters' => {
		'name' => 'yol0~~',
		'type' => 'riuk'
	}
};

my $attributes_without_name = {
	'parameters' => {
		'type' => 'riuk-php',
		'type' => 'riuk'
	}
};

my $attributes_with_unexisting_param = {
	'parameters' => {
		'name'          => 'agoodname',
		'type'          => 'riuk',
		'external_ipv4' => '10.11.22.33',
		'unknown_param' => 'a value'
	}
};

my $attributes_with_child = {
	'parameters'   => {
		'name'          => 'agoodname',
		'type'          => 'riuk',
		'external_ipv4' => '10.11.22.35'
	},
	'applications' => {
		'website1' => {
			'parameters' => {
				'type'    => 'web',
				'ipv4'    => '10.0.0.4',
				'gateway' => '10.0.0.1'
			}
		},
		'website2' => {
			'parameters' => {
				'type'            => 'sftp',
				'arbitrary_param' => '1',
				'ipv4'            => '10.0.0.5',
				'gateway'         => '10.0.0.1'
			}
		}
	}
};

my $attributes_with_missing_params = {
	'parameters'   => {
		'name' => 'integration',
		'type' => 'riuk'
	},
	'applications' => {
		'ctr'  => {
			'parameters' => {
				'arbitrary_param' => 'hello',
				'type'            => 'mumble',
				'mandatory_param' => '1',
			}
		},
		'rnbw' => {
			'parameters' => {
				'mandatory_param_two' => 'AAooo',
				'type'                => 'mumble'
			}
		}
	}
};

my $attributes_with_missing_type_in_children = {
	'parameters'   => {
		'name' => 'integration',
		'type' => 'riuk'
	},
	'applications' => {
		'ctr'  => {
			'parameters' => {
				'arbitrary_param' => 'hello',
				'mandatory_param' => '1'
			}
		},
		'rnbw' => {
			'parameters' => {
				'mandatory_param_two' => 'AAAooo',
				'type'                => 'mumble'
			}
		}
	}
};

my $complex_host_to_hash_result = {
	'applications' => {
		'website2' => {
			'parameters' => {
				'data_out'               => {
					'mandatory' => 'false'
				},
				'type'                   => {
					'value'    => 'sftp',
					'required' => 'true'
				},
				'gateway'                => {
					'mandatory' => 'true',
					'value'     => '10.0.0.1'
				},
				'ipv4'                   => {
					'mandatory' => 'true',
					'value'     => '10.0.0.5'
				},
				'arbitrary_param'        => {
					'mandatory' => 'false',
					'value'     => '1'
				},
				'second_arbitrary_param' => {
					'mandatory' => 'false'
				},
				'iface'                  => {
					'mandatory' => 'true',
					'value'     => 'eth0'
				},
				'bridge'                 => {
					'mantatory' => 'true',
					'value'     => 'lxcbr0'
				},
				'template'               => {
					'mandatory' => 'true',
					'value'     => 'flodayalpine -- version 3.4'
				},
				'netmask'                => {
					'value'     => '255.255.255.0',
					'mandatory' => 'true'
				},
				'name'                   => {
					'value'    => 'website2',
					'required' => 'true'
				},
				'data_in'                => {
					'mandatory' => 'false'
				},
				'container_path'         => {
					'value' => 'riuk-sftp'
				},
				'application_path'          => {
					'value' => 'agoodname-website2'
				}
			},
			'setups'     => {
				'data'    => {
					'priority' => '30',
					'exec'     => 'riuk/children/core/setups/data.pl'
				},
				'network' => {
					'exec'     => 'riuk/children/core/setups/network.pl',
					'priority' => '10'
				}
			},
			'hooks'      => {
				'lxc_deploy_before'  => {
					'open_firewall' => {
						'exec'     => 'riuk/children/core/hooks/lxc_deploy_before/open_firewall.pl',
						'priority' => 10
					}
				},
				'lxc_deploy_after'   => {
					'close_firewall' => {
						'exec'     => 'riuk/children/core/hooks/lxc_deploy_after/close_firewall.pl',
						'priority' => 10
					}
				},
				'lxc_destroy_before' => {
					'clear_filesystem' => {
						'exec'     => 'riuk/children/core/hooks/lxc_destroy_before/clear_filesystem.pl',
						'priority' => 10
					}
				},
				'lxc_destroy_after'  => {
					'update_fstab' => {
						'exec'     => 'riuk/children/core/hooks/lxc_destroy_after/update_fstab.pl',
						'priority' => 10
					}
				}
			},
			'inherit'    => [
				'riuk-core'
			]
		},
		'website1' => {
			'setups'     => {
				'network'  => {
					'exec'     => 'riuk/children/core/setups/network.pl',
					'priority' => '10'
				},
				'lighttpd' => {
					'priority' => '20',
					'exec'     => 'riuk/children/web/setups/lighttpd.pl'
				},
				'data'     => {
					'priority' => '30',
					'exec'     => 'riuk/children/core/setups/data.pl'
				}
			},
			'end_setups' => {
				'iptables_save' => {
					'exec'     => 'riuk/children/web/end_setup/iptables_save.pl',
					'priority' => 10
				}
			},
			'hooks'      => {
				'lxc_deploy_before'  => {
					'open_firewall' => {
						'exec'     => 'riuk/children/core/hooks/lxc_deploy_before/open_firewall.pl',
						'priority' => 10
					}
				},
				'lxc_deploy_after'   => {
					'close_firewall' => {
						'exec'     => 'riuk/children/core/hooks/lxc_deploy_after/close_firewall.pl',
						'priority' => 10
					}
				},
				'lxc_destroy_before' => {
					'clear_filesystem' => {
						'exec'     => 'riuk/children/core/hooks/lxc_destroy_before/clear_filesystem.pl',
						'priority' => 10
					}
				},
				'lxc_destroy_after'  => {
					'update_fstab' => {
						'exec'     => 'riuk/children/core/hooks/lxc_destroy_after/update_fstab.pl',
						'priority' => 10
					}
				}
			},
			'inherit'    => [
				'riuk-core'
			],
			'parameters' => {
				'iface'          => {
					'value'     => 'eth0',
					'mandatory' => 'true'
				},
				'bridge'         => {
					'mantatory' => 'true',
					'value'     => 'lxcbr0'
				},
				'template'       => {
					'mandatory' => 'true',
					'value'     => 'flodayalpine -- version 3.4'
				},
				'name'           => {
					'value'    => 'website1',
					'required' => 'true'
				},
				'netmask'        => {
					'value'     => '255.255.255.0',
					'mandatory' => 'true'
				},
				'data_in'        => {
					'mandatory' => 'false'
				},
				'data_out'       => {
					'mandatory' => 'false'
				},
				'gateway'        => {
					'mandatory' => 'true',
					'value'     => '10.0.0.1'
				},
				'type'           => {
					'value'    => 'web',
					'required' => 'true'
				},
				'ipv4'           => {
					'mandatory' => 'true',
					'value'     => '10.0.0.4'
				},
				'container_path' => {
					'value' => 'riuk-web'
				},
				'application_path'  => {
					'value' => 'agoodname-website1'
				}
			}
		}
	},
	'inherit'      => [ ],
	'parameters'   => {
		'type'           => {
			'value'    => 'riuk',
			'required' => 'true'
		},
		'useless_param'  => {
			'value'    => 'we dont care',
			'required' => 'false'
		},
		'name'           => {
			'value'    => 'agoodname',
			'required' => 'true'
		},
		'external_ipv4'  => {
			'required' => 'true',
			'value'    => '10.11.22.35'
		},
		'container_path' => {
			'value' => 'riuk'
		},
		'application_path'  => {
			'value' => 'agoodname'
		}
	}
};

my @missing_params_errors = (
  'The \'mandatory_param\' mandatory parameter is missing in \'integration-rnbw\' application.',
  'The \'mandatory_param_two\' mandatory parameter is missing in \'integration-ctr\' application.',
  '\'mandatory_param_two\' parameter in \'integration-rnbw\' has value \'AAooo\' that doesn\'t respect the \'^[A|B]{3,5}\' regex.'
);

ok (Floday::Helper::Host->new('runfile' => $attributes_with_good_name), 'A application is correctly created.');
throws_ok {Floday::Helper::Host->new('runfile' => $attributes_with_wrong_name)}
  qr/Invalid name 'yol0~~' for host initialization/,
  'Check exception at invalid hostname.';
throws_ok {Floday::Helper::Host->new('runfile' => $attributes_without_name)}
  qr/Invalid name '' for host initialization/,
  'Check exception at invalid hostname.';
throws_ok {Floday::Helper::Host->new('runfile' => $attributes_with_wrong_type)}
  qr/Invalid type 'riuk-xx' for host initialization/,
  'Check exception at invalid container type.';
throws_ok {Floday::Helper::Host->new('runfile' => $attributes_with_missing_type_in_children)->to_hash()}
  qr/Missing name or type for an application/,
  'Check exception if child type is missing.';

#Test _mergeDefinition function:
my $host = Floday::Helper::Host->new('runfile' => $attributes_with_good_name);
cmp_ok ($host->to_hash()->{'parameters'}{'external_ipv4'}{'value'}, 'eq', '10.11.22.33',
  'Check runfile parameters integration in runlist.');
cmp_ok ($host->to_hash()->{'parameters'}{'useless_param'}{'value'}, 'eq', 'we dont care',
  'Check default runlist parameters values.');
throws_ok {Floday::Helper::Host->new('runfile' => $attributes_with_unexisting_param)->to_hash()}
  qr/Parameter 'unknown_param' present in runfile but that doesn't exist in container definition/,
  'Check exception on unexisting parameter in container definition.';

#Test _get_container_path:
my $complex_host = Floday::Helper::Host->new('runfile' => $attributes_with_child);
$complex_host->{application_path_to_manage} = 'agoodname-website1';
cmp_ok $complex_host->_get_container_path(), 'eq', 'riuk-web', 'Check _get_container_path resolution.';
$complex_host->{application_path_to_manage} = 'agoodname-website2';
cmp_ok $complex_host->_get_container_path(), 'eq', 'riuk-sftp', 'Check _get_container_path resolution.';
$complex_host->{application_path_to_manage} = 'agoodname';

#Test to_hash
cmp_deeply $complex_host->to_hash(), $complex_host_to_hash_result, 'Check to_hash result.';

#Test error management in runlist initialization.
my $test_errors = Floday::Helper::Host->new('runfile' => $attributes_with_missing_params);
$test_errors->to_hash();
my @errors_fetched = @{$test_errors->get_all_errors()};
cmp_bag(\@errors_fetched, \@missing_params_errors, 'Test mandatory parameters checker');

done_testing;

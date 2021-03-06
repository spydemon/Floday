#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;

use Log::Any::Adapter('File', 'floday_helper_runlist.log');
use Test::Deep;
use Test::Exception;
use Test::More;

use Floday::Helper::Runlist;

my $runlist = {
	'hosts' => {
		'backup' => {
			'parameters' => {
				'type' => 'riuk',
				'name' => 'backup',
				'external_ipv4' => '192.168.15.152',
				'container_path' => 'riuk',
				'application_path' => 'backup',
				'useless_param' => 'we dont care'
			},
			'applications' => {
				'web' => {
					'parameters' => {
						'type' => 'web',
						'name' => 'web',
						'bridge' => 'lxcbr0',
						'iface' => 'eth0',
						'ipv4' => '10.0.3.5',
						'gateway' => '10.0.3.1',
						'netmask' => '255.255.255.0',
						'template' => 'flodayalpine -- version 3.4',
						'container_path' => 'riuk-web',
						'application_path' => 'backup-web'
					},
					'setups' => {
						'network' => {
							'avoidable' => 'false',
							'exec' => 'riuk/children/core/setups/network.pl',
							'priority' => 10
						},
						'lighttpd' => {
							'exec' => 'riuk/children/web/setups/lighttpd.pl',
							'priority' => 20
						},
						'data' => {
							'avoidable' => 'true',
							'exec' => 'riuk/children/core/setups/data.pl',
							'priority' => 30
						}
					},
					'end_setups' => {
						'iptables_save' => {
							'exec' => 'riuk/children/web/end_setup/iptables_save.pl',
							'priority' => 10
						}
					},
					'hooks' => {
						'lxc_deploy_before' => {
							'open_firewall' => {
								'exec' => 'riuk/children/core/hooks/lxc_deploy_before/open_firewall.pl',
								'priority' => 10
							}
						},
						'lxc_deploy_after' => {
							'close_firewall' => {
								'exec' => 'riuk/children/core/hooks/lxc_deploy_after/close_firewall.pl',
								'priority' => 10
							}
						},
						'lxc_destroy_before' => {
							'clear_filesystem' => {
								'exec' => 'riuk/children/core/hooks/lxc_destroy_before/clear_filesystem.pl',
								'priority' => 10
							}
						},
						'lxc_destroy_after' => {
							'update_fstab' => {
								'exec' => 'riuk/children/core/hooks/lxc_destroy_after/update_fstab.pl',
								'priority' => 10
							}
						}
					},
					'avoidance' => {
						'importer' => {
							'exec' => 'riuk/children/core/avoidance/importer.pl',
							'priority' => '1-20'
						},
						'parameters' => {
							'priority' => '1-10',
							'exec' => 'riuk/children/core/avoidance/parameters.pl'
						}
					},
				},
			},
		},
		'integration' => {
			'parameters' => {
				'type' => 'riuk',
				'name' => 'integration',
				'external_ipv4' => '192.168.15.151',
				'useless_param' => 'we dont care',
				'container_path' => 'riuk',
				'application_path' => 'integration'
			},
			'applications' => {
				web => {
					'parameters' => {
						'type' => 'web',
						'name' => 'web',
						'bridge' => 'lxcbr0',
						'iface' => 'eth0',
						'ipv4' => '10.0.3.5',
						'gateway' => '10.0.3.1',
						'netmask' => '255.255.255.0',
						'template' => 'flodayalpine -- version 3.4',
						'container_path' => 'riuk-web',
						'application_path' => 'integration-web'
					},
					'setups' => {
						'network' => {
							'avoidable' => 'false',
							'exec' => 'riuk/children/core/setups/network.pl',
							'priority' => 10
						},
						'lighttpd' => {
							'exec' => 'riuk/children/web/setups/lighttpd.pl',
							'priority' => 20
						},
						'data' => {
							'avoidable' => 'true',
							'exec' => 'riuk/children/core/setups/data.pl',
							'priority' => 30
						}
					},
					'end_setups' => {
						'iptables_save' => {
							'exec' => 'riuk/children/web/end_setup/iptables_save.pl',
							'priority' => 10
						}
					},
					'hooks' => {
						'lxc_deploy_before' => {
							'open_firewall' => {
								'exec' => 'riuk/children/core/hooks/lxc_deploy_before/open_firewall.pl',
								'priority' => 10
							}
						},
						'lxc_deploy_after' => {
							'close_firewall' => {
								'exec' => 'riuk/children/core/hooks/lxc_deploy_after/close_firewall.pl',
								'priority' => 10
							}
						},
						'lxc_destroy_before' => {
							'clear_filesystem' => {
								'exec' => 'riuk/children/core/hooks/lxc_destroy_before/clear_filesystem.pl',
								'priority' => 10
							}
						},
						'lxc_destroy_after' => {
							'update_fstab' => {
								'exec' => 'riuk/children/core/hooks/lxc_destroy_after/update_fstab.pl',
								'priority' => 10
							}
						}
					},
					'avoidance' => {
						'importer' => {
							'exec' => 'riuk/children/core/avoidance/importer.pl',
							'priority' => '1-20'
						},
						'parameters' => {
							'priority' => '1-10',
							'exec' => 'riuk/children/core/avoidance/parameters.pl'
						}
					},
					'applications' => {
						'test' => {
							'parameters' => {
								'type' => 'php',
								'name' => 'test',
								'data_in' => 'floday.d/integration-web-test/php',
								'data_out' => '/var/www',
								'bridge' => 'lxcbr0',
								'iface' => 'eth0',
								'ipv4' => '10.0.3.6',
								'gateway' => '10.0.3.1',
								'netmask' => '255.255.255.0',
								'template' => 'flodayalpine -- version 3.4',
								'hostname' => 'test.keh.keh',
								'container_path' => 'riuk-web-php',
								'application_path' => 'integration-web-test'
							},
							'setups' => {
								'network' => {
									'avoidable' => 'false',
									'exec' => 'riuk/children/core/setups/network.pl',
									'priority' => 10
								},
								'php' => {
									'exec' => 'riuk/children/web/children/php/setups/php.pl',
									'priority' => 20
								},
								'data' => {
									'avoidable' => 'true',
									'exec' => 'riuk/children/core/setups/data.pl',
									'priority' => 30
								}
							},
							'hooks' => {
								'lxc_deploy_before' => {
									'open_firewall' => {
										'exec' => 'riuk/children/core/hooks/lxc_deploy_before/open_firewall.pl',
										'priority' => 10
									}
								},
								'lxc_deploy_after' => {
									'close_firewall' => {
										'exec' => 'riuk/children/core/hooks/lxc_deploy_after/close_firewall.pl',
										'priority' => 10
									}
								},
								'lxc_destroy_before' => {
									'clear_filesystem' => {
										'exec' => 'riuk/children/core/hooks/lxc_destroy_before/clear_filesystem.pl',
										'priority' => 10
									}
								},
								'lxc_destroy_after' => {
									'update_fstab' => {
										'exec' => 'riuk/children/core/hooks/lxc_destroy_after/update_fstab.pl',
										'priority' => 10
									}
								}
							},
							'avoidance' => {
								'importer' => {
									'exec' => 'riuk/children/core/avoidance/importer.pl',
									'priority' => '1-20'
								},
								'parameters' => {
									'priority' => '1-10',
									'exec' => 'riuk/children/web/children/php/avoidance/parameters.pl'
								}
							},
						},
						'secondtest' => {
							'parameters' => {
								'type' => 'php',
								'name' => 'secondtest',
								'data_in' => 'floday.d/integration-web-secondtest/php',
								'data_out' => '/var/www',
								'bridge' => 'lxcbr0',
								'iface' => 'eth0',
								'ipv4' => '10.0.3.7',
								'gateway' => '10.0.3.1',
								'netmask' => '255.255.255.0',
								'template' => 'flodayalpine -- version 3.4',
								'hostname' => 'test2.keh.keh',
								'container_path' => 'riuk-web-php',
								'application_path' => 'integration-web-secondtest'
							},
							'setups' => {
								'network' => {
									'avoidable' => 'false',
									'exec' => 'riuk/children/core/setups/network.pl',
									'priority' => 10
								},
								'php' => {
									'exec' => 'riuk/children/web/children/php/setups/php.pl',
									'priority' => 20
								},
								'data' => {
									'avoidable' => 'true',
									'exec' => 'riuk/children/core/setups/data.pl',
									'priority' => 30
								}
							},
							'hooks' => {
								'lxc_deploy_before' => {
									'open_firewall' => {
										'exec' => 'riuk/children/core/hooks/lxc_deploy_before/open_firewall.pl',
										'priority' => 10
									}
								},
								'lxc_deploy_after' => {
									'close_firewall' => {
										'exec' => 'riuk/children/core/hooks/lxc_deploy_after/close_firewall.pl',
										'priority' => 10
									}
								},
								'lxc_destroy_before' => {
									'clear_filesystem' => {
										'exec' => 'riuk/children/core/hooks/lxc_destroy_before/clear_filesystem.pl',
										'priority' => 10
									}
								},
								'lxc_destroy_after' => {
									'update_fstab' => {
										'exec' => 'riuk/children/core/hooks/lxc_destroy_after/update_fstab.pl',
										'priority' => 10
									}
								}
							},
							'avoidance' => {
								'importer' => {
									'exec' => 'riuk/children/core/avoidance/importer.pl',
									'priority' => '1-20'
								},
								'parameters' => {
									'priority' => '1-10',
									'exec' => 'riuk/children/web/children/php/avoidance/parameters.pl'
								}
							},
						}
					}
				}
			}
		}
	}
};

my $test = Floday::Helper::Runlist->new(runfile => 'floday_helper_runlist.d/runfile.yml');

my @children = $test->get_sub_applications_of('integration-web');
cmp_deeply(\@children, ['integration-web-secondtest', 'integration-web-test'], 'Test of getApplicationsOf seems good.');

my %parameters = $test->get_parameters_for_application('integration-web-secondtest');
is $parameters{bridge}, 'lxcbr0', 'Test of get_parameters_for_application seems good.';

my %scripts = $test->get_execution_list_by_priority_for_application('integration-web-test', 'setups');
cmp_deeply([sort keys %scripts], [10, 20, 30], 'get_setups_by_priority_for_application seems to correctly apply priorities.');
cmp_deeply($test->get_runlist(), $runlist, 'get_runlist return the expected runlist.');

throws_ok {Floday::Helper::Runlist->new(runfile => 'floday_helper_runlist.d/broken-runfile.yml')}
  qr#Errors in runfile:
/hosts/integration/applications/web/applications/secondtest: Properties not allowed: something_else.
/hosts/integration/applications/web/applications/test/parameters/object: Expected string - got object.#,
  'Check runfile YAML schema validation.';

throws_ok {Floday::Helper::Runlist->new(runfile => 'floday_helper_runlist.d/runfile-broken.yml')}
  qr#Errors in runfile:
/hosts/integration/applications/web/parameters/type: Missing property.#,
  'Check that "type" property is mandatory in "parameters" node.';

cmp_ok($test->is_application_existing('integration-stuff-retest-no-problem'), '==', 0, 'Check an is_application_existing with a false return');
cmp_ok($test->is_application_existing('integration-web-test'), '==', 1, 'Check an is_application_existing with a true return');


`echo > floday_helper_runlist.log`;
Floday::Helper::Runlist
  ->new(runfile => 'floday_helper_runlist.d/runfile-collision.yml')
  ->get_execution_list_by_priority_for_application('integration-collision', 'setups');
ok(
  `cat floday_helper_runlist.log | grep -F "A collision occurred for the setups script with the priority 50."`,
  'Check that we log correctly collisions with scripts with the same priority.'
);

done_testing;

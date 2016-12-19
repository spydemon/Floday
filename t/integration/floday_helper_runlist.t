#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;

use Data::Dumper;
use Log::Any::Adapter('File', 'log.txt');
use Test::Deep;
use Test::More;

use Floday::Helper::Runlist;

$Data::Dumper::Indent = 1;

my $runlist = {
	'hosts' => {
		'backup' => {
			'parameters' => {
				'type' => 'riuk',
				'name' => 'backup',
				'external_ipv4' => '192.168.15.152',
				'container_path' => 'riuk',
				'instance_path' => 'backup',
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
						'instance_path' => 'backup-web'
					},
					'setups' => {
						'network' => {
							'exec' => 'riuk/children/core/setups/network.pl',
							'priority' => 10
						},
						'lighttpd' => {
							'exec' => 'riuk/children/web/setups/lighttpd.pl',
							'priority' => 20
						},
						'data' => {
							'exec' => 'riuk/children/core/setups/data.pl',
							'priority' => 30
						}
					}
				}
			}
		},
		'integration' => {
			'parameters' => {
				'type' => 'riuk',
				'name' => 'integration',
				'external_ipv4' => '192.168.15.151',
				'useless_param' => 'we dont care',
				'container_path' => 'riuk',
				'instance_path' => 'integration'
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
						'instance_path' => 'integration-web'
					},
					'setups' => {
						'network' => {
							'exec' => 'riuk/children/core/setups/network.pl',
							'priority' => 10
						},
						'lighttpd' => {
							'exec' => 'riuk/children/web/setups/lighttpd.pl',
							'priority' => 20
						},
						'data' => {
							'exec' => 'riuk/children/core/setups/data.pl',
							'priority' => 30
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
								'instance_path' => 'integration-web-test'
							},
							'setups' => {
								'network' => {
									'exec' => 'riuk/children/core/setups/network.pl',
									'priority' => 10
								},
								'php' => {
									'exec' => 'riuk/children/web/children/php/setups/php.pl',
									'priority' => 20
								},
								'data' => {
									'exec' => 'riuk/children/core/setups/data.pl',
									'priority' => 30
								}
							}
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
								'instance_path' => 'integration-web-secondtest'
							},
							'setups' => {
								'network' => {
									'exec' => 'riuk/children/core/setups/network.pl',
									'priority' => 10
								},
								'php' => {
									'exec' => 'riuk/children/web/children/php/setups/php.pl',
									'priority' => 20
								},
								'data' => {
									'exec' => 'riuk/children/core/setups/data.pl',
									'priority' => 30
								}
							}
						}
					}
				}
			}
		}
	}
};

my $test = Floday::Helper::Runlist->new(runfile => 'floday_helper_runlist.d/runfile.yml');
my @children = $test->getApplicationsOf('integration-web');
cmp_deeply(\@children, ['integration-web-secondtest', 'integration-web-test'], 'Test of getApplicationsOf seems good.');
my %parameters = $test->getParametersForApplication('integration-web-secondtest');
is $parameters{bridge}, 'lxcbr0', 'Test of getParametersForApplication seems good.';
my %scripts = $test->getSetupsByPriorityForApplication('integration-web-test');
cmp_deeply([sort keys %scripts], [10, 20, 30], 'getSetupsByPriorityForApplication seems to correctly apply priorities.');
cmp_deeply($test->getRunlist(), $runlist, 'getPlainData return the expected runlist.');

done_testing;

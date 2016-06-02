#!/usr/bin/env perl

use v5.20;
use strict;

use Data::Dumper;
use Virt::LXC;
use YAML::Tiny;

$Data::Dumper::Indent = 1;

#{{{Runlist
my $runList = {
	'hosts' => {
		'integration' => {
			'parameters' => {
				'type' => 'riuk',
				'name' => 'integration',
				'external_ipv4' => '192.168.15.151'
			},
			'applications' => {
				web => {
					'parameters' => {
						'type' => 'riuk-http',
						'name' => 'integration-web',
						'bridge' => 'lxcbr0',
						'iface' => 'eth0',
						'ipv4' => '10.0.3.5',
						'gateway' => '10.0.3.1',
						'netmask' => '255.255.255.0',
						'template' => 'alpine -- --release v3.3'
					},
					'setup' => {
						'network' => {
							'exec' => '/opt/floday/containers/riuk/children/core/setup/network.pl',
							'priority' => 10
						},
						'lighttpd' => {
							'exec' => '/opt/floday/containers/riuk/children/web/setup/lighttpd.pl',
							'priority' => 20
						}
					},
					'applications' => {
						'test' => {
							'parameters' => {
								'type' => 'riuk-http-php',
								'name' => 'integration-web-test',
								'data_in' => 'floday.d/integration-web-test/php',
								'data_out' => '/var/www',
								'bridge' => 'lxcbr0',
								'iface' => 'eth0',
								'ipv4' => '10.0.3.6',
								'gateway' => '10.0.3.1',
								'netmask' => '255.255.255.0',
								'template' => 'alpine -- --release v3.3',
								'hostname' => 'test.keh.keh'
							},
							'setup' => {
								'network' => {
									'exec' => '/opt/floday/containers/riuk/children/core/setup/network.pl',
									'priority' => 10
								},
								'php' => {
									'exec' => '/opt/floday/containers/riuk/children/web/children/php/setup/php.pl',
									'priority' => 20
								},
								'data' => {
									'exec' => '/opt/floday/containers/riuk/children/core/setup/data.pl',
									'priority' => 30
								}
							}
						},
						'secondtest' => {
							'parameters' => {
								'type' => 'riuk-http-php',
								'name' => 'integration-web-secondtest',
								'data_in' => 'floday.d/integration-web-secondtest/php',
								'data_out' => '/var/www',
								'bridge' => 'lxcbr0',
								'iface' => 'eth0',
								'ipv4' => '10.0.3.7',
								'gateway' => '10.0.3.1',
								'netmask' => '255.255.255.0',
								'template' => 'alpine -- --release v3.3',
								'hostname' => 'test2.keh.keh'
							},
							'setup' => {
								'network' => {
									'exec' => '/opt/floday/containers/riuk/children/core/setup/network.pl',
									'priority' => 10
								},
								'php' => {
									'exec' => '/opt/floday/containers/riuk/children/web/children/php/setup/php.pl',
									'priority' => 20
								},
								'data' => {
									'exec' => '/opt/floday/containers/riuk/children/core/setup/data.pl',
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
#}}}

sub getScriptsByPriorities {
	my ($scripts) = @_;
	my %output;
	while(my ($key, $value) = each %$scripts) {
		$output{$value->{priority}} = {
			'exec' => $value->{exec},
			'name' => $key
		};
	}
	return %output;
}

sub launch {
	my ($c) = @_;
	my $container = Virt::LXC->new($c->{parameters}{name});
	my %startupScripts = getScriptsByPriorities($c->{setup});
	if ($container->isExisting) {
			$container->destroy;
	}
	$container->setTemplate($c->{parameters}{template});
	my ($state, $stdout, $stderr) = $container->deploy;
	die $stderr unless $state;
	for(sort keys %startupScripts) {
		say `$startupScripts{$_}->{exec} --container $c->{parameters}{name}`;
	}
	$container->stop if $container->isRunning;
	$container->start;
	for (values %{$c->{applications}}) {
		launch ($_);
	}
}

sub initHost {
	my $yaml = YAML::Tiny->new(%$runList);
	$yaml->write('/var/lib/floday/runlist.yml');
	my ($host) = @_;
	for (values %{$host->{applications}}) {
		launch($_);
	}
}

initHost($runList->{hosts}{integration});

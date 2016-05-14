#!/usr/bin/env perl

use v5.20;
use strict;

use lib '/opt/floday/src/';

use Data::Dumper;
use Virt::LXC;
use YAML::Tiny;

$Data::Dumper::Indent = 1;

my $runList = {
	'hosts' => {
		'spyzone' => {
			'parameters' => {
				'type' => 'riuk',
				'name' => 'spyzone',
			},
			'applications' => {
				web => {
					'parameters' => {
						'type' => 'riuk-http',
						'name' => 'spyzone-web',
						'bridge' => 'lxcbr0',
						'iface' => 'eth0',
						'ipv4' => '10.0.3.5',
						'gateway' => '10.0.3.1',
						'netmask' => '255.255.255.0',
						'template' => 'alpine'
					},
					'setup' => {
						'network' => {
							'exec' => '/opt/floday/containers/riuk/children/core/setup/network.pl',
							'priority' => 10
						},
						'lighttpd' => {
							'exec' => '/opt/floday/containers/riuk/children/web/setup/network.pl',
							'priority' => 20
						}
					},
					'applications' => {
						'test' => {
							'parameters' => {
								'type' => 'riuk-http-php',
								'name' => 'spyzone-web-test',
								'data' => 'floday.d/riuk-web-test/php/',
								'bridge' => 'lxcbr0',
								'iface' => 'yallah!',
								'ipv4' => '10.0.3.6',
								'gateway' => '10.0.3.1',
								'netmask' => '255.255.255.0',
								'template' => 'alpine'
							},
							'setup' => {
								'network' => {
									'exec' => '/opt/floday/containers/riuk/children/core/setup/network.pl',
									'priority' => 10
								},
								'php' => {
									'exec' => '/opt/floday/containers/riuk/children/core/setup/network.pl',
									'priority' => 20
								},
								'data' => {
									'exec' => '/opt/floday/containers/riuk/children/core/setup/data_receiver.pl',
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
	my ($app) = @_;
	for(my ($c) = values %$app) {
		my $container = Virt::LXC->new($c->{parameters}{name});
		my %startupScripts = getScriptsByPriorities($c->{setup});
		if ($container->isExisting) {
			say "Destroying $c->{parameters}{name} container.";
			#$container->destroy;
		}
		$container->setTemplate($c->{parameters}{template});
		say "Creation of the $c->{parameters}{name} container.";
		#my ($state, $stdout, $stderr) = $container->deploy;
		#say "Container created" if $state;
		#die $stderr unless $state;
		for(sort keys %startupScripts) {
			`$startupScripts{$_}->{exec} --container $c->{parameters}{name}`;
		}
		foreach($c->{applications}) {
			launch $_;
		}
	}
}

sub initHost {
	my $yaml = YAML::Tiny->new(%$runList);
	$yaml->write('/usr/lib/floday/runlist.yml');
	my ($host) = @_;
	for ($host->{applications}) {
		say Dumper $_;
		launch $_;
	}
}

initHost($runList->{hosts}{spyzone});

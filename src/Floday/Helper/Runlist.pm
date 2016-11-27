package Floday::Helper::Runlist;

use v5.20;

use Floday::Helper::Host;

use Data::Dumper;
use Log::Any;
use Moo;
use YAML::Tiny;

has log => (
	is => 'ro',
	default => sub {
		Log::Any->get_logger;
	}
);

has runfile => (
	is => 'ro',
	isa => sub {
		die 'runfile is not readable' unless -r $_[0];
	},
	reader => 'getRunFile',
	required => 1,
);

has rawRunlist => (
	is => 'rw',
	lazy => 1,
	builder => '_initializeRunlist',
	reader => 'getRawRunlist'
);

has cleanRunlist => (
	is => 'rw',
	lazy => 1,
	builder => '_cleanRunlist',
	reader => 'getCleanRunlist'
);

#{{{Runlist
my $runlist = {
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
						'type' => 'riuk-web',
						'name' => 'integration-web',
						'bridge' => 'lxcbr0',
						'iface' => 'eth0',
						'ipv4' => '10.0.3.5',
						'gateway' => '10.0.3.1',
						'netmask' => '255.255.255.0',
						'template' => 'flodayalpine -- version 3.4'
					},
					'setups' => {
						'network' => {
							'exec' => '/opt/floday/containers/riuk/children/core/setups/network.pl',
							'priority' => 10
						},
						'lighttpd' => {
							'exec' => '/opt/floday/containers/riuk/children/web/setups/lighttpd.pl',
							'priority' => 20
						}
					},
					'applications' => {
						'test' => {
							'parameters' => {
								'type' => 'riuk-web-php',
								'name' => 'integration-web-test',
								'data_in' => 'floday.d/integration-web-test/php',
								'data_out' => '/var/www',
								'bridge' => 'lxcbr0',
								'iface' => 'eth0',
								'ipv4' => '10.0.3.6',
								'gateway' => '10.0.3.1',
								'netmask' => '255.255.255.0',
								'template' => 'flodayalpine -- version 3.4',
								'hostname' => 'test.keh.keh'
							},
							'setups' => {
								'network' => {
									'exec' => '/opt/floday/containers/riuk/children/core/setups/network.pl',
									'priority' => 10
								},
								'php' => {
									'exec' => '/opt/floday/containers/riuk/children/web/children/php/setups/php.pl',
									'priority' => 20
								},
								'data' => {
									'exec' => '/opt/floday/containers/riuk/children/core/setups/data.pl',
									'priority' => 30
								}
							}
						},
						'secondtest' => {
							'parameters' => {
								'type' => 'riuk-web-php',
								'name' => 'integration-web-secondtest',
								'data_in' => 'floday.d/integration-web-secondtest/php',
								'data_out' => '/var/www',
								'bridge' => 'lxcbr0',
								'iface' => 'eth0',
								'ipv4' => '10.0.3.7',
								'gateway' => '10.0.3.1',
								'netmask' => '255.255.255.0',
								'template' => 'flodayalpine -- version 3.4',
								'hostname' => 'test2.keh.keh'
							},
							'setups' => {
								'network' => {
									'exec' => '/opt/floday/containers/riuk/children/core/setups/network.pl',
									'priority' => 10
								},
								'php' => {
									'exec' => '/opt/floday/containers/riuk/children/web/children/php/setups/php.pl',
									'priority' => 20
								},
								'data' => {
									'exec' => '/opt/floday/containers/riuk/children/core/setups/data.pl',
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

sub getApplicationsOf {
	my ($this, $applicationName) = @_;
	my $definition = $this->getDefinitionOf($applicationName);
	sort map{$_ = $applicationName . '-' . $_; $_} keys %{$definition->{applications}};
}

sub getDefinitionOf {
	my ($this, $applicationName) = @_;
	$this->log->debugf('Asking definition of: %s', $applicationName);
	my @containerPath = split /-/, $applicationName;
	my $definition->{'applications'} = $this->getRunlist()->{'hosts'};
	for (@containerPath) {
		$definition = $definition->{'applications'}{$_};
	}
	return $definition;
}

sub getRunlist {
	my ($this) = @_;
	my $rn = $this->getCleanRunlist();
	return $rn;
}

sub getParametersForApplication {
	my ($this, $applicationName) = @_;
	%{$this->getDefinitionOf($applicationName)->{parameters}};
}

sub getSetupsByPriorityForApplication {
	my ($this, $applicationName) = @_;
	my %setups = %{$this->getDefinitionOf($applicationName)->{setups}};
	my %sortedScripts;
	while (my($key, $value) = each %setups) {
		$sortedScripts{$value->{priority}} = {
		  'exec' => $value->{exec},
		  'name' => $key
	  };
  }
  return %sortedScripts;
}

#TODO: refactor this.
sub _cleanRunlist {
	my ($this, $rawData) = @_;
	my $first = 0;
	if (not defined $rawData) {
		$rawData = $this->getRawRunlist()->{'hosts'};
		$first = 1;
	}
	my $cleanRunlist;
	foreach $a (keys %$rawData) {
		foreach (keys %{$rawData->{$a}{'parameters'}}) {
			if (defined $rawData->{$a}{'parameters'}{$_}{'value'}) {
				$cleanRunlist->{$a}{'parameters'}{$_} = $rawData->{$a}{'parameters'}{$_}{'value'};
			}
		}
		if (defined $rawData->{$a}{'setups'}) {
			$cleanRunlist->{$a}{'setups'} = $rawData->{$a}{'setups'};
		}
		if (defined $rawData->{$a}{'applications'}) {
			$cleanRunlist->{$a}{'applications'} = $this->_cleanRunlist($rawData->{$a}{'applications'});
		}
		if ($first == 1) {
			return {'hosts' => $cleanRunlist};
		}
	}
	return $cleanRunlist;
}

sub _initializeRunlist {
	my ($this) = @_;
	my $hosts = YAML::Tiny->read($this->getRunFile())->[0]{hosts};
	my $hostsInitialized;
	for (keys %$hosts) {
		my $attributes = $hosts->{$_};
		$attributes->{parameters}{name} = $_;
		$hostsInitialized->{'hosts'}{$_} = Floday::Helper::Host->new('runfile' => $attributes)->toHash();
	}
	return $hostsInitialized;
}

1

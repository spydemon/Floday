package Floday::Helper::Host;

use v5.20;

use Config::Tiny;
use Moo;
use YAML::Tiny;

has attributesFromRunfile => (
  is => 'ro',
  isa => sub {
     no warnings 'uninitialized';
     my $hostName = $_[0]->{parameters}{name};
     my $hostType = $_[0]->{parameters}{type};
     die "Invalid name '$hostName' for host initialization" if $hostName !~ /^\w+$/;
     die "Invalid type '$hostType' for host initialization" if $hostType !~ /^\w+$/;
  },
  reader => 'getAttributesFromRunfile'
);

has flodayConfigFile => (
  builder => sub {
    my $cfg = Config::Tiny->read('/etc/floday/floday.cfg');
    die ("Unable to load Floday configuration file ($Config::Tiny::errstr)") unless defined $cfg;
	return $cfg;
  },
  is => 'ro',
  reader => '_getFlodayConfigFile'
);

sub toHash {
	my ($this) = @_;
	#TODO: manage recursivity:
	my $containerConfig = $this->_getContainerConfig($this->getAttributesFromRunfile()->{parameters}{name});
	#TODO: check integrity.
	#TODO: clean parameters format.
	return $containerConfig;
}

sub _getContainerConfig {
	my ($this, $containerNamePath, $configuration) = @_;
	my $containerDefinitionPath = _getContainerConfigFilePath();
	my $plainConfig = YAML::Tiny->read($containerDefinitionPath);
	$this->_mergeConfig($containerNamePath, $plainConfig->[0]);
}

sub _getContainerConfigFilePath {
	my ($this, $containerNamePath) = @_;
	#TODO: manage real implementation.
	#join('/', $this->_getFlodayConfig('path'), $containerNamePath, 'config.yml');
	return '/etc/floday/containers/riuk/config.yml';
}

sub _getFlodayConfig {
	my ($this, $key) = @_;
	die ("Undefined key") unless defined $key;
	my $value = $this->_getFlodayConfigFile()->{containers}{$key};
	die ("Undefined '$key' key in Floday configuration container section") unless defined $value;
	return $value;
}

sub _mergeConfig {
	my ($this, $containerNamePath, $containerConfig) = @_;
	my $attributesFromRunfile;
	$attributesFromRunfile->{$this->getAttributesFromRunfile()->{parameters}{name}} = $this->getAttributesFromRunfile();
	for (split '-', $containerNamePath . '-') {
		$attributesFromRunfile = $attributesFromRunfile->{$_}{parameters};
	}
	$containerConfig->{parameters}{name}{value} = undef;
	$containerConfig->{parameters}{type}{value} = undef;
	for (keys %$attributesFromRunfile) {
		die ("Parameter '$_' present in runfile but that doesn't exist in container definition") unless defined $containerConfig->{parameters}{$_};
		$containerConfig->{parameters}{$_}{value} = $attributesFromRunfile->{$_};
	}
	return $containerConfig;
}
1
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

has containerNamePathToManage => (
  default => sub {
    my ($this) = @_;
    $this->getAttributesFromRunfile()->{parameters}{name};
  },
  is => 'ro',
  isa => sub {
    die if $_[0] !~ /^[\w-]+$/;
  },
  reader => '_getContainerNamePathToManage'
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
	my $containerNamePath = $this->_getContainerNamePathToManage();
	my $containerConfig = $this->_getContainerDefinition($containerNamePath);
	my $containerAttributeFromRunfile = $this->_getInstanceToManageRunfileConfiguration();
	if (defined $containerAttributeFromRunfile->{applications}) {
		for (keys %{$containerAttributeFromRunfile->{applications}}) {
			$containerAttributeFromRunfile->{applications}{$_}{parameters}{name} =  $_;
			$containerConfig->{applications}{$_} =
			  Floday::Helper::Host->new(
			    'attributesFromRunfile' => $this->getAttributesFromRunfile,
			    'containerNamePathToManage' => $this->_getContainerNamePathToManage() . '-' . $_
			  )->toHash()
			;
		}
	}
	#TODO: check integrity.
	#TODO: clean parameters format.
	return $containerConfig;
}

sub _getContainerDefinition {
	my ($this, $containerNamePath) = @_;
	my $containerDefinitionPath = $this->_getContainerConfigFilePath($containerNamePath);
	my $plainConfig = YAML::Tiny->read($containerDefinitionPath);
	$this->_mergeConfig($plainConfig->[0]);
}

sub _getContainerConfigFilePath {
	my ($this, $containerNamePath) = @_;
	my @containersType = split '-', $this->_getContainerTypePath($containerNamePath);
	join('/',
	  $this->_getFlodayConfig('path'),
	  shift @containersType,
	  (map {'children/' . $_} @containersType),
	  'config.yml'
	);
}

sub _getInstanceToManageRunfileConfiguration {
	my ($this) = @_;
	my $attributesFromRunfile;
	$attributesFromRunfile->{applications}{$this->getAttributesFromRunfile->{parameters}{name}} = $this->getAttributesFromRunfile();
	for (split '-', $this->_getContainerNamePathToManage()) {
		$attributesFromRunfile = $attributesFromRunfile->{applications}{$_};
	}
	return $attributesFromRunfile;
}

sub _getContainerTypePath {
	my ($this, $containerNamePath) = @_;
	my @containerTypePath;
	my $runfileConfig;
	$runfileConfig->{applications}{$this->getAttributesFromRunfile()->{parameters}{name}} = $this->getAttributesFromRunfile();
	for (split ('-', $containerNamePath)) {
		$runfileConfig = $runfileConfig->{applications}{$_};
		push @containerTypePath, $runfileConfig->{parameters}{type};
	}
	join '-', @containerTypePath;
}

sub _getFlodayConfig {
	my ($this, $key) = @_;
	die ("Undefined key") unless defined $key;
	my $value = $this->_getFlodayConfigFile()->{containers}{$key};
	die ("Undefined '$key' key in Floday configuration container section") unless defined $value;
	return $value;
}

sub _mergeConfig {
	my ($this, $containerConfig) = @_;
	my $runfileConfig = $this->_getInstanceToManageRunfileConfiguration();
	$runfileConfig = $runfileConfig->{'parameters'};
	$containerConfig->{parameters}{name}{value} = undef;
	$containerConfig->{parameters}{type}{value} = undef;
	for (keys %$runfileConfig) {
		die ("Parameter '$_' present in runfile but that doesn't exist in container definition") unless defined $containerConfig->{parameters}{$_};
		$containerConfig->{parameters}{$_}{value} = $runfileConfig->{$_};
	}
	return $containerConfig;
}

1
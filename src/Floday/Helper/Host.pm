package Floday::Helper::Host;

use v5.20;

use Config::Tiny;
use Moo;
use YAML::Tiny;

has runfile => (
  is => 'ro',
  isa => sub {
     no warnings 'uninitialized';
     my $hostName = $_[0]->{parameters}{name};
     my $hostType = $_[0]->{parameters}{type};
     die "Invalid name '$hostName' for host initialization" if $hostName !~ /^\w+$/;
     die "Invalid type '$hostType' for host initialization" if $hostType !~ /^\w+$/;
  },
  reader => '_getAttributesFromRunfile'
);

has instancePathToManage => (
  default => sub {
    my ($this) = @_;
    $this->_getAttributesFromRunfile()->{parameters}{name};
  },
  is => 'ro',
  isa => sub {
    die if $_[0] !~ /^[\w-]+$/;
  },
  lazy => 1, #The lazyness is a trick for ensuring us that this attribute is load after "runfile" one.
  reader => '_getInstancePathToManage'
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
	my $runlist = $this->_getInstanceDefinition();
	my $currentInstanceAttributesFromRunfile = $this->_getInstanceToManageRunfileAttributes();
	if (defined $currentInstanceAttributesFromRunfile->{applications}) {
		for (keys %{$currentInstanceAttributesFromRunfile->{applications}}) {
			$currentInstanceAttributesFromRunfile->{applications}{$_}{parameters}{name} =  $_;
			$runlist->{applications}{$_} =
			  Floday::Helper::Host->new(
			    'runfile' => $this->_getAttributesFromRunfile,
			    'instancePathToManage' => $this->_getInstancePathToManage() . '-' . $_
			  )->toHash()
			;
		}
	}
	#TODO: manage inheritance.
	#TODO: check integrity.
	#TODO: clean parameters format.
	return $runlist;
}

sub _getInstanceDefinition {
	my ($this) = @_;
	my $containerDefinition = YAML::Tiny->read(
	  $this->_getContainerDefinitionFilePath()
	);
	#Create instance definition.
	$this->_mergeDefinition($containerDefinition->[0]);
}

sub _getContainerDefinitionFilePath {
	my ($this) = @_;
	my @containersType = split '-', $this->_getContainerPath();
	join('/',
	  $this->_getFlodayConfig('path'),
	  shift @containersType,
	  (map {'children/' . $_} @containersType),
	  'config.yml'
	);
}

sub _getInstanceToManageRunfileAttributes {
	my ($this) = @_;
	my $attributesFromRunfile->{applications}{$this->_getAttributesFromRunfile->{parameters}{name}} = $this->_getAttributesFromRunfile();
	for (split '-', $this->_getInstancePathToManage()) {
		$attributesFromRunfile = $attributesFromRunfile->{applications}{$_};
	}
	return $attributesFromRunfile;
}

sub _getContainerPath {
	my ($this) = @_;
	my @containerTypePath;
	my $runfileConfig->{applications}{$this->_getAttributesFromRunfile()->{parameters}{name}} = $this->_getAttributesFromRunfile();
	for (split ('-', $this->_getInstancePathToManage())) {
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

sub _mergeDefinition {
	my ($this, $containerDefinition) = @_;
	my $runfileAttributes = $this->_getInstanceToManageRunfileAttributes();
	$runfileAttributes = $runfileAttributes->{'parameters'};
	$containerDefinition->{parameters}{name}{value} = undef;
	$containerDefinition->{parameters}{type}{value} = undef;
	for (keys %$runfileAttributes) {
		die ("Parameter '$_' present in runfile but that doesn't exist in container definition") unless defined $containerDefinition->{parameters}{$_};
		$containerDefinition->{parameters}{$_}{value} = $runfileAttributes->{$_};
	}
	return $containerDefinition;
}

1
package Floday::Helper::Host;

use v5.20;

use Floday::Helper::Container;
use Hash::Merge;
use Moo;

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
	#TODO: check integrity.
	#TODO: clean parameters format.
	return $runlist;
}

sub _getInstanceDefinition {
	my ($this) = @_;
	my $containerDefinition = Floday::Helper::Container->new()->getContainerDefinition($this->_getContainerPath());
	#Create instance definition.
	$this->_mergeDefinition($containerDefinition);
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
	$containerDefinition->{parameters}{instance_path}{value} = $this->_getInstancePathToManage();
	$containerDefinition->{parameters}{container_path}{value} = $this->_getContainerPath();
	return $containerDefinition;
}

1
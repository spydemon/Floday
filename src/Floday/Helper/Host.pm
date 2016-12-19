package Floday::Helper::Host;

use v5.20;

use Floday::Helper::Container;
use Hash::Merge;
use Moo;
use Data::Dumper;

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

state @errors;

sub generateRunlist {
	my ($this) = @_;
	my $runlist = $this->toHash();
	if (@errors > 0) {
		die(map{$_ . "\n"} @errors);
	}
	say Dumper @errors;
	return $runlist;
}

sub getAllErrors {
	@errors;
}

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
	push @errors, $this->_checkRunlistIntegrity($runlist);
	return $runlist;
}

sub _checkRunlistIntegrity {
	my ($this, $runlist) = @_;
	my @_errors;
	for my $currParam (keys %{$runlist->{parameters}}) {
		my $paramsAttributes = $runlist->{parameters}->{$currParam};
		#TODO: boolean are not managed with YAML::Tiny! It could be nice to user real Yaml boolean instead of a string equals to "true".
		if (defined $paramsAttributes->{mandatory}
		  and $paramsAttributes->{mandatory} eq 'true'
		  and not (defined $paramsAttributes->{value})
		) {
			push @_errors, "The '$currParam' mandatory parameter is missing in '$runlist->{parameters}{instance_path}{value}' application.";
		}
		if (defined $paramsAttributes->{pattern}
		  and defined $paramsAttributes->{value}
		  and $paramsAttributes->{value} !~ qr/$paramsAttributes->{pattern}/
		) {
			push @_errors, "'$currParam' parameter in '$runlist->{parameters}{instance_path}{value}' has value '$paramsAttributes->{value}' that doesn't respect the '$paramsAttributes->{pattern}' regex.";
		}
	}
	return @_errors;
}

sub _getInstanceDefinition {
	my ($this) = @_;
	my $containerDefinition = Floday::Helper::Container->new()->getContainerDefinition($this->_getContainerPath());
	$this->_mergeDefinition($containerDefinition);
}

sub _getInstanceToManageRunfileAttributes {
	my $attributesFromRunfile;
	eval {
		use warnings FATAL => 'uninitialized';
		my ($this) = @_;
		$attributesFromRunfile->{applications}{$this->_getAttributesFromRunfile->{parameters}{name}} = $this->_getAttributesFromRunfile();
		for (split '-', $this->_getInstancePathToManage()) {
			$attributesFromRunfile = $attributesFromRunfile->{applications}{$_};
		}
	};
	die ("Missing name or type for an application") if $@ ne '';
	return $attributesFromRunfile;
}

sub _getContainerPath {
	my $containerPath;
	eval {
		use warnings FATAL => 'uninitialized';
		my ($this) = @_;
		my @containerTypePath;
		my $runfileConfig->{applications}{$this->_getAttributesFromRunfile()->{parameters}{name}} = $this->_getAttributesFromRunfile();
		for (split ('-', $this->_getInstancePathToManage())) {
			$runfileConfig = $runfileConfig->{applications}{$_};
			push @containerTypePath, $runfileConfig->{parameters}{type};
		}
		$containerPath = join '-', @containerTypePath;
	};
	die ("Missing name or type for an application") if $@ ne '';
	return $containerPath;
}

sub _mergeDefinition {
	my ($this, $containerDefinition) = @_;
	my $runfileAttributes = $this->_getInstanceToManageRunfileAttributes();
	$runfileAttributes = $runfileAttributes->{'parameters'};
	$containerDefinition->{parameters}{name}{value} = undef;
	$containerDefinition->{parameters}{name}{required} = 'true';
	$containerDefinition->{parameters}{type}{value} = undef;
	$containerDefinition->{parameters}{type}{required} = 'true';
	for (keys %$runfileAttributes) {
		die ("Parameter '$_' present in runfile but that doesn't exist in container definition") unless defined $containerDefinition->{parameters}{$_};
		$containerDefinition->{parameters}{$_}{value} = $runfileAttributes->{$_};
	}
	$containerDefinition->{parameters}{instance_path}{value} = $this->_getInstancePathToManage();
	$containerDefinition->{parameters}{container_path}{value} = $this->_getContainerPath();
	return $containerDefinition;
}

1
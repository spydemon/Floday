package Floday::Setup;
use lib '/opt/floday/src/';
use v5.20;
use Moo;
use YAML::Tiny;
use Virt::LXC;

has containerName => (
	'is' => 'ro',
	'required' => 1,
	'reader' => 'getContainerName',
	'writter' => '_setContainerName',
	#TODO: disallow also -- in isa instruction.
	'isa' => sub {die unless $_[0] =~ /^\w[\w-]*\w$/},
);

has lxcInstance => (
	'is' => 'ro',
	'reader' => 'getLxcInstance',
	'default' => sub { Virt::LXC->new('utsname' => $_[0]->getContainerName) },
	'lazy' => 1
);

has runlistPath => (
	'is' => 'ro',
	'default' => '/var/lib/floday/runlist.yml',
	'reader' => 'getRunlistPath'
);

has log => (
	'is' => 'ro',
	'default' => sub { Log::Any->get_logger }
);

sub getDefinition {
	my ($this) = @_;
	return $this->{definition} //= $this->_fetchDefinition;
}

sub getParentContainer {
	my ($this) = @_;
	$this->{parent} //= $this->_fetchParentContainer;
}

sub getRunlist {
	my ($this) = @_;
	return $this->{runlist} //= $this->_fetchRunlist;
}

sub getParameter {
	#TODO: test parameter validity.
	my ($this, $parameter) = @_;
	my $value = $this->getDefinition->{parameters}{$parameter};
	if (!defined $value) {
		$this->log->warningf('%s: get undefined %s parameter', $this->getContainerName, $parameter);
	} else {
		$this->log->debugf('%s: get parameter %s with value: %s', $this->getContainerName, $parameter, $value);
	}
	return $value;
}

sub _fetchDefinition {
	my ($this) = @_;
	$this->log->infof('%s: fetching container definition', $this->getContainerName);
	my ($h, $a) = $this->getContainerName =~ /(.*?)-(.*)/;
	my $runlist = $this->getRunlist;
	my $definition = $runlist->[1]->{$h};
	for (split /-/, $a) {
		$definition = $definition->{applications}->{$_};
	}
	return $definition;
}

sub _fetchRunlist {
	my ($this) = @_;
	YAML::Tiny->read($this->getRunlistPath);
}

sub _fetchParentContainer {
	my ($this) = @_;
	my ($parentName) = $this->getContainerName =~ /^(.*)-.*$/;
	if (defined $parentName) {
		return Floday::Setup->new(containerName => $parentName);
	}
}

1;

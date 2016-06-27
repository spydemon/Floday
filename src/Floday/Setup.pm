package Floday::Setup;
use v5.20;
use Moo;
use Log::Any;
use YAML::Tiny;

has name => (
	'is' => 'ro',
	'required' => 1,
	'reader' => 'getName',
	'writter' => '_setName',
	#TODO: disallow also -- in isa instruction.
	'isa' => sub {die unless $_[0] =~ /^\w[\w-]*\w$/},
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
	return $this->{definition} // $this->_fetchDefinition;
}

sub getParameter {
	#TODO: test parameter validity.
	my ($this, $parameter) = @_;
	my $value = $this->getDefinition->{parameters}{$parameter};
	#TODO: undef is not working well right now.
	if (defined $value) {
		$this->log->warningf('%s: get undefined $parameter parameter', $this->getName, $parameter);
	} else {
		$this->log->debugf('%s: get parameter %s with value: %s', $this->getName, $parameter, $value);
	}
	return $value;
}

sub getParentDefinition {
	my ($this) = @_;
	return $this->{parentRunlist} // $this->_fetchRunlist;
}

sub getRunlist {
	my ($this) = @_;
	return $this->{runlist} //= $this->_fetchRunlist;
}

sub _fetchDefinition {
	my ($this) = @_;
	$this->log->infof('%s: fetching definition');
	my ($h, $a) = $this->getName =~ /(.*?)-(.*)/;
	my $runlist = $this->getRunlist;
	my $definition = $runlist->[1]->{$h};
	for (split /-/, $a) {
		$this->{parentDefinition} = $definition if defined $definition;
		$definition = $definition->{applications}->{$_};
	}
	$this->{definition} = $definition;
	return $definition;
}

sub _fetchRunlist {
	my ($this) = @_;
	my $runlist = YAML::Tiny->read($this->getRunlistPath);
	return $runlist;
}

1;

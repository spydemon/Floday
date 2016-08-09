package Floday::Setup;

use lib '/opt/floday/src/';
use v5.20;

use Carp;
use Data::Dumper;
use File::Temp;
use Floday::Helper::Runlist;
use Moo;
use Template::Alloy;
use Virt::LXC;
use YAML::Tiny;

#TODO: we should use the "application" name instead of "container".

has containerName => (
	'is' => 'ro',
	'required' => 1,
	'reader' => 'getContainerName',
	'writter' => '_setContainerName',
	'isa' => sub {die unless $_[0] =~ /^(?:\w-?)+\w$/}
);

has lxcInstance => (
	'is' => 'ro',
	'reader' => 'getLxcInstance',
	'default' => sub { Virt::LXC->new('utsname' => $_[0]->getContainerName) },
	'lazy' => 1
);

has runfilePath => (
	#default => '/etc/floday/runfile.yml',
	default => '/opt/floday/t/integration/floday.d/runfile.yml',
	is => 'ro',
	reader => 'getRunfilePath'
);

has parent => (
	builder => '_fetchParentContainer',
	is => 'ro',
	lazy => 1,
	reader => 'getParentContainer'
);

has runlist => (
	is => 'rw',
	reader => 'getRunlist',
	builder => '_initializeRunlist',
	lazy => 1
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
	$this->getRunlist->getDefinitionOf($this->getContainerName);
}

sub getParameter {
	#TODO: undefined value non fatal.
	my ($this, $parameter) = @_;
	croak 'Parameter "' . $parameter . '" asked has an invalid name' if $parameter !~ /^\w{1,}$/;
	my %parameters = $this->getParameters;
	my $value = $parameters{$parameter};
	if (!defined $value) {
		$this->log->errorf('%s: get undefined %s parameter', $this->getContainerName, $parameter);
		croak 'undefined "' . $parameter . '" parameter asked for ' . $this->getContainerName . ' container.';
	} else {
		$this->log->debugf('%s: get parameter "%s" with value: "%s"', $this->getContainerName, $parameter, $value);
	}
	return $value;
}

sub getParameters {
	my ($this) = @_;
	$this->getRunlist->getParametersForApplication($this->getContainerName);
}

sub generateFile {
	my ($this, $template, $data, $location) = @_;
	$this->log->infof('%s: generate %s from %s', $this->getContainerName, $location, $template);
	my $i = File::Temp->new();
	my $t = Template::Alloy->new(
		ABSOLUTE => 1,
	);
	$t->process($template, $data, $i) or die $t->error;
	$this->getLxcInstance->put($i, $location);
}

sub _fetchParentContainer {
	my ($this) = @_;
	$this->log->debugf('%s: asking parent application', $this->getContainerName);
	my ($parentName) = $this->getContainerName =~ /^(.*)-.*$/;
	if (defined $parentName) {
		return Floday::Setup->new(containerName => $parentName, runfilePath => $this->getRunfilePath);
	} else {
		croak "This container doesn't have parent.";
	}
}

sub _initializeRunlist {
	my ($this) = @_;
	$this->log->infof("Runfile %s", $this->getRunfilePath);
	Floday::Helper::Runlist->new(runfile => $this->getRunfilePath);
}

1;

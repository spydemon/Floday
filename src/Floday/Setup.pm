package Floday::Setup;

use lib '/opt/floday/src/';
use v5.20;

use Backticks;
use Carp;
use Exporter qw(import);
use Floday::Helper::Runlist;
use Moo;
use Template::Alloy;
use Virt::LXC;

use constant ALLOW_UNDEF => 1;

$Backticks::autodie = 1;

our @EXPORT_OK = ('ALLOW_UNDEF');

#TODO: rename to instancePath.
has applicationName => (
	'is' => 'ro',
	'required' => 1,
	'reader' => 'getApplicationName',
	'writter' => '_setApplicationName',
	'isa' => sub {die unless $_[0] =~ /
	  ^         #start of the line
	  (?:\w-?)+ #should contain at least one letter and no double dash
	  \w$       #should finish with a letter
	  /x
	}
);

has lxcInstance => (
	'is' => 'ro',
	'reader' => 'getLxcInstance',
	'default' => sub { Virt::LXC->new('utsname' => $_[0]->getApplicationName) },
	'lazy' => 1
);

has runfilePath => (
	#default => '/etc/floday/runfile.yml',
	default => '/opt/floday/t/integration/floday.d/runfile.yml',
	is => 'ro',
	reader => 'getRunfilePath'
);

has parent => (
	builder => '_fetchParentApplication',
	is => 'ro',
	lazy => 1,
	reader => 'getParentApplication'
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
	$this->getRunlist->getDefinitionOf($this->getApplicationName);
}

sub getParameter {
	#TODO: use Perl subrouting signature feature instead of doing this shit.
	push (@_, 0) if (@_ == 2);
	my ($this, $parameter, $flags) = @_;
	croak 'Parameter "' . $parameter . '" asked has an invalid name' if $parameter !~ /^\w{1,}$/;
	my %parameters = $this->getParameters;
	my $value = $parameters{$parameter};
	if (!defined $value && $flags != ALLOW_UNDEF) {
		$this->log->errorf('%s: get undefined %s parameter', $this->getApplicationName, $parameter);
		croak 'undefined "' . $parameter . '" parameter asked for ' . $this->getApplicationName . ' application.';
	} else {
		$this->log->debugf('%s: get parameter "%s" with value: "%s"', $this->getApplicationName, $parameter, $value);
	}
	return $value;
}

sub getParameters {
	my ($this) = @_;
	$this->getRunlist->getParametersForApplication($this->getApplicationName);
}

sub generateFile {
	my ($this, $template, $data, $location) = @_;
	$this->log->infof('%s: generate %s from %s', $this->getApplicationName, $location, $template);
	my $i = File::Temp->new();
	my $t = Template::Alloy->new(
		ABSOLUTE => 1,
	);
	$t->process($template, $data, $i) or die $t->error;
	$this->getLxcInstance->put($i, $location);
}

sub _fetchParentApplication {
	my ($this) = @_;
	$this->log->debugf('%s: asking parent application', $this->getApplicationName);
	my ($parentName) = $this->getApplicationName =~ /^(.*)-.*$/;
	if (defined $parentName) {
		return Floday::Setup->new(applicationName => $parentName, runfilePath => $this->getRunfilePath);
	} else {
		croak "This application doesn't have parent.";
	}
}

sub _initializeRunlist {
	my ($this) = @_;
	$this->log->infof("Runfile %s", $this->getRunfilePath);
	Floday::Helper::Runlist->new(runfile => $this->getRunfilePath);
}

1;

package Floday::Setup;

use lib '/opt/floday/src/';
use v5.20;

use Backticks;
use Carp;
use Exporter qw(import);
use File::Temp;
use Floday::Helper::Config;
use Floday::Helper::Runlist;
use Getopt::Long;
use Log::Any::Adapter('+Floday::Helper::Logging');
use Moo;
use Template::Alloy;
use Virt::LXC;
use YAML::Tiny;

our ($APP);

use constant ALLOW_UNDEF => 1;

$Backticks::autodie = 1;

our @EXPORT = qw($APP);
our @EXPORT_OK = qw(ALLOW_UNDEF);

has instancePath => (
	'is' => 'ro',
	'required' => 1,
	'reader' => 'getInstancePath',
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
	'default' => sub { Virt::LXC->new('utsname' => $_[0]->getInstancePath) },
	'lazy' => 1
);

#TODO: runfile should be used here. Only runlist is needed.
has runfilePath => (
	default => sub {
		Floday::Helper::Config->new()->getFlodayConfig('floday', 'runfile')
	},
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
	$this->getRunlist->getDefinitionOf($this->getInstancePath);
}

sub getParameter {
	#TODO: use Perl subrouting signature feature instead of doing this shit.
	push (@_, 0) if (@_ == 2);
	my ($this, $parameter, $flags) = @_;
	croak 'Parameter "' . $parameter . '" asked has an invalid name' if $parameter !~ /^\w{1,}$/;
	my %parameters = $this->getParameters;
	my $value = $parameters{$parameter};
	if (!defined $value && $flags != ALLOW_UNDEF) {
		$this->log->errorf('%s: get undefined %s parameter', $this->getInstancePath, $parameter);
		croak 'undefined "' . $parameter . '" parameter asked for ' . $this->getInstancePath. ' application.';
	} else {
		$this->log->debugf('%s: get parameter "%s" with value: "%s"', $this->getInstancePath, $parameter, $value);
	}
	return $value;
}

sub getParameters {
	my ($this) = @_;
	$this->getRunlist->getParametersForApplication($this->getInstancePath);
}

sub generateFile {
	my ($this, $template, $data, $location) = @_;
	$this->log->infof('%s: generate %s from %s', $this->getInstancePath, $location, $template);
	my $i = File::Temp->new();
	my $t = Template::Alloy->new(
		ABSOLUTE => 1,
	);
	$t->process($template, $data, $i) or die $t->error;
	$this->getLxcInstance->put($i, $location);
}

sub _fetchParentApplication {
	my ($this) = @_;
	$this->log->debugf('%s: asking parent application', $this->getInstancePath);
	my ($parentPath) = $this->getInstancePath =~ /^(.*)-.*$/;
	if (defined $parentPath) {
		return Floday::Setup->new(instancePath => $parentPath, runfilePath => $this->getRunfilePath);
	} else {
		croak "This application doesn't have parent.";
	}
}

sub _initializeRunlist {
	my ($this) = @_;
	$this->log->infof("Runfile %s", $this->getRunfilePath);
	Floday::Helper::Runlist->new(runfile => $this->getRunfilePath);
}

#Auto creation of the module variables
my $container;
GetOptions('container=s', \$container);
croak('No container was provided during setup script instantiation.') if (not defined $container) or ($container eq '');
$APP = __PACKAGE__->new(instancePath => $container);

1;

package Floday::Setup;

use lib '/opt/floday/src/';
use v5.20;

use Backticks;
use Carp;
use Exporter qw(import);
use File::Temp;
use Floday::Helper::Config;
use Floday::Helper::Runlist;
use Floday::Lib::Linux::LXC;
use Getopt::Long;
use Log::Any::Adapter('+Floday::Helper::Logging');
use Moo;
use Template::Alloy;
use YAML::Tiny;

our ($APP);

use constant ALLOW_UNDEF => 1;

$Backticks::autodie = 1;

our @EXPORT = qw($APP);
our @EXPORT_OK = qw(ALLOW_UNDEF);

has config => (
	'is' => 'ro',
	'default' => sub {Floday::Helper::Config->new()},
	'reader' => 'get_config'
);

has instance_path => (
	'is' => 'ro',
	'required' => 1,
	'reader' => 'get_instance_path',
	'isa' => sub {die unless $_[0] =~ /
	  ^         #start of the line
	  (?:\w-?)+ #should contain at least one letter and no double dash
	  \w$       #should finish with a letter
	  /x
	}
);

has lxc_instance => (
	'is' => 'ro',
	'reader' => 'get_lxc_instance',
	'default' => sub { Floday::Lib::Linux::LXC->new('utsname' => $_[0]->get_instance_path) },
	'lazy' => 1
);

#TODO: runfile should be used here. Only runlist is needed.
has runfile_path => (
	default => sub {
		Floday::Helper::Config->new()->get_floday_config('floday', 'runfile')
	},
	is => 'ro',
	reader => 'get_runfile_path'
);

has parent => (
	builder => '_fetch_parent_application',
	is => 'ro',
	lazy => 1,
	reader => 'get_parent_application'
);

has runlist => (
	is => 'rw',
	reader => 'get_runlist',
	builder => '_initialize_runlist',
	lazy => 1
);

has runlist_path => (
	'is' => 'ro',
	'default' => '/var/lib/floday/runlist.yml',
	'reader' => 'get_runlist_path'
);

has log => (
	'is' => 'ro',
	'default' => sub { Log::Any->get_logger }
);

sub get_applications {
	my ($this, $instance_path) = @_;
	$instance_path //= $this->get_instance_path();
	my @applications;
	for (keys %{$this->get_runlist->get_definition_of($instance_path)->{applications}}) {
		push @applications, __PACKAGE__->new(instance_path => $instance_path . '-' . $_);
	}
	return @applications;
}

sub get_definition {
	my ($this) = @_;
	$this->get_runlist->get_definition_of($this->get_instance_path);
}

sub get_parameter {
	#TODO: use Perl subrouting signature feature instead of doing this shit.
	push (@_, 0) if (@_ == 2);
	my ($this, $parameter, $flags) = @_;
	croak 'Parameter "' . $parameter . '" asked has an invalid name' if $parameter !~ /^\w{1,}$/;
	my %parameters = $this->get_parameters;
	my $value = $parameters{$parameter};
	if (!defined $value && $flags != ALLOW_UNDEF) {
		$this->log->errorf('%s: get undefined %s parameter', $this->get_instance_path, $parameter);
		croak 'undefined "' . $parameter . '" parameter asked for ' . $this->get_instance_path. ' application.';
	} else {
		$this->log->debugf('%s: get parameter "%s" with value: "%s"', $this->get_instance_path, $parameter, $value);
	}
	return $value;
}

sub get_root_path() {
	my ($this) = @_;
	return '/var/lib/lxc/' . $this->get_instance_path . '/rootfs';
}

sub get_parameters {
	my ($this) = @_;
	$this->get_runlist->get_parameters_for_application($this->get_instance_path);
}

sub generate_file {
	my ($this, $template, $data, $location) = @_;
	$this->log->debugf('%s: generate %s from %s', $this->get_instance_path, $location, $template);
	$template = $this->get_config()->get_floday_config('containers', 'path') . '/' . $template;
	my $i = File::Temp->new();
	my $t = Template::Alloy->new(
		ABSOLUTE => 1,
	);
	$t->process($template, $data, $i) or die $t->error . "\n";
	say "Dafuq?";
	if ($this->get_lxc_instance()->is_existing()) {
		$this->get_lxc_instance->put($i, $location);
	} else {
		#lxc instance doesn't exist when the file should be put on the host.
		rename $i, $location;
	}
}

sub _fetch_parent_application {
	my ($this) = @_;
	$this->log->debugf('%s: asking parent application', $this->get_instance_path);
	my ($parent_path) = $this->get_instance_path =~ /^(.*)-.*$/;
	if (defined $parent_path) {
		return Floday::Setup->new(instance_path => $parent_path, runfile_path => $this->get_runfile_path);
	} else {
		return undef;
	}
}

sub _initialize_runlist {
	my ($this) = @_;
	Floday::Helper::Runlist->new(runfile => $this->get_runfile_path);
}

#Auto creation of the module variables
my $container;
GetOptions('container=s', \$container);
if (defined $container) {
	$APP = __PACKAGE__->new(instance_path => $container);
}

1;

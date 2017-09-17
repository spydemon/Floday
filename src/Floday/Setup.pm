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

has application_path => (
	'is' => 'ro',
	'required' => 1,
	'reader' => 'get_application_path',
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
	'default' => sub { Floday::Lib::Linux::LXC->new('utsname' => $_[0]->get_application_path) },
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

has manager => (
	builder => '_fetch_manager',
	is => 'ro',
	lazy => 1,
	reader => 'get_manager'
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

sub get_sub_applications {
	my ($this, $application_path) = @_;
	$application_path //= $this->get_application_path();
	my @applications;
	for (keys %{$this->get_runlist->get_definition_of($application_path)->{applications}}) {
		push @applications, __PACKAGE__->new(application_path => $application_path . '-' . $_);
	}
	return @applications;
}

sub get_definition {
	my ($this) = @_;
	$this->get_runlist->get_definition_of($this->get_application_path);
}

sub get_parameter {
	#TODO: use Perl subrouting signature feature instead of doing this shit.
	push (@_, 0) if (@_ == 2);
	my ($this, $parameter, $flags) = @_;
	croak 'Parameter "' . $parameter . '" asked has an invalid name' if $parameter !~ /^\w{1,}$/;
	my %parameters = $this->get_parameters;
	my $value = $parameters{$parameter};
	if (!defined $value && $flags != ALLOW_UNDEF) {
		$this->log->errorf('%s: get undefined %s parameter', $this->get_application_path, $parameter);
		croak 'undefined "' . $parameter . '" parameter asked for ' . $this->get_application_path. ' application.';
	} else {
		$this->log->debugf('%s: get parameter "%s" with value: "%s"', $this->get_application_path, $parameter, $value);
	}
	return $value;
}

sub get_root_folder() {
	my ($this) = @_;
	return '/var/lib/lxc/' . $this->get_application_path . '/rootfs';
}

sub get_parameters {
	my ($this) = @_;
	$this->get_runlist->get_parameters_for_application($this->get_application_path);
}

sub generate_file {
	my ($this, $template, $data, $location) = @_;
	$this->log->debugf('%s: generate %s from %s', $this->get_application_path, $location, $template);
	$template = $this->get_config()->get_floday_config('containers', 'path') . '/' . $template;
	my $i = File::Temp->new();
	my $t = Template::Alloy->new(
		ABSOLUTE => 1,
	);
	$t->process($template, $data, $i) or die $t->error . "\n";
	if ($this->get_lxc_instance()->is_existing()) {
		$this->get_lxc_instance->put($i, $location);
	} else {
		#lxc instance doesn't exist when the file should be put on the host.
		rename $i, $location;
	}
}

sub _fetch_manager {
	my ($this) = @_;
	$this->log->debugf('%s: asking manager application', $this->get_application_path);
	my ($manager_path) = $this->get_application_path =~ /^(.*)-.*$/;
	if (defined $manager_path) {
		return Floday::Setup->new(application_path => $manager_path, runfile_path => $this->get_runfile_path);
	} else {
		return undef;
	}
}

sub _initialize_runlist {
	my ($this) = @_;
	Floday::Helper::Runlist->new(runfile => $this->get_runfile_path);
}

#Auto creation of the module variables
my $application;
GetOptions('application=s', \$application);
if (defined $application) {
	$APP = __PACKAGE__->new(application_path => $application);
}

1;

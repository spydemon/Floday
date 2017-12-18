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
	'default' => sub {
	  die ('We can not invocate LXC container from host') if ($_[0]->is_host());
	  Floday::Lib::Linux::LXC->new('utsname' => $_[0]->get_application_path)
	},
	'lazy' => 1
);

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

has log => (
	'is' => 'ro',
	'default' => sub { Log::Any->get_logger }
);

sub BUILD {
	my ($this) = @_;
	if (!$this->get_runlist()->is_application_existing($this->get_application_path())) {
		die ('Floday "' . $this->get_application_path() . "\" application was not found in the runfile.\n");
	}
};

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
	if ($this->is_host()) {
		`mkdir -p \`dirname $location\``;
		rename $i, $location;
	} else {
		$this->get_lxc_instance->put($i, $location);
	}
}

sub is_host {
	my ($this) = @_;
	return 1 if $this->get_application_path() =~ /^[^-]*$/;
	return 0;
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

=head1 NAME

Floday::Setup - Manage a Floday application.

=head1 VERSION

1.1.0

=head1 SYNOPSYS

  #!/usr/bin/env perl

  use strict;
  use warnings;
  use v5.20;

  use Backticks;
  use Floday::Setup;

  $Backticks::autodie = 1;

  my $lxc = $APP->get_lxc_instance();
  $lxc->start() if $lxc->is_stopped();
  $lxc->exec('apk add lighttpd');
  $lxc->exec('rc-update add lighttpd');
  $lxc->exec('/etc/init.d/lighttpd start');

  $APP->generate_file(
    'jaxe/children/www/setups/lighttpd/lighttpd.conf',
    undef,
    '/etc/lighttpd/lighttpd.conf'
  );
  for ($APP->get_sub_applications()) {
    $APP->generate_file(
      $_->getParameter('lighttpd_config'),
      {$_->getParameters()},
      '/etc/lighttpd/conf.d/'.$_->get_application_path().'.conf'
    );
  }

  my $ipv4 = $APP->get_parameter('networking_ipv4');
  my ($ipv6) = $APP->get_parameter('networking_ipv6') =~ /^(.*)\//;
  `iptables -t nat -A PREROUTING ! -i lxcbr0 -p tcp --dport 80 -j DNAT --to-dest $ipv4`;
  `iptables -t filter -A FORWARD ! -i lxcbr0 -p tcp --dport 80 -j ACCEPT`;
  `ip6tables -t nat -A PREROUTING ! -i lxcbr0 -p tcp --dport 80 -j DNAT --to-dest $ipv6`;
  `ip6tables -t filter -A FORWARD ! -i lxcbr0 -p tcp --dport 80 -j ACCEPT`;

=head1 DESCRIPTION

Warning: this module is aimed to be used only inside a Floday context.
If you don't know what Floday is, it is probably a wrong idea to use this module yet.

This module is a helper that can be used for managing Floday application deployment.
It provides a lot of helpful functions that are listed below:

=head2 The $APP object

When Floday is deploying an application, it pass an "application" parameter to each "setup" or "end_setup" scripts
presents in the container definition for allowing those scripts to know on who it is working.

This parameter is automatically handled by this module and will create an $APP object that can directly be used in
your script.

  use Floday::Setup; //Create automaticaly a $APP object.
  my $lxc = $APP->get_lxc_instance(); //Get a Linux::LXC object depending on the application we are deploying.

If no "application" parameter is provided to the script, the $APP object is simply ignored.

=head2 Use a script as standalone

Of course, you can still use this module without providing any "application" parameter to your script. It can be
useful for debugging purpose:

  use Floday::Setup;
  my $my_blog = Floday::Setup->new('application_path' => 'my_server-web-my_blog');
  my $mum_blog = Floday::Setup->new('application_path' => 'my_server-web-mum_blog');

=head2 Object methods

=head3 generate_file($self, $source, $parameters, $destination)

Will generate a file with the $source Template Toolkit file, the $parameters parameters and write the result on the
$destination file inside the LXC container representing the current Floday application.
This function first role is to provide a way for generating configuration files.

=over 15

=item $source

String representing a Template Toolkit file to use as template.
The root of this string is the folder that contains Floday container set.
Eg: if $source = 'riuk/children/web/setups/lighttpd.tt' and the container/path configuration value in the
/etc/floday.cfg file has the "/etc/floday/containers" value, the source file will be /etc/floday/containers/riuk/children/web/setups/lighttpd.tt

=back

=over 15

=item $parameters

A hash that will be used for generating the output.
Refer to Template Toolkit documentation for knowing more about how that part works.

=back

=over 15

=item $destination

String that represent where to write the file on the LXC container.
If folders are missing, they will be automaticaly created.
Eg: if $destinatiion = /etc/lighttpd.conf and the LXC root of the current application is /var/lib/lxc/integration-web/rootfs,
the file will be write at the /var/lib/lxc/integration-web/rootfs/etc/lighttpd.conf emplacement, and the folder
/var/lib/lxc/integration-web/rootfs/etc will be created if it wasn't already the case.

=back

=head3 get_application_path($self)

Return the application path set to the object.

=head3 get_config($self)

Return a Floday::Helper::Config object initialized for the current application.

=head3 get_definition($self)

Return a hash with the part of the runlist corresponding to the current Floday application.
For knowing more about the runlist, please refer yourself to the Floday documentation.

=head3 get_lxc_instance($self)

Return a Linux::LXC object initialized for reaching the LXC container that manage the current Floday application.
If called from an application that represents the host, the script will die.

=head3 get_manager($self)

Return a new Floday::Setup object set on the manager of the current application, if it exists.
For knowing more about the manager notion, please refer yourself to the Floday documentation.

=head3 get_parameter($self, $param_name, $flag)

Get the value of a parameter.

=over 15

=item $param_name

Is a string with the name of the attribute we want to get.

=back

=over 15

=item $flag

Can be "$ALLOW_EMPTY" or "undef". If the flag is not set, the script will crash if an asked parameter doesn't exist in
the current Floday application. With it, the subroutine will simply return "undef".

Here is an example:

  use Floday::Helper qw/$APP ALLOW_UNDEF/;
  my $param = $APP->get_parameter('ipv4_external', ALLOW_UNDEF);

=back

=over 15

=item return

The return value is a string with the parameter value, if it exists. Otherwise, and if the ALLOW_EMPTY flag was
provided, the return value will be undef. Finally, the call will die if the parameter was not existing and that the
ALLOW_EMPTY flag was not set.

=back

=head3 get_parameters($self)

Return a hash that contains all parameters that exist for the current Floday application.

=head3 get_root_folder($self)

Get the folder from the host point of view that represents the root of the LXC container for the current Floday
application.

=head3 get_runlist($self)

Return a Floday::Helper::Runlist object initialized with your runfile.
For knowing more about what a runfile is, please refer yourself to the Floday documentation.

=head3 get_sub_applications($self)

Return an list of other Floday::Setup objects that represent all sub-applications the current one manage.
For knowing more about what a sub-application is, please refer yourself to the Floday documentation.

=head3 is_host($self)

Returns 1 if the current application is actually the host that is deploying Floday.
It returns 0 otherwise.

=head1 AUTHORS

Floday team - http://dev.spyzone.fr/floday

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by the Floday team.

This program is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.

You should have received a copy of the GNU General Public License along
with this program. If not, see <http://www.gnu.org/licenses/>.

=cut

package Floday::Lib::Linux::LXC;

use v5.20;

use Floday::Helper::Runlist;
use Carp;
use Moo;

extends 'Linux::LXC';
our @EXPORT_OK = ('ALLOW_UNDEF', 'ERASING_MODE', 'ADDITION_MODE');

has config => (
	default => sub {
		Floday::Helper::Config->instance();
	},
	is => 'ro',
	reader => 'get_floday_config'
);

has log => (
	is => 'ro',
	default => sub { Log::Any->get_logger },
);

has runlist => (
	is => 'rw',
	lazy => 1,
	builder => sub {
		Floday::Helper::Runlist->instance;
	},
	reader => 'get_runlist'
);

after deploy => sub {
	my ($this) = @_;
	my %hooks = $this->get_runlist->get_execution_list_by_priority_for_application(
	  $this->get_utsname, 'hooks', 'lxc_deploy_after'
	);
	$this->log->warningf('End deploying LXC container.');
	$this->log->{adapter}->indent_dec();
	$this->log->warningf('Start post deployment hook.');
	$this->log->{adapter}->indent_inc();
	for(sort {$a <=> $b} keys %hooks) {
		$this->log->infof('Running script: %s', $hooks{$_}{exec});
		my $prefix = $this->get_floday_config()->get_floday_config('containers', 'path');
		`$prefix/$hooks{$_}{exec}`;
	}
	$this->log->{adapter}->indent_dec();
	$this->log->warningf('End post deployment hook.');
};

after destroy => sub {
	my ($this) = @_;
	my %hooks = $this->get_runlist->get_execution_list_by_priority_for_application(
		$this->get_utsname, 'hooks', 'lxc_destroy_after'
	);
	$this->log->warningf('End LXC container destruction.');
	$this->log->warningf('Start post destroy hook.');
	$this->log->{adapter}->indent_inc();
	for (sort {$a cmp $b} keys %hooks) {
		$this->log->infof('Running script: %s', $hooks{$_}{exec});
		my $prefix = $this->get_floday_config()->get_floday_config('containers', 'path');
		my $application= $this->get_utsname();
		`$prefix/$hooks{$_}{exec} --application $application`;
	}
	$this->log->{adapter}->indent_dec();
	$this->log->warningf('End post destroy hook.');
};

after start => sub {
	my ($this) = @_;
	$this->log->debugf('%s: started', $this->get_utsname());
};

after stop => sub {
	my ($this) = @_;
	$this->log->debugf('%s: stopped', $this->get_utsname());
};

around get_template => sub {
	my ($orig, $this, $attr, $filter, $flags) = @_;
	my $results;
	eval {$results = $orig->($this, $attr, $filter, $flags)};
	if (defined $@ and $@ ne '') {
		$this->log->error($@);
		croak $@;
	}
	return $results;
};

around put => sub {
	my ($orig, $this, $input, $dest) = @_;
	$this->log->debugf('%s: put: %s on %s', $this->get_utsname(), $input, $dest);
	eval {$orig->($this, $input, $dest)};
	if (defined $@ and $@ ne '') {
		$this->log->error($@);
		croak $@;
	}
};

around _qx => sub {
	my ($orig, $this, $cmd, $params, $wantarray) = @_;
	$this->log->debugf('%s: _qx: `%s` => %s', $this->get_utsname(), $cmd, $params);
	my ($result, $stdout, $stderr) = $orig->($this, $cmd, $params, 1);
	chomp $stdout;
	chomp $stderr;
	$this->log->tracef('%s: _qx result: %s', $this->get_utsname(), $result);
	$this->log->tracef('%s: _qx stdout: %s', $this->get_utsname(), $stdout);
	$this->log->tracef('%s: _qx stderr: %s', $this->get_utsname(), $stderr);
	$this->log->errorf('%s', $stderr) unless $result;
	return ($result, $stdout, $stderr) if $wantarray;
	return $result;
};

before destroy => sub {
	my ($this) = @_;
	$this->log->warningf('Start pre destruction hooks.');
	$this->log->{adapter}->indent_inc();
	my %hooks = $this->get_runlist->get_execution_list_by_priority_for_application(
		$this->get_utsname, 'hooks', 'lxc_destroy_before'
	);
	for (sort {$a cmp $b} keys %hooks) {
		$this->log->infof('Running script: %s', $hooks{$_}{exec});
		my $prefix = $this->get_floday_config()->get_floday_config('containers', 'path');
		my $application = $this->get_utsname();
		`$prefix/$hooks{$_}{exec} --application $application`;
	}
	$this->log->{adapter}->indent_dec();
	$this->log->warningf('End pre destruction hooks.');
	$this->log->warningf('Start LXC container %s destruction.', $this->get_utsname());
};

before deploy => sub {
	my ($this) = @_;
	$this->log->warningf('Start pre deployment hooks.');
	$this->log->{adapter}->indent_inc();
	my %hooks = $this->get_runlist->get_execution_list_by_priority_for_application(
	  $this->get_utsname, 'hooks', 'lxc_deploy_before'
	);
	for(sort {$a cmp $b} keys %hooks) {
		$this->log->infof('Running script: %s', $hooks{$_}{exec});
		my $prefix = $this->get_floday_config()->get_floday_config('containers', 'path');
		my $application = $this->get_utsname();
		`$prefix/$hooks{$_}{exec} --application $application`;
	}
	$this->log->{adapter}->indent_dec();
	$this->log->warningf('End pre deployment hook.');
	$this->log->warningf('Start deploying LXC %s container.', $this->get_utsname());
	$this->log->{adapter}->indent_inc();
};

before start => sub {
	my ($this) = @_;
	$this->log->debugf('%s: start', $this->get_utsname());
};

before stop => sub {
	my ($this) = @_;
	$this->log->debugf('%s: stop', $this->get_utsname());
};

1;

=head1 NAME

Floday::Lib::Linux::LXC - Overload of Linux::LXC for logging purpose.

=head1 VERSION

1.2.0

=head1 DESCRIPTION

This is an internal module used by Floday for logging purpose.
You should not work directly with this module if you are not currently developing on Floday core.

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

You should have received a copy of the GNU General Public License

=cut

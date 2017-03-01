package Floday::Lib::Linux::LXC;

use v5.20;

use Floday::Helper::Runlist;
#use Log::Any;
use Moo;
use Data::Dumper;

extends 'Linux::LXC';
our @EXPORT_OK = ('ALLOW_UNDEF', 'ERASING_MODE', 'ADDITION_MODE');

has config => (
	default => sub {
		Floday::Helper::Config->instance();
	},
	is => 'ro',
	reader => 'getConfig'
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
	reader => 'getRunlist'
);

after deploy => sub {
	my ($this) = @_;
	my %hooks = $this->getRunlist->getExecutionListByPriorityForApplication(
	  $this->get_utsname, 'hooks', 'lxc_deploy_after'
	);
	for(sort {$a <=> $b} keys %hooks) {
		my $prefix = $this->getConfig()->getFlodayConfig('containers', 'path');
		say `$prefix/$hooks{$_}{exec}`;
	}
};

after start => sub {
	my ($this) = @_;
	$this->log->infof('%s: started', $this->get_utsname());
};

after stop => sub {
	my ($this) = @_;
	$this->log->infof('%s: stopped', $this->get_utsname());
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
	$this->log->infof('%s: put: %s on %s', $this->get_utsname(), $input, $dest);
	eval {$orig->($this, $input, $dest)};
	if (defined $@ and $@ ne '') {
		$this->log->error($@);
		croak $@;
	}
};

around _qx => sub {
	my ($orig, $this, $cmd, $params, $wantarray) = @_;
	$this->log->tracef('%s: _qx: `%s` => %s', $this->get_utsname(), $cmd, $params);
	my ($result, $stdout, $stderr) = $orig->($this, $cmd, $params, 1);
	$this->log->tracef('%s: _qx result: %s', $this->get_utsname(), $result);
	$this->log->tracef('%s: _qx stdout: %s', $this->get_utsname(), $stdout);
	$this->log->tracef('%s: _qx stderr: %s', $this->get_utsname(), $stderr);
	return ($result, $stdout, $stderr) if $wantarray;
	return $result;
};

before deploy => sub {
	my ($this) = @_;
	my %hooks = $this->getRunlist->getExecutionListByPriorityForApplication(
	  $this->get_utsname, 'hooks', 'lxc_deploy_before'
	);
	for(sort {$a <=> $b} keys %hooks) {
		my $prefix = $this->getConfig()->getFlodayConfig('containers', 'path');
		say `$prefix/$hooks{$_}{exec}`;
	}
};

before start => sub {
	my ($this) = @_;
	$this->log->infof('%s: start', $this->get_utsname());
};

before stop => sub {
	my ($this) = @_;
	$this->log->infof('%s: stop', $this->get_utsname());
};

1
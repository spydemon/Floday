package Floday::Lib::Virt::LXC;

use v5.20;

use Floday::Helper::Runlist;
use Moo;

extends 'Virt::LXC';

has config => (
	default => sub {
		Floday::Helper::Config->instance();
	},
	is => 'ro',
	reader => 'getConfig'
);

has runlist => (
	is => 'rw',
	lazy => 1,
	builder => sub {
		Floday::Helper::Runlist->instance;
	},
	reader => 'getRunlist'
);

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

1
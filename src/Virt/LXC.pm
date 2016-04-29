package Virt::LXC;

use v5.20;
use Data::Dumper;

sub new {
	my %this;
	my ($class, $utsname) = @_;
	defined $utsname or die 'Utsname is mandatory for LXC container.';
	$this{'utsname'} = $utsname;
	bless(\%this, $class);
	return \%this;
}

sub getExistingContainers {
	map{chomp $_; $_} `lxc-ls -1`;
}

sub getRunningContainers {
	map{chomp $_; $_} `lxc-ls -1 --running`
}

sub getStoppedContainers {
	map{chomp $_; $_} `lxc-ls -1 --stopped`
}

sub isRunning {
	my ($this) = @_;
	defined $this->{'utsname'} or die 'Utsname is missing.';
	grep {$_ eq $this->{'utsname'}} getRunningContainers;
}

sub isExisting {
	my ($this) = @_;
	defined $this->{'utsname'} or die 'Utsname is missing.';
	grep {$_ eq $this->{'utsname'}} getExistingContainers;
}

sub deploy {
	my ($this) = @_;
	defined $this->{'utsname'} or die 'Utsname is missing.';
	defined $this->{'template'} or die 'Template is missing.';
	$this->isExisting and die "Container with the $this->{'utsname'} utsname already exists.";
	`lxc-create -t $this->{'template'} -n $this->{'utsname'} 1>/dev/null`;
}

sub stop {
	my ($this) = @_;
	$this->isRunning or die "Container $this->{'utsname'} is not running.";
	`lxc-stop -n $this->{'utsname'}`;
}

sub start {
	my ($this) = @_;
	$this->isRunning and die "Container $this->{'utsname'} is already running.";
	$this->isExisting or die "Container $this->{'utsname'} doesn't exist.";
	`lxc-start -n $this->{'utsname'}`;
}

sub setTemplate {
	my ($this, $templateName) = @_;
	$this->{template} = $templateName;
}

0

package Virt::LXC;
use v5.20;

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

sub getLxcPath {
	my ($this) = @_;
	defined $this->{lxcpath} and return $this->{lxcpath};
	return "/var/lib/lxc/$this->{utsname}";
}

sub getConfig {
	my ($this, $attr) = @_;
	$this->isExisting or die ('Unexisting container.');
	open CONF, '<' . $this->getLxcPath . '/config';
	my @results;
	for (<CONF>) {
		/^$attr = (.*)$/ and push @results, $1
	};
	return @results;
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
	`lxc-create -t $this->{'template'} -n $this->{'utsname'} 2&1>/dev/null`;
}

sub destroy {
	my ($this) = @_;
	defined $this->{'utsname'} or die 'Utsname is missing.';
	$this->isRunning and $this->stop;
	`lxc-destropy -n $this->{'utsname'} 2&1>/dev/null`
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

sub exec {
	my ($this, $cmd) = @_;
	$this->isRunning or die 'Can\'t execute something in a non running container.';
	print `lxc-attach -n $this->{'utsname'} -- $cmd`;
}

sub setTemplate {
	my ($this, $templateName) = @_;
	$this->{template} = $templateName;
}

sub setLxcPath {
	my ($this, $path) = @_;
	$this->{lxcpath} = $path;
}

sub setConfig {
	my ($this, $attr, $value) = @_;
	defined $this->{'utsname'} or die 'Utsname is missing.';
	$this->isExisting or die "Container $this->{'utsname'} doesn't exist.";
	my $written = 0;
	open CONF_R, '<' . $this->getLxcPath . '/config';
	open CONF_W, '>' . $this->getLxcPath . '/config_r';
	for (<CONF_R>) {
		if (/^$attr = .*$/) {
			print CONF_W "$attr = $value\n";
			$written = 1;
		} else {
			print CONF_W $_;
		}
	}
	!$written and print CONF_W "$attr = $value\n";
	close CONF_R;
	close CONF_W;
	rename $this->getLxcPath. '/config_r', $this->getLxcPath . '/config';
}

1

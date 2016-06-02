package Virt::LXC;
use File::Temp;
use Carp;

use v5.20;

sub _qx {
	my ($this, $cmd, $wantarray) = @_;
	my $stderr = File::Temp->new();
	my $stdout = `$cmd 2>$stderr`;
	my $result = !$?;
	seek $stderr, 0, 0;
	open F,'<',$stderr;
	say $cmd;
	$wantarray and return ($result, $stdout, join('', <F>));
	return $result;
}

sub new {
	my %this;
	my ($class, $utsname) = @_;
	defined $utsname or croak 'Utsname is mandatory for LXC container';
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
	$this->isExisting or croak 'Unexisting container';
	open CONF, '<' . $this->getLxcPath . '/config';
	my @results;
	for (<CONF>) {
		/^$attr\W*=\W*(.*)$/ and push @results, $1
	};
	return @results;
}

sub isRunning {
	my ($this) = @_;
	defined $this->{'utsname'} or croak 'Utsname is missing';
	grep {/^$this->{'utsname'}$/} getRunningContainers;
}

sub isExisting {
	my ($this) = @_;
	defined $this->{'utsname'} or croak 'Utsname is missing';
	grep {/^$this->{'utsname'}$/} getExistingContainers;
}

sub isStopped {
	my ($this) = @_;
	defined $this->{'utsname'} or croak 'Utsname is missing';
	grep {/^$this->{'utsname'}$/} getStoppedContainers;
}

sub deploy {
	my ($this) = @_;
	defined $this->{'utsname'} or croak 'Utsname is missing';
	defined $this->{'template'} or croak 'Template is missing';
	$this->isExisting and croak "Container with the $this->{'utsname'} utsname already exists";
	$this->_qx("lxc-create -n $this->{'utsname'} -t $this->{'template'}", wantarray);
}

sub destroy {
	my ($this) = @_;
	defined $this->{'utsname'} or croak 'Utsname is missing';
	$this->isRunning and $this->stop;
	$this->_qx("lxc-destroy -n $this->{'utsname'}", wantarray);
}

sub stop {
	my ($this) = @_;
	$this->isRunning or croak "Container $this->{'utsname'} is not running";
	$this->_qx("lxc-stop -n $this->{'utsname'}", wantarray);
}

sub start {
	my ($this) = @_;
	$this->isRunning and croak "Container $this->{'utsname'} is already running";
	$this->isExisting or croak "Container $this->{'utsname'} doesn't exist";
	$this->_qx("lxc-start -n $this->{'utsname'}", wantarray);
}

sub exec {
	my ($this, $cmd) = @_;
	$this->isRunning or confess 'Can\'t execute something in a non running container.';
	$this->_qx("lxc-attach -n $this->{'utsname'} -- $cmd", wantarray);
}

sub put {
	my ($this, $input, $dest) = @_;
	$this->isExisting or croak 'Container doesn\'t exists';
	-r $input or croak "Input $input is not readable";
	$dest !~ /^\// and croak 'Destination should be an absolute path';
	$dest = $this->getLxcPath.'/rootfs'.$dest;
	$dest =~ /^(.*\/)/;
	-d $1 or `mkdir -p $1`;
	`cp -R $input $dest`;
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
	defined $this->{'utsname'} or croak 'Utsname is missing';
	$this->isExisting or croak "Container $this->{'utsname'} doesn't exist";
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

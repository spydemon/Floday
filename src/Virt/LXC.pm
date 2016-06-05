package Virt::LXC;
use v5.20;
use File::Temp;
use Carp;
use Moo;

has utsname => (
	'is' => 'ro',
	'required' => 1,
	'reader' => 'getUtsname'
);

has template => (
	'is' => 'rwp',
	'reader' => '_getTemplate',
	'writer' => 'setTemplate'
);

has lxcpath => (
	'is' => 'rwp',
	'reader' => '_getLxcPath',
	'writer'=> 'setLxcPath',
);

sub getLxcPath {
	my ($this) = @_;
	return $this->_getLxcPath if defined $this->_getLxcPath;
	'/var/lib/lxc/' . $this->getUtsname;
}

sub getTemplate {
	my ($this) = @_;
	croak 'Template is not provided for $this->getUtsname container.' unless $this->_getTemplate;
	$this->_getTemplate;
}

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

sub getExistingContainers {
	map{chomp $_; $_} `lxc-ls -1`;
}

sub getRunningContainers {
	map{chomp $_; $_} `lxc-ls -1 --running`
}

sub getStoppedContainers {
	map{chomp $_; $_} `lxc-ls -1 --stopped`
}

sub getConfig {
	my ($this, $attr) = @_;
	$this->isExisting() or croak 'Unexisting container';
	open CONF, '<' . $this->getLxcPath . '/config';
	my @results;
	for (<CONF>) {
		/^$attr\W*=\W*(.*)$/ and push @results, $1
	};
	return @results;
}

sub isRunning {
	my ($this) = @_;
	my $name = $this->getUtsname;
	grep {/^$name$/} getRunningContainers;
}

sub isExisting {
	my ($this) = @_;
	my $name = $this->getUtsname;
	grep {/^$name$/} getExistingContainers;
}

sub isStopped {
	my ($this) = @_;
	my $name = $this->getUtsname;
	grep {/^$name$/} getStoppedContainers;
}

sub deploy {
	my ($this) = @_;
	$this->isExisting and croak "Container with the $this->getUtsname utsname already exists";
	my $utsName = $this->getUtsname;
	my $template = $this->getTemplate;
	$this->_qx("lxc-create -n $utsName -t $template", wantarray);
}

sub destroy {
	my ($this) = @_;
	$this->isRunning and $this->stop;
	my $utsName = $this->getUtsname;
	$this->_qx("lxc-destroy -n $utsName", wantarray);
}

sub stop {
	my ($this) = @_;
	my $utsName = $this->getUtsname;
	$this->isRunning or croak "Container $utsName is not running";
	$this->_qx("lxc-stop -n $this->{'utsname'}", wantarray);
}

sub start {
	my ($this) = @_;
	my $utsName = $this->getUtsname;
	$this->isRunning and croak "Container $utsName is already running";
	$this->isExisting or croak "Container $utsName doesn't exist";
	$this->_qx("lxc-start -n $utsName", wantarray);
}

sub exec {
	my ($this, $cmd) = @_;
	my $utsName = $this->getUtsname;
	$this->isRunning or croak 'Can\'t execute something in a non running container.';
	$this->_qx("lxc-attach -n $utsName -- $cmd", wantarray);
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

sub setConfig {
	my ($this, $attr, $value) = @_;
	my $utsName = $this->getUtsname;
	$this->isExisting or croak "Container $utsName doesn't exist";
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

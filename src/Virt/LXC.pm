package Virt::LXC;
use v5.20;

use Backticks;
use Carp;
use Exporter qw(import);
use Log::Any ();
use Moo;

use constant ALLOW_UNDEF => 0x01;
our @EXPORT_OK = ('ALLOW_UNDEF');

$Backticks::autodie = 1;

has utsname => (
	'is' => 'ro',
	'required' => 1,
	'reader' => 'getUtsname'
);

has template => (
	'is' => 'rw',
	'reader' => '_getTemplate',
	'writer' => 'setTemplate'
);

has lxcpath => (
	'is' => 'rwp',
	'reader' => '_getLxcPath',
	'writer'=> 'setLxcPath',
);

has log => (
	is => 'ro',
	default => sub { Log::Any->get_logger },
);

sub getLxcPath {
	my ($this) = @_;
	return $this->_getLxcPath if defined $this->_getLxcPath;
	'/var/lib/lxc/' . $this->getUtsname;
}

sub getTemplate {
	my ($this) = @_;
	if (!$this->_getTemplate) {
		$this->log->errorf('%s: getTemplate: template not provided', $this->getUtsname);
		croak 'Template is not provided for $this->getUtsname container.';
	}
	$this->_getTemplate;
}

sub _qx {
	local $Backticks::autodie = 0;
	my ($this, $cmd, $wantarray) = @_;
	my $stderr = File::Temp->new();
	$this->log->tracef('%s: _qx: `%s`', $this->getUtsname, $cmd);
	my $exec = `$cmd`;
	$this->log->tracef('%s: _qx res: %s/%s/%s', $this->getUtsname, $exec->exitcode, $exec->stdout, $exec->stderr);
	$wantarray and return ($exec->exitcode, $exec->stdout, $exec->stderr);
	return !$exec->exitcode;
}

sub _checkContainerIsRunning {
	my ($this) = @_;
	if ($this->isStopped) {
		my (undef, undef, undef, $caller) = caller(1);
		$caller =~ /::(\w*)$/;
		$this->log->errorf('%s: %s: not running', $this->getUtsname, $1);
		croak 'Container ' . $this->getUtsname . ' is not running';
	}
}

sub _checkContainerIsExisting {
	my ($this) = @_;
	if (!$this->isExisting) {
		my (undef, undef, undef, $caller) = caller(1);
		$caller =~ /::(\w*)$/;
		$this->log->errorf('%s: %s: container not existing', $this->getUtsname, $1);
		croak 'Container ' . $this->getUtsname . ' doesn\'t exist';
	}
}

sub _checkContainerIsNotExisting {
	my ($this) = @_;
	if ($this->isExisting)  {
		my (undef, undef, undef, $caller) = caller(1);
		$caller =~ /::(\w*)$/;
		$this->log->errorf('%s: %s: container alreay exists', $this->getUtsname, $1);
		croak 'Container ' . $this->getUtsname . ' already exists';
	}
}


sub getExistingContainers {
	split("\n", `lxc-ls -1`);
}

sub getRunningContainers {
	split("\n", `lxc-ls -1 --running`);
}

sub getStoppedContainers {
	split("\n", `lxc-ls -1 --stopped`);
}

sub getConfig {
	my ($this, $attr, $filter, $flags) = @_;
	if (defined $filter and ref($filter) ne 'Regexp') {
		croak '$filter should be a regular expresion';
	}
	my $allowUndef = defined ($flags) && $flags & ALLOW_UNDEF;
	$this->_checkContainerIsExisting;
	open CONF, '<', $this->getLxcPath . '/config';
	my @results;
	for (<CONF>) {
		if (/^$attr\W*=\W*(?P<value>.*)$/) {
			if (defined $filter) {
				$+{value} =~ $filter and push @results, $1;
			} else {
				push @results, $+{value};
			}
		}
	}
	$this->log->debugf('%s: getConfig %s: %s', $this->getUtsname, $attr, \@results);
	if (!@results && !$allowUndef) {
		croak "'$attr' attribute was not found in lxc configuration file";
	}
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
	$this->_checkContainerIsNotExisting;
	my $utsName = $this->getUtsname;
	my $template = $this->getTemplate;
	$this->log->infof('%s: deploy', $this->getUtsname);
	$this->_qx("lxc-create -n $utsName -t $template", wantarray);
	$this->log->infof('%s: deployed', $this->getUtsname);
}

sub destroy {
	my ($this) = @_;
	$this->isRunning and $this->stop;
	$this->log->infof('%s: destroy', $this->getUtsname);
	$this->_qx('lxc-destroy -n '.$this->getUtsname, wantarray);
	$this->log->infof('%s: destroyed', $this->getUtsname);
}

sub stop {
	my ($this) = @_;
	my $utsName = $this->getUtsname;
	if (!$this->isRunning) {
		$this->log->warningf('%s: stop: already stopped', $this->getUtsname);
		return;
	}
	$this->log->infof('%s: stop', $this->getUtsname);
	$this->_qx('lxc-stop -n '.$this->getUtsname, wantarray);
	$this->log->infof('%s: stopped', $this->getUtsname);
}

sub start {
	my ($this) = @_;
	my $utsName = $this->getUtsname;
	$this->_checkContainerIsExisting;
	if ($this->isRunning) {
		$this->log->warningf('%s start: already started', $this->getUtsname);
		return;
	}
	$this->log->infof('%s: start', $this->getUtsname);
	$this->_qx("lxc-start -n $utsName", wantarray);
	$this->log->infof('%s: started', $this->getUtsname);
}

sub exec {
	my ($this, $cmd) = @_;
	$this->_checkContainerIsRunning;
	$this->log->infof('%s: exec `%s`', $this->getUtsname, $cmd);
	$this->_qx('lxc-attach -n '.$this->getUtsname." -- $cmd", wantarray);
}

sub put {
	my ($this, $input, $dest) = @_;
	my ($uid) = $this->getConfig('lxc.id_map', qr/^u 0 (\d+)/);
	$this->_checkContainerIsExisting;
	if (!-r $input) {
		$this->log->errorf('%s: put %s: not readable', $this->getUtsname, $input);
		croak "Input $input is not readable";
	}
	if ($dest !~ /^\//) {
		$this->log->errorf('%s: put %s: destination should be an absolute path', $this->getUtsname, $dest);
		croak 'Destination should be an absolute path';
	}
	$dest = $this->getLxcPath.'/rootfs'.$dest;
	$dest =~ /^(.*\/)/;
	-d $1 or `mkdir -p $1`;
	$this->log->infof('%s: put: %s on %s', $this->getUtsname, $input, $dest);
	`cp -R $input $dest`;
	`chown -R $uid:$uid $dest`;
}

sub setConfig {
	my ($this, $attr, $value) = @_;
	$this->_checkContainerIsExisting;
	$this->log->infof('%s: setConfig %s -> %s', $this->getUtsname, $attr, $value);
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

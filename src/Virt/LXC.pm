package Virt::LXC;
use v5.0;

use Backticks;
use Carp;
use Exporter qw(import);
use Log::Any;
use Moo;
use IPC::Run qw(run);

use constant ALLOW_UNDEF => 0x01;
use constant ERASING_MODE => 0x01;
use constant ADDITION_MODE => 0x02;
our @EXPORT_OK = ('ALLOW_UNDEF', 'ERASING_MODE', 'ADDITION_MODE');

our $VERSION = 1.0;

$Backticks::autodie = 1;

########################
## Module subroutines
########################
sub get_existing_containers {
	split("\n", `lxc-ls -1`);
}

sub get_running_containers {
	split("\n", `lxc-ls -1 --running`);
}

sub get_stopped_containers {
	split("\n", `lxc-ls -1 --stopped`);
}

########################
## Objects subroutines
########################
has utsname => (
	'is' => 'ro',
	'required' => 1,
	'reader' => 'get_utsname'
);

has template => (
	'is' => 'rw',
	'reader' => '_get_template',
	'writer' => 'set_template'
);

has lxcpath => (
	'is' => 'rwp',
	'reader' => '_get_lxc_path',
	'writer'=> 'set_lxc_path',
);

has log => (
	is => 'ro',
	default => sub { Log::Any->get_logger },
);

sub deploy {
	my ($this) = @_;
	$this->_check_container_is_not_existing();
	my $utsname = $this->get_utsname();
	my $template = $this->get_template();
	$this->log->infof('%s: deploy', $this->get_utsname());
	$this->_qx("lxc-create -n $utsname -t $template", undef, wantarray);
	$this->log->infof('%s: deployed', $this->get_utsname());
}

sub destroy {
	my ($this) = @_;
	$this->is_running() and $this->stop();
	$this->log->infof('%s: destroy', $this->get_utsname());
	$this->_qx('lxc-destroy -n '.$this->get_utsname(), undef, wantarray);
	$this->log->infof('%s: destroyed', $this->get_utsname());
}

sub exec {
	my ($this, $cmd) = @_;
	$this->_check_container_is_running();
	$this->log->infof('%s: exec `%s`', $this->get_utsname(), $cmd);
	$this->_qx('lxc-attach -n '.$this->get_utsname(), $cmd, wantarray);
}

sub get_lxc_path {
	my ($this) = @_;
	return $this->_get_lxc_path() if defined $this->_get_lxc_path();
	'/var/lib/lxc/' . $this->get_utsname();
}

sub get_config {
	my ($this, $attr, $filter, $flags) = @_;
	if (defined $filter and ref($filter) ne 'Regexp') {
		croak '$filter should be a regular expresion';
	}
	$filter //= qr/(.*)/;
	my $allow_undef = defined ($flags) && $flags & ALLOW_UNDEF;
	$this->_check_container_is_existing();
	open CONF, '<', $this->get_lxc_path() . '/config';
	my @results;
	for (<CONF>) {
		if (/^$attr\W*=\W*(?P<value>.*)$/) {
			push @results, $+{value} =~ $filter;
		}
	}
	$this->log->debugf('%s: getConfig \'%s\' with pattern \'%s\': %s', $this->get_utsname(), $attr, $filter, \@results);
	if (!@results && !$allow_undef) {
		croak "'$attr' attribute was not found in lxc configuration file with filter $filter";
	}
	return @results;
}

sub get_template {
	my ($this) = @_;
	if (!$this->_get_template()) {
		$this->log->errorf('%s: getTemplate: template not provided', $this->get_utsname());
		croak 'Template is not provided for $this->getUtsname container.';
	}
	$this->_get_template();
}

sub is_existing {
	my ($this) = @_;
	my $name = $this->get_utsname();
	grep {/^$name$/} get_existing_containers();
}

sub is_running {
	my ($this) = @_;
	my $name = $this->get_utsname();
	grep {/^$name$/} get_running_containers();
}

sub is_stopped {
	my ($this) = @_;
	my $name = $this->get_utsname();
	grep {/^$name$/} get_stopped_containers();
}

sub put {
	my ($this, $input, $dest) = @_;
	my ($uid) = $this->get_config('lxc.id_map', qr/^u 0 (\d+)/, ALLOW_UNDEF);
	$this->_check_container_is_existing();
	if (!-r $input) {
		$this->log->errorf('%s: put %s: not readable', $this->get_utsname(), $input);
		croak "Input $input is not readable";
	}
	if ($dest !~ /^\//) {
		$this->log->errorf('%s: put %s: destination should be an absolute path', $this->get_utsname(), $dest);
		croak 'Destination should be an absolute path';
	}
	$dest = $this->get_lxc_path().'/rootfs'.$dest;
	$dest =~ /^(.*\/)/;
	-d $1 or `mkdir -p $1`;
	$this->log->infof('%s: put: %s on %s', $this->get_utsname(), $input, $dest);
	`cp -R $input $dest`;
	`chown -R $uid:$uid $dest` if defined $uid;
}
#TODO add del_config subroutine.

sub set_config {
	my ($this, $attr, $value, $flags) = @_;
	$flags = ERASING_MODE unless defined $flags;
	croak 'set_config can not be in erasing and addition mode' if ($flags == (ERASING_MODE | ADDITION_MODE));
	$this->_check_container_is_existing();
	$this->log->infof('%s: setConfig %s -> %s', $this->get_utsname(), $attr, $value);
	if ($flags & ADDITION_MODE) {
		open CONF, '>>', $this->get_lxc_path() . '/config';
		print CONF "$attr = $value\n";
	} else {
		my $written = 0;
		open CONF_R, '<'.$this->get_lxc_path().'/config';
		open CONF_W, '>'.$this->get_lxc_path().'/config_r';
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
		rename $this->get_lxc_path().'/config_r', $this->get_lxc_path().'/config';
	}
}

sub start {
	my ($this) = @_;
	my $utsname = $this->get_utsname();
	$this->_check_container_is_existing();
	if ($this->is_running()) {
		$this->log->warningf('%s start: already started', $this->get_utsname());
		return;
	}
	$this->log->infof('%s: start', $this->get_utsname());
	$this->_qx("lxc-start -d -n $utsname", undef, wantarray);
	$this->log->infof('%s: started', $this->get_utsname());
}

sub stop {
	my ($this) = @_;
	if (!$this->is_running()) {
		$this->log->warningf('%s: stop: already stopped', $this->get_utsname());
		return;
	}
	$this->log->infof('%s: stop', $this->get_utsname());
	$this->_qx('lxc-stop -n '.$this->get_utsname(), undef, wantarray);
	$this->log->infof('%s: stopped', $this->get_utsname());
}

########################
## Internal subroutines
########################
sub _check_container_is_existing {
	my ($this) = @_;
	if (!$this->is_existing()) {
		my (undef, undef, undef, $caller) = caller(1);
		$caller =~ /::(\w*)$/;
		$this->log->errorf('%s: %s: container not existing', $this->get_utsname(), $1);
		croak 'Container ' . $this->get_utsname() . ' doesn\'t exist';
	}
}

#TODO: is duplicate with _check_container_is_existing.
sub _check_container_is_not_existing {
	my ($this) = @_;
	if ($this->is_existing())  {
		my (undef, undef, undef, $caller) = caller(1);
		$caller =~ /::(\w*)$/;
		$this->log->errorf('%s: %s: container alreay exists', $this->get_utsname(), $1);
		croak 'Container ' . $this->get_utsname() . ' already exists';
	}
}

sub _check_container_is_running {
	my ($this) = @_;
	if ($this->is_stopped()) {
		my (undef, undef, undef, $caller) = caller(1);
		$caller =~ /::(\w*)$/;
		$this->log->errorf('%s: %s: not running', $this->get_utsname(), $1);
		croak 'Container ' . $this->get_utsname() . ' is not running';
	}
}

sub _qx {
	my ($this, $cmd, $params, $wantarray) = @_;
	my $log = $this->get_utsname() . ': _qx:`' . $cmd . '`';
	$log .= ' => ' . $params if defined $params;
	$this->log->tracef($log);
	my @cmd = split(' ', $cmd);
	my ($stdout, $stderr);
	my $result = run \@cmd, \$params, \$stdout, \$stderr;
	$this->log->tracef('%s: _qx res: %s/%s/%s', $this->get_utsname(), $result, $stdout, $stderr);
	$wantarray and return ($result, $stdout, $stderr);
	return $result;
}

1

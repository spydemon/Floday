#!/usr/bin/env perl

use v5.20;
use warnings;
use strict;

use feature qw(signatures);
no warnings qw(experimental::signatures);

use Getopt::Long;
use Switch;
use File::Basename;
use Net::OpenSSH;
$Net::OpenSSH::debug = 0;

my $action = '';
GetOptions(
  "a=s" => \$action
);

sub run($msg, $cmd){
	say "\033[32m$msg\033[0m";
	open my $exec, '|-', $cmd or die $!;
}

sub error($msg) {
	say "\033[1;31m$msg\033[0m";
}

sub container_stop {
	if (`VBoxManage list runningvms` =~ /Floday_Work/) {
		run
		  'Stop Floday_Work vm.',
		  'VBoxManage controlvm Floday_Work acpipowerbutton';
		while (`VBoxManage list runningvms` =~ /Floday_Work/){};
	}
}

sub container_flush {
	container_stop;
	if (`VBoxManage list vms` =~ /Floday_Work/) {
		my ($hdd) = `VBoxManage showvminfo Floday_Work` =~ /SATA \(0, 0\): ([-\/_.a-zA-Z0-9 ]{0,}) .*/;
		run
		  'Unlink hdd and vm.',
		  'VBoxManage modifyvm Floday_Work --hda none';
		run
		  'Destroying virtual machine.',
		  'VBoxManage unregistervm Floday_Work';
		run
		  'Destroying virtual hdd.',
		  "VBoxManage closemedium disk \"$hdd\" --delete";
		run
		  'Destroying vm folder.',
		  'rm -r "' . dirname($hdd) . '"';
	}
}

sub get_container_ip {
	my ($ip) = `VBoxManage guestproperty get Floday_Work /VirtualBox/GuestInfo/Net/0/V4/IP` =~ /^Value: ([.0-9]*)$/;
	return $ip;
}

sub container_run {
	`VBoxManage list runningvms` =~ /Floday_Work/
	  and error 'Floday_Work is already running.'
	  and die;
	`VBoxManage showvminfo Floday_Work`;
	$? == 0
	  or run
	    'Building Floday_Work image.',
	    'VBoxManage clonevm Floday_Clean --name Floday_Work --register';
	run 
	  'Start Floday_Work virtual machine.',
	  'VBoxManage startvm Floday_Work --type headless';
	my $ip;
	do {
		$ip = get_container_ip;
	} while (!defined $ip);
	say "Container ip address : $ip";
}

sub container_exec($cmd) {
	container_run if !defined get_container_ip;
	my $ssh = Net::OpenSSH->new("user:password@".get_container_ip);
	$ssh->error and die('SSH fail: ' . $ssh->error);
	my ($out, $pid) = $ssh->pipe_out($cmd)
	  or die "ssh command failed: " . $ssh->error;
	while (<$out>) { print; }
}

`whereis VBoxManage` =~ /:$/
  and error 'Virtualbox seems to not be installed.'
  and die;

`VBoxManage showvminfo Floday_Clean`;
$? != 0
  and error 'No Floday_Clean container was found.'
  and die;

switch ($action) {
	case 'flush' {container_flush;}
	case 'run' {container_run;}
	case 'stop' {container_stop;}
	case 'test' {container_exec('perl /opt/floday/t/harness.pl');}
	case 'exec' {container_exec('cd /opt/floday/src/ && ./floday.pl --run ../samples/run.xml --host spyzone');}
	else {container_run;}
}


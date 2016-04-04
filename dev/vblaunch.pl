#!/bin/perl

use v5.20;
use warnings;
use strict;

use feature qw(signatures);
no warnings qw(experimental::signatures);

use Getopt::Long;
use Switch;
use File::Basename;

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
		my ($uuid) = `VBoxManage showvminfo Floday_Work` =~ /UUID: ([-a-z0-9]{1,})/;
		my ($hdd) = `VBoxManage showvminfo Floday_Work` =~ /IDE \(0, 0\): ([-\/_.a-zA-Z0-9 ]{0,}) .*/;
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
		($ip) = `VBoxManage guestproperty get Floday_Work /VirtualBox/GuestInfo/Net/0/V4/IP` =~ /^Value: ([.1-9]*)$/;
	} while (!defined $ip);
	say "Container ip address : $ip";
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
	else {container_run;}
}


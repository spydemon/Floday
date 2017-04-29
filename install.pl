#!/usr/bin/env perl
use strict;
use warnings;
use v5.20;

use FindBin;
use lib ($FindBin::Bin);
chdir $FindBin::Bin;

#TODO: manage uninstalling.
#TODO: manage lxc template installation.
my $PATH = 'src/';

my %dependencies;
lookup_dir($PATH);

my $current_dir = $FindBin::Bin;
`mkdir -p /etc/perl/`;
`ln -s $current_dir/src/Floday /etc/perl/`;

for (keys %dependencies) {
	`cpan $_`;
}

sub lookup_dir {
	my ($dir_name) = @_;
	opendir (my $project, $dir_name);
	while(readdir $project) {
		next if /^\.\.?$/;
		my $abs_path = $dir_name . '/' . $_;
		lookup_dir($abs_path) if -d $abs_path;
		next unless -f $abs_path;
		open (my $src, '<', $abs_path);
		while(<$src>) {
			next unless /^.*use\s+([A-Z][a-zA-Z:]*)/
			  or /extends\s+'(.*)'/;
			next if /Floday/;
			$dependencies{$1} = 1;
		}
	}
}

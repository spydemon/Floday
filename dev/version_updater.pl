#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;

use FindBin;
use lib ($FindBin::Bin);
chdir $FindBin::Bin;

use Getopt::Long;
use File::Find;

my ($version_from, $version_to);
my $format_version = qr/^[\d\.]+$/;

GetOptions('from=s', \$version_from, 'to=s', \$version_to);

die('Invalid $version_from') unless $version_from =~ $format_version;
die('Invalid $version_to') unless $version_to =~ $format_version;

find(\&update_perldoc_version, '.', "$FindBin::Bin/../src");
update_latex_version();

sub update_latex_version {
	open(my $file_out, '<:encoding(UTF-8)', "$FindBin::Bin/../doc/main.tex") or die ($!);
	local $/;
	while (<$file_out>) {
		chomp;
		s/versionReference\{\Q$version_from\E\}/versionReference\{$version_to\}/g;
		open(my $file_in, '>:encoding(UTF-8)', "$FindBin::Bin/../doc/main.tex") or die ($!);
		print $file_in $_;
	}
}

sub update_perldoc_version {
	return unless -f $File::Find::name;
	open(my $file_out, '<:encoding(UTF-8)', $File::Find::name) or die ($!);
	local $/;
	while (<$file_out>) {
		chomp;
		s/=head1 VERSION\s\s\Q$version_from\E/=head1 VERSION\r\n\r\n$version_to/g;
		open(my $file_in, '>:encoding(UTF-8)', $File::Find::name) or die ($!);
		print $file_in $_;
	}
}

=head1 NAME

version_updater.pl - Will update the version number in all Floday files that contain it.

=head1 VERSION

1.0.3

=head1 SYNOPSYS

./version_updater.pl --from 1.0.2 --to 1.0.3

=cut

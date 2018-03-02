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

find(\&update_perldoc_version, '.', '../src');

update_file (
  '../src/floday.pl',
  qr/my \$message_version\s*=\s*'\Q$version_from\E';/,
  "my \$message_version = '$version_to';"
);

update_file (
  '../doc/main.tex',
  qr/versionReference\{\Q$version_from\E\}/,
  "versionReference\{$version_to\}"
);

update_file (
  '../t/integration/floday.t',
  qr/\Qcmp_ok(`..\/..\/src\/floday.pl --version`->stdout(), 'eq', "$version_from\n"/,
  "cmp_ok(`../../src/floday.pl --version`->stdout(), 'eq', \"$version_to\\n\""
);

sub update_file {
	my ($file, $pattern_in, $pattern_out) = @_;
	open(my $file_out, '<:encoding(UTF-8)', $file) or die ("$file: $!");
	local $/;
	while (<$file_out>) {
		chomp;
		s/$pattern_in/$pattern_out/g;
		open(my $file_in, '>:encoding(UTF-8)', $file) or die ($!);
		print $file_in $_;
	}
}

sub update_perldoc_version {
	return unless -f;
	update_file (
	  $_,
	  qr/=head1 VERSION\s*\Q$version_from\E/,
	  "=head1 VERSION\r\n\r\n$version_to"
	);
}

=head1 NAME

version_updater.pl - Will update the version number in all Floday files that contain it.

=head1 VERSION

1.1.3

=head1 SYNOPSYS

./version_updater.pl --from 1.0.2 --to 1.0.3

=cut

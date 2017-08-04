#!/usr/bin/perl

use strict;
use warnings;

use File::Path;

my $source   = $ARGV[0];
my $dest_dir = defined($ARGV[1]) ? $ARGV[1] : './';
if ($dest_dir !~ m|/$|) { $dest_dir = "$dest_dir/"; }

open( IN, '<', $source ) || die "Unable to open $source\n";
local $/ = undef;
my $in = <IN>;
close IN;

foreach my $contents ( split m/(^|;)\s*\#*\s*package\s+/, $in ) {
	next if ( $contents =~ m/^\s*\;?\s*$/);
	my $package = '';
	if ($contents =~ m/^([\w:]+)\s*;/) {
		$package = $1;
		$contents =~ s/^([\w:]+)\s*;/package $package;/;
		$contents =~ s/\s*1;\s*$//;
		$contents .= "\n\n1;\n";
	}
	else {
		die "Unable to parse package name on '$contents'!\n";
	}
	my $file = $package.'.pm';
	$file =~ s|::|/|gs;
	my $full_dir = $dest_dir . $file;
	$full_dir =~ s|/\w+.pm||;
	unless (-d $full_dir) { mkpath($full_dir); }
	open( OUT, '>', $dest_dir.$file )
	  || die "Unable to open output file '$dest_dir$file'\n";
	print OUT $contents;
	close OUT;
}

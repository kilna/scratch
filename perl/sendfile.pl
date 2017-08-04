#!/usr/bin/perl

use strict;
use warnings;

use Sys::Hostname;
use MIME::Lite;
use Getopt::Long;

Getopt::Long::Configure('pass_through');

my @to      = ('anthony.kilna@everyonecounts.com');
my $from    = 'anthony.kilna@everyonecounts.com';
my $server  = 'volta.ec.loc';
my $subject = '';
my $content = '';
my $hello   = hostname();
my $debug   = 1;

GetOptions(
	'to|t=s'      => \@to,
	'from|r=s'    => \$from,
	'server|s=s'  => \$server,
	'debug|d'     => \$debug,
	'subject|j=s' => \$subject,
	'hello|h=s'   => \$hello,
);

my @files = @ARGV;

unless (scalar @files)
{
	print STDERR "USAGE: $0 [options] file1, file2, ...";
	exit 1;
}

foreach my $file (@files)
{
	next if (-f $file);
	print STDERR "Path $file cannot be found or is not a regular file";
	exit 1;
}

my $filenames = join ' ', @files;

if ($subject eq '')
{
	$subject = "Sending $filenames"
}

if ($content eq '')
{
	$content = "Please see attached files:\n\n";
	$content .= "  ".join("\n  ", @files)."\n";
}

my $m = MIME::Lite->new(
	'From'    => $from,
	'To'      => join(', ', @to),
	'Subject' => $subject,
	'Type'    => 'TEXT',
	'Data'    => $content,
);

foreach my $file (@files)
{
	$m->attach(
		'Path' => $file,
		'Type' => 'AUTO',
	);
}

$m->send(
	'smtp'  => $server,
	'Hello' => $hello,
	'Debug' => $debug,
);

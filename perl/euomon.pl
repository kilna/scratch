#!/usr/bin/perl

use strict;
use warnings;

use LWP::Simple qw(get $ua);
use Data::Dumper;
use POSIX qw(asctime);
use FindBin;
use File::Pid;
use File::Basename;

$| = 1;
my $name = $FindBin::Bin.'/'.(File::Basename::basename($0))[0];
$ua->agent('Mozilla/5.0 (Windows NT 6.1; WOW64; rv:36.0) Gecko/20100101 Firefox/36.0');
my $wait = ($ARGV[0] =~ m/^\d+$/) ? shift(@ARGV) : 600;

sub logmsg ($) {
    my $msg = shift;
    my $ts = asctime(localtime);
    $ts =~ s/\n//;
    $ts =~ s/\0//;
    print $ts . " $msg\n";
}

my $pidfile = File::Pid->new( { 'file' => $name.'.pid' } );
$pidfile->running && exit;
(-f $pidfile->file) && $pidfile->remove;
$pidfile = File::Pid->new( { 'file' => $name.'.pid' } );
$pidfile->write;

$SIG{INT} = $SIG{TERM} = sub { 
    logmsg "daemon stopped $$";
    $pidfile->remove;
    exit;
};

my $br = qr/\s*<br\s*\/?>\s*/;
    
logmsg "daemon started $$";

my %last_online = ();
while (1) {
    my $page = get('http://euotopia.com/armoury.php');
    if ($page =~ m|<b>Regular</b>$br(.*?)(?:$br)?\s*(\d+)\s+player|s) {
        my $num_online = $2;
        my %online = map { $_ => 1 } 
                     map { s/^.*>(\w+)<.*$/$1/; $_ } 
                     split /,/, $1;
        foreach my $char ( keys %last_online ) {
            next if $online{$char};
            logmsg "[$num_online] - $char";
        } 
        foreach my $char ( keys %online ) {
            next if $last_online{$char};
            logmsg "[$num_online] + $char";
        }
        %last_online = %online;
    }
    sleep $wait;
}


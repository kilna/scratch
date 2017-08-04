#!/usr/bin/perl

use strict;
use warnings;

use LWP::UserAgent;
use HTML::Entities;
use Getopt::Long;
use POSIX qw(strftime);

my $debug           = 0;
my $req_sleep       = 1;
my $check_sleep     = 2;
my $processed_cache = 1800; # 30 minutes
my $size_threshold  = 0;
my $at_lines_ratio  = 0;
my $text_only       = 0;
my $new_only        = 0;
my $save            = 0;

GetOptions(
    'debug|d'           => \$debug,
    'req-sleep=i'       => \$req_sleep,
    'check-sleep=i'     => \$check_sleep,
    'processed-cache=i' => \$processed_cache,
    'size-threshold=i'  => \$size_threshold,
    'at-lines-ratio=s'  => \$at_lines_ratio,
    'text-only'         => \$text_only,
    'new-only'          => \$new_only,
    'save'              => \$save,
);

my $ua = LWP::UserAgent->new();
$ua->timeout(10);

my @cols = qw( name age syntax );

my %processed = ();
my $counter = 1;
while (1) {
    foreach my $record ( get_archive() ) {
        next if exists $processed{$record->{'id'}};
        $processed{$record->{'id'}} = time;
        next if $text_only && ($record->{'syntax'} ne 'text');
        next if $new_only && ($counter == 1);
        my $contents = get($record->{'url'});
        next if (length($contents) < $size_threshold);
        if ($at_lines_ratio) {
            my $ats = () = ($contents =~ m/\@/gs);
            next unless $ats;
            my $lines = (() = ($contents =~ m/\n/gs)) + 1;
            next if (($ats / $lines) < $at_lines_ratio);
        }
        my $stamp = strftime ('%Y-%m-%d %H:%M:%S', localtime());
        my $out = "URL: $record->{'url'}\n";
        $out .= "ID: $record->{'id'}\n";
        $out .= "Time: $stamp\n";
        if ($record->{'name'} ne 'Untitled') {
            $out .= "Title: $record->{'name'}\n";
        }
        $out .= "\n$contents";
        print '-=-' x 26 . "\n";
        print $out."\n\n\n";
        if ($save) {
            my $filename = $stamp . '-' . $record->{'id'};
            $filename =~ s/:/-/gs;
            $filename =~ s/[^0-9A-Za-z-_]/_/gs;
            $filename .= '.txt';
            if ( open my $FILE, '>', $filename) {
                print $FILE "$out";
                close $FILE;
            }
            else {
                warn "Unable to open $filename: $!";
            }
        }
    }
    # Clean old "seen" cache entries;
    foreach my $id (keys %processed) {
        if ((time - $processed{$id}) > $processed_cache) {
            delete $processed{$id};
        }
    }
    sleep $check_sleep;
    $counter++;
}

sub get {
    my $url = shift;
    my $content = '';
    my $trynum;
    for ($trynum = 1; $trynum <= 6; $trynum++) {
        sleep $req_sleep * ((2 ^ $trynum) - 1); # 1, 3, 7, 15, 31
        $debug && print "Getting $url ...\n";
        my $resp = $ua->get($url);
        $content = $resp->decoded_content;
        if ($content =~ m/Pastebin.*Please slow down/i) {
            next;
        }
        last if $resp->is_success;
    }
    $debug && print "Got $url\n";
    return $content;
}
    
sub get_archive {
    my $str = get("http://pastebin.com/archive");
    my @records = ();
    RECORD: foreach my $tr ( $str =~ m|<tr>(.*?)</tr>|gs ) {
        $debug && print "Got TR chunk $tr\n";
        my $record = {};
        my $count = 0;
        foreach my $val ( $tr =~ m|<td.*?>(.*?)</td>|gs ) {
            $debug && print "Got TD chunk $val\n";
            my $key = $cols[$count++];
            if ($key eq 'name') {
                $val =~ m|\s*<a href="/(.*)">\s*(.*?)\s*</a>\s*|;
                $record->{'id'} = $1;
                $record->{'url'} = "http://pastebin.com/raw.php?i=$1";
                $val = $2;
            }
            elsif ($key eq 'syntax') {
                $val =~ s|^\s*<a href="/archive/(.*?)">.*?</a>\s*$|$1|gs
            }
            elsif ($key eq 'age') {
                if ($val =~ m/(\d+)\s+sec\s+ago/) {
                    $val = $1;
                }
                elsif ($val =~ m/(\d+)\s+min\s+ago/) {
                    $val = $1 * 60;
                }
                else {
                    $val = '';
                }
            }
            $val = decode_entities($val);
            $record->{$key} = $val;
        }
        push @records, $record;
    }
    return reverse @records;
}


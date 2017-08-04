#!/bin/env perl

use strict;
use warnings;
use v5.10;
use Data::Dumper;
use List::Util qw(sum);

my $elections = 1000000;

my %profiles = (
    'dem'      => 'Democrat (partisan assertion position)',
    'rep'      => 'Republican (partisan assertion position)',
    'dem_avg'  => 'Democrat (averaged bipartisan positions)',
    'rep_avg'  => 'Republican (averaged bipartisan positions)',
    'dem_str'  => 'Democrat (strongest position)',
    'rep_str'  => 'Republican (strongest position)',
    'dem_weak' => 'Democrat (weakest position)',
    'rep_weak' => 'Republican (weakest position)',
);

my @states = ();
foreach (<DATA>) {
    die "Bad line '$_'" unless m/
      ^ (\w\w) \s+
      (.*?) \s+
      (\d+) \s+
      (\d+(?:\.\d+)?) \s+
      (\d+(?:\.\d+)?) \s* $
    /x;
    my $d = ($4 ? ($4 / 100) : 0);
    my $r = ($5 ? ($5 / 100) : 0);
    my $d_to_r = 1 - $d;
    my $r_to_d = 1 - $r;
    push @states, {
        'code'     => $1,
        'state'    => $2,
        'votes'    => $3,
        'dem'      => $d,
        'rep'      => $r,
        'dem_avg'  => (($d + 1 - $r) / 2 ),
        'rep_avg'  => (($r + 1 - $d) / 2 ),
        'dem_str'  => (($d > $r_to_d) ? $d : $r_to_d),
        'rep_str'  => (($r > $d_to_r) ? $r : $d_to_r),
        'dem_weak' => (($d < $r_to_d) ? $d : $r_to_d),
        'rep_weak' => (($r < $d_to_r) ? $r : $d_to_r),
    };
}
# print Dumper(\@states);

foreach my $profile (sort keys %profiles) {
	my @results = ();
    foreach (0..$elections) {
        my $votes = 0;
        foreach (@states) {
            if (rand(1) < $_->{$profile}) { $votes += $_->{'votes'}; }
        }
        push @results, $votes;
    }
    my $wins = scalar( grep { $_ >= 270 } @results );
#    my %vote_counts = ();
#    foreach (@results) { $vote_counts{$_}++; }
#    my $most_common_count = 0;
#    my $most_common = 0;
#    foreach (sort { $a <=> $b } keys %vote_counts) {
#        if ($vote_counts{$_} > $most_common_count) {
#            $most_common_count = $vote_counts{$_};
#            $most_common = $_;
#        }
#    }
    #    print "$_ => $vote_counts{$_}\n";
    # print Dumper(\@results);
    printf "%-45s Avg Votes %0.1f   Win %0.1f%%\n",
        $profiles{$profile},
        (sum(@results) / @results),
        (( $wins / @results ) * 100);
#    print '-' x 78 . "\n";
#    print $profiles{$profile} . "\n";
#    print "Average votes: ".(sum(@results) / @results)."\n";
#    print "Most common name votes: ".$most_common."\n";
#    print "Win percentage: ".(( $wins / @results ) * 100)."\n";
#    print "\n";
}


__DATA__
WA Washington           12  95     6
OR Oregon                7  92    15
CA California           55  95.1   6
NV Nevada                6  68.5  31.6
ID Idaho                 4   0    93.5
UT Utah                  6   0    91.5
AZ Arizona              11  10.3  89.8
NM New Mexico            5  88    14.9
CO Colorado              9  47.5  52.6
WY Wyoming               3   0    85
MT Montana               3   4    98
ND North Dakota          3   9.9  98.0
SD South Dakota          3   5    94
NE Nebraska              5   0    82.9
KS Kansas                6   0    96.4
OK Oklahoma              7   8    97
TX Texas                38   2    98.1
LA Louisiana             8   0    75.5
AR Arkansas              6   0    97.5
MO Missouri             10  11    89.7
IA Iowa                  6  62.5  37
MN Minnesota            10  85    15
WI Wisconsin            10  68.1  34.5
IL Illinois             20  83.7   5
IN Indiana              11   5    95.1
MI Michigan             16  83.5  16.6
OH Ohio                 18  59.5  43.4
KY Kentucky              8   0    98
TN Tennessee            11  10    90
MS Mississippi           6   0    82.5
AL Alabama               9   0    97.5
FL Florida              29  33.9  70.1
GA Georgia              16   3.2  95.1
SC South Carolina        9   6.6  98.5
NC North Carolina       15  21.9  78
VA Virginia             13  45.1  55
WV West Virginia         5   6    93
MD Maryland             10  88.8   0
DE Delaware              3  97     0
NJ New Jersey           14  97     9.4
PA Pennsylvania         20  79.6  25.6
NY New York             29  99.8   0
CT Connecticut           7  89.5   9
RI Rhode Island          4  86.5   0
MA Massachussets        11  99.6   3
VT Vermont               3  99     3
NH New Hampshire         4  62    38
ME Maine                 4  96     4
DC District of Columbia  3  65     0
HI Hawaii                4  90    10
AK Alaska                3   0    91.5

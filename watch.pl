#!/usr/bin/perl

use strict;
use warnings;

my %segments = (
    'a' => '  /| ',
    'b' => ' |/| ',
    'c' => '-|  -',
    'd' => '- /|-',
    'e' => '-|/ -',
    'f' => '-|   ',
    'g' => '  /|-',
    'h' => ' | | ',
    'i' => '-  |-',
    'j' => '   |-',
    'k' => '  / -',
    'l' => ' |  -',
    'm' => '- /| ',
    'n' => '-| | ',
    'o' => '-| |-',
    'p' => '-|/  ',
    'q' => '-|/|-',
    'r' => '-|/| ',
    's' => ' |/| ',
    't' => '-  | ',
    'u' => ' | |-',
    'v' => ' |/  ',
    'w' => ' |/ -',
    'x' => '  /  ',
    'y' => '- /  ',
    'z' => '- / -',
    '-' => '-   -',
);


my @minutes = qw(
    .|_-o-clock
    one-past-.
    two-past-.
    three-past-.
    four-past-.
    five-past-.
    six-past-.
    seven-past-.
    eight-past-.
    nine-past-.
    ten-past-.
    _-eleven
    _-twelve
    _-thirteen
    _-fourteen
    quarter-past-.
    _-sixteen
    _-seventeen
    _-eighteen
    _-nineteen
    _-twenty
    _-twenty-one
    _-twenty-two
    _-twenty-three
    _-twenty-four
    _-twenty-five
    _-twenty-six
    _-twenty-seven
    _-twenty-eight
    _-twenty-nine
    half-past-.
    _-thirty-one
    _-thirty-two
    _-thirty-three
    _-thirty-four
    _-thirty-five
    _-thirty-six
    _-thirty-seven
    _-thirty-eight
    _-thirty-nine
    _-fourty
    _-fourty-one
    _-fourty-two
    _-fourty-three
    _-fourty-four
    quarter-to-^
    _-fourty-six
    _-fourty-seven
    _-fourty-eight
    _-fourty-nine
    ten-til-^
    _-fifty-one
    _-fifty-two
    _-fifty-three
    _-fifty-four
    five-til-^
    _-fifty-six
    three-til-^
    two-til-^
    a-minute-to-^
);

my @hours = qw(
    midnite|twelve
    one
    two
    three
    four
    five
    six
    seven
    eight
    nine
    ten
    eleven
    noon|twelve
    one
    two
    three
    four
    five
    six
    seven
    eight
    nine
    ten
    eleven
);

my @lengths= ();
my @long = ();
my %letters = ();

foreach my $hour_num (0..$#hours) {
    
    my $hour = $hours[$hour_num];
    my $hour_special = $hour;
    if ($hour =~ m/^(.*)\|(.*)/) {
        $hour_special = $1;
        $hour = $2;
    }
    
    my $hour_up_num = ($hour_num == 23) ? 0 : ($hour_num + 1);
    my $hour_up = $hours[$hour_up_num];
    if ($hour_up =~ m/^(.*)\|/) { $hour_up = $1; }
    
    foreach my $min_num (0..59) {
        my $min = $minutes[$min_num];
        my $min_special = $min;
        if ($min =~ m/^(.*)\|(.*)$/) {
            $min_special = $1;
            $min = $2;
            if ($hour ne $hour_special) {
                $min = $min_special;
            }
        }
        my $out = $min;
        $out =~ s/_/$hour/;
        $out =~ s/\./$hour_special/;
        $out =~ s/\^/$hour_up/;
        $out =~ s/\-//g;
        if (length $out >= 19) {
            push @long, $out;
        }
        $lengths[length $out]++;
        foreach (split //, $out) { $letters{$_} = undef; }
        $out =~ s/^(.?.?.?.?)(.?.?.?.?)(.?.?.?.?)(.?.?.?.?)/$1\n$2\n$3\n$4\n\n/;
#        $out =~ s/(.)/$segments{$1}/gs;
#        $out =~ s/ /0/gs;
#        $out =~ s/[^0]/1/gs;
        $out .= "\n";
        print $out;
    }
}

print "\n\n";
print "$_\n" foreach @long;

#print "\n\n";
#print "    $_\n" foreach sort keys %letters;

#print "\n\n";
#foreach (0..$#lengths) {
#    next unless defined $lengths[$_];
#    print "$_ : $lengths[$_]\n";
#}

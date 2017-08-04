#!/bin/env perl

use strict;
use warnings;
use v5.14;
use List::Util qw(sum);
use Getopt::Long;
use Term::ProgressBar;

my $debug       = 0;
my $doors       = 3;
my $num_to_show = 1;
my $iterations  = 100000;
GetOptions(
    'debug|g'        => \$debug,
    'doors|d=i'      => \$doors,
    'show|s=i'       => \$num_to_show,
    'iterations|i=i' => \$iterations,
);

say "Total Doors: $doors";
say "Doors to Show: $num_to_show";
say "Simulation Iterations: $iterations\n";

my @switched = ();
my @stayed   = ();

my $p = Term::ProgressBar->new({ 'count' => $iterations });
foreach ( 1 .. $iterations ) {
    my $car  = pick_random($doors);
    $debug && say "Car Is Behind: $car";
    my $orig_pick = pick_random($doors);
    $debug && say "Original Pick: $orig_pick";
    my @show = ();
    foreach ( 1 .. $num_to_show ) {
        push @show, pick_random($doors, $car, $orig_pick, @show);
    }
    @show = sort { $a <=> $b } @show;
    $debug && say "Showed Doors:  ".join(' ',@show);
    my $pick = $orig_pick;
    if (int(rand(1)+0.5)) {
        $pick = pick_random($doors, $orig_pick, @show);
        $debug && say "Switched to:   $pick";
    }
    my $result = ($pick == $car) ? 1 : 0;
    $debug && say "Result:        ".( $result ? 'Win' : 'Lose ')."\n";
    if ($pick != $orig_pick) { push @switched, $result; }
    else { push @stayed, $result; }
    $p->update($_);
}

say "Number of times switched: ".scalar(@switched);
say "Number of times stayed:   ".scalar(@stayed)."\n";

say sprintf 'Switched Success: %0.1f%%', ((sum(@switched)/scalar(@switched))*100);
say sprintf 'Stayed Success:   %0.1f%%', ((sum(@stayed)  /scalar(@stayed)  )*100);

sub pick_random {
    my $limit = shift;
    my %exclude = map { $_ => undef } @_;
    my $num;
    do { $num = int( rand($limit)+1 ) } while exists($exclude{$num});
    return $num;
} 

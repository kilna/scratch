#!/usr/bin/perl

print foreach sort {
    my $cmp = length($a) <=> length($b);
    $cmp && return $cmp;
    $a cmp $b;
} <>;

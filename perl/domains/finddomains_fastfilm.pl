#!/usr/bin/perl -w

use Net::Whois::Raw;
use Data::Dumper;

$|++;

sub template_sort (@) {
  return sort {
    my $val = length($a) <=> length($b);
    $val && return $val;
    my ($a2, $b2) = ($a, $b);
    $a2 =~ s/\*//; $b2 =~ s/\*//;
    return $a2 cmp $b2;
  } @_;
}

my @templates = qw(
  pic* *pic
  cut* *cut
  cine* *cine
  film* *film
  flick* *flick
  silver* *silver
  screen* *screen
  cimena* *cinema
  picture* *picture
);

#@templates = template_sort qw(
#);

my @words = qw(
  hot
  fly
  run
  cut
  rush
  fast
  game
  dart
  jump
  race
  dash
  snap
  swift
  quick
  flash
  crazy
  hurry
  rapid
  short
  speed
  chase
  fight
  sport
  streak
  runner
  sprint
  express
  challenge
);

my @tlds = qw(
  .com
);

my @out = ();

foreach my $word (@words)
{
  foreach my $template (@templates)
  {
    foreach my $tld (@tlds)
    {
      my $dom = $template;
      $dom =~ s/\*/$word/gs;
      $dom .= $tld;
      check($dom);
    }
  }
}

sub check {
  my $dom = shift;
#  print STDERR "$dom\n";
  my $result = whois($dom);
  if ($result =~ m/No match for/gis)
  {
    print "$dom\n";
  }
#  print $result;
#  exit;
}


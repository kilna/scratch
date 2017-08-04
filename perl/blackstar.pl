#!/usr/bin/perl 

use warnings;
use strict;

my @seq = (
  '00101',
  '11111',
  '11010',
  '10110',
  '01101',
  '00111',
);

foreach my $invert ( 0, 1 ) {
  foreach my $reverse ( 0, 1 ) {
    foreach my $rotate ( ( 0, 1, 2, 3, 4 ) ) {
      foreach my $add ( 32..96 ) { 
        run( $invert, $rotate, $reverse, $add, @seq );
      }
    }
  }
}

sub run {

  my ($invert, $rotate, $reverse, $add, @seq) = @_;

  # invert 1/1
  if ($invert) {
    @seq = map { s/0/x/gs; s/1/0/gs; s/x/1/gs; $_ } @seq;
  }

  # rotate
  if ($rotate){
    @seq = map { substr($_,$rotate).substr($_,0,$rotate) } @seq;
  }

  # reverse
  if ($reverse) {
    @seq = map { $_ = reverse $_; $_ } @seq; 
  }

  # Convert to numbers
  @seq = map { unpack("N", pack("B32", substr("0" x 32 . $_, -32))); } @seq;

  # add
  if ($add) {
    @seq = map { $_ + $add } @seq;
  }

  print "i:$invert r:$rotate R:$reverse a:$add > ";
  print "$_ " foreach @seq;
  print "> ";
  print chr($_) foreach @seq;
  print "\n";

}


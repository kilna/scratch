#!/bin/env perl

use strict;
use warnings;
use v5.10;

package Position;
use Finance::YahooQuote;
use Text::xSV::Slurp 'xsv_slurp';
use Moo;

my %yq_fields = qw(
    name 1
    price 2
    range 13
);

my @fields     = qw(id market symbol shares buy buy_ts sell sell_ts max fees);
my %field_nums = map { $fields[$_] => $_ } 0..$#fields;

has market  => ( is => 'ro' );
has symbol  => ( is => 'ro' );
has shares  => ( is => 'ro' );
has buy     => ( is => 'ro' );
has buy_ts  => ( is => 'ro' );
has sell    => ( is => 'ro' );
has sell_ts => ( is => 'ro', default => sub { return '' } );
has high    => ( is => 'rw' );
has low     => ( is => 'rw' );
has fees    => ( is => 'ro', default => sub { return 10 } );

sub all {
    my $class = shift;
    return map { Position->new( %$_ ) } @{xsv_slurp( 'positions.csv' )};
}

sub profit {
    my $self = shift;
    if ($self->sell) {
        return ($self->sell - $self->buy) * $self->shares;
    }
    else {
        return ($self->price - $self->buy) * $self->shares;
    }
}

sub quote {
    my $self = shift;
    if (not defined $self->{'quote'}) {
		$self->{'quote'} = getonequote lc($self->symbol);
    }
    return $self->{'quote'};
}

sub name      { shift->quote->[$yq_fields{'name'}] }
sub price     { shift->quote->[$yq_fields{'price'}] }
sub range     { split ' - ', shift->quote->[$yq_fields{'range'}] }
sub day_low   { (shift->range)[0] }
sub day_high  { (shift->range)[1] }

sub save {
    my $self = shift;
    
}

sub url {
    my $self = shift;
    return 'http://finance.google.com/finance?q=' . $self->market . ':' . $self->symbol;
}

sub dump {
    my $self = shift;
    use Data::Dumper;
    return Data::Dumper->Dump([$self],[lc($self->symbol)]);
}



package main;

my $total = 0;

foreach my $pos (Positions->all) {
    say $pos->dump;
    say $pos->symbol . " ". $pos->profit . '   ' . $pos->url;
    $total += $pos->profit;
}

say "Total: ".$total;

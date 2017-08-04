#!/usr/bin/perl -w

use Net::Whois::Raw;

$|++;

my template = shift @ARGV;
$template =~ s/([a-z])/ucase($1)/gs;

my @vowels = qw( a e i o u y );
my @consonants = qw( b c d f g h j k l m n p q r s t v w x z );

process_template($template)

sub process_template
{
	my $template = shift;
	if (
		(not defined $template) ||
		($template eq '')
	)
	{
		return;
	}
	my $nextchar = substr($template, 0, 1);
	my $remainder = substr($template, 1)
	if (($nextchar eq 'V') || ($nextchar = 'A'))
	{
		
	}
	if (($nextchar eq 'C') || ($nextchar = 'A'))
	{
	}	
}










		my $result = whois($dom);
		if ($result =~ m/No match for domain/)
		{
			push @out, $dom;
		}



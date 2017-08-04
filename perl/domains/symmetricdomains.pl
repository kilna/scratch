#!/usr/bin/perl

use Net::Whois::Raw;
use Data::Dumper;
use Getopt::Long;
use Carp;

my $file = '';
my $debug = 0;

GetOptions(
	'file|f=s' => \$file,
	'debug|d'  => \$debug,
);

$|++;

my %flips = (
	'a' => ['v'],
	'b' => ['q','9'],
	'c' => ['d'],
	'd' => ['p','g','c'],
	'e' => ['3'],
	'f' => ['j'],
	'g' => ['d'],
	'h' => ['h','y','4'],
	'i' => ['i'],
	'j' => ['f'],
	'l' => ['7'],
	'm' => ['w'],
	'n' => ['u','n'],
	'o' => ['o'],
	'p' => ['d'],
	'q' => ['b','6','0'],
	's' => ['s','5'],
	't' => ['t'],
	'u' => ['n'],
	'v' => ['a'],
	'w' => ['m'],
	'x' => ['x'],
	'y' => ['h'],
	'z' => ['z'],
	'0' => ['q','0'],
	'3' => ['e'],
	'4' => ['h'],
	'5' => ['s','5'],
	'6' => ['9','q'],
	'7' => ['l'],
	'8' => ['8'],
	'9' => ['6','b'],
);

my %self_flips = map { $_ => undef } qw( z n o h s x i 0 5 );

my %vowels = map { $_ => undef } qw(a e i o u y);

my %consonants = map { $_ => undef } qw(b c d f g h j k l m n p q r s t v w x z);

my %numbers = map { $_ => undef } qw(0 1 2 3 4 5 6 7 8 9);

my @tlds = qw( .com );

my @templates = qw(
	vvvv
	cvvv
	vcvv
	ccvv
	vvcv
	cvcv
	vccv
	cccv
	vvvc
	cvvc
	vcvc
	ccvc
	vvcc
	cvcc
	vccc
	cccc
	vvvvv
	cvvvv
	vcvvv
	vvcvv
	vvvcv
	vvvvc
	ccvvv
	vccvv
	vvccv
	vvvcc
	cvcvv
	vcvcv
	vvcvc
	cvcvc
	cvvvc
	cvvcv
	cvcvv
	cvccvc
	vcvvcv
);


$debug && print Data::Dumper->Dump([\@templates],['templates']);

my @out = ();
foreach my $template (@templates)
{
	print "\n$template\n";;
	next if ($template =~ m/!/);
	
	my @chars = split '', $template;
	my @before = @chars[0 .. int(($#chars-1) / 2)];
	my $middle = ( $#chars % 2 ) ? '' : $chars[int( scalar(@chars) / 2 )];
	my @after  = reverse @chars[(int( $#chars / 2 ) + 1) .. $#chars];
	
	my @words = $middle ? self_flips_of_type($middle) : ('');
	
	$debug && print Data::Dumper->Dump([\$middle],['middle']);
	$debug && print Data::Dumper->Dump([\@before],['before']);
	$debug && print Data::Dumper->Dump([\@after],['after']);
	$debug && print Data::Dumper->Dump([\@words],['words']);

	while (scalar @before)
	{
		my $before_type = shift @before;
		my $after_type = shift @after;
		my @words_orig = @words;
		@words = ();
		my @pairs = flip_type_pairs( $before_type, $after_type );
		while (scalar @pairs)
		{
			my $before_char = shift @pairs;
			my $after_char = shift @pairs;
			foreach my $word (@words_orig)
			{
				push @words, $before_char.$word.$after_char;
			}
		}
	}
	
	$debug && print Data::Dumper->Dump([\@words],['words']);

	foreach my $tld (@tlds)
	{
		foreach my $word (@words)
		{
			my $result = whois($word.$tld);
			if ($result =~ m/No match for/)
			{
				push @out, $word.$tld;
				print $word.$tld."\n";
			}
		}
	}
}

if ($file)
{
	open $FILE, '>', $file || die "Unable to open file $file: $!\n";
	foreach (sort { length($a) <=> length($b) || $a cmp $b } @out)
	{
		print $FILE "$_\n";
	}
	close $FILE;
}

sub type_of_char
{
	my $char = lc(shift);
	if    (exists $vowels{$char})     { return 'v'; }
	elsif (exists $consonants{$char}) { return 'c'; }
	elsif (exists $numbers{$char})    { return '#'; }
	confess "Unknown type for char '$char'";
}

sub char_is_of_type
{
	my $char = lc(shift);
	my $type = shift;
	if    ($type eq 'v') { return exists $vowels{$char}     }
	elsif ($type eq 'c') { return exists $consonants{$char} }
	elsif ($type eq '#') { return exists $numbers{$char}    }
	confess "Unknown type '$type'!";
}

sub flip_of_type_for_char
{
	my $char = lc(shift);
	my $type = shift;
	return unless defined($flips{$char});
	return grep { char_is_of_type($_, $type) } @{$flips{$char}}
}

sub self_flips_of_type
{
	my $type = shift;
	return  grep { char_is_of_type($_, $type) } keys %self_flips;
}

sub flip_type_pairs
{
	my $type1 = shift;
	my $type2 = shift;

	my @pairs = ();
	foreach my $char1 (keys %flips)
	{
		next unless char_is_of_type($char1, $type1);
		foreach my $char2 (@{$flips{$char1}})
		{
			next unless char_is_of_type($char2, $type2);
			push @pairs, $char1, $char2;
		}
	}
	
	return @pairs;
}



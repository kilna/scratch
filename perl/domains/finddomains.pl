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
    *planet
	planet*
	*site
	*city
	*town
	*central
	*space
	space*
	cyber*
	*time
	*blast
	*party
	*blaster
	*licious
	good*
	*store
	buy*
	*heaven
	*street
	killer*
	top*
	*house
	*zap
	zap*
	*brain
	*head
	pop*
	*pop
	thunder*
	lightning*
	*farm
	*land
	*buddy
	*friend
	*spot
	*lane
	*place
	*way
);

@templates = template_sort qw(
	*
	e*
	i*
	v*
	k*
	x*
	*x
	z*
	*z
    u*
	*y
    xy*
    zy*
    ky*
    kry*
    kryo*
    cryo*
	*nexus
	*star
	*matic
	micro*
	mega*
	neo*
    new*
    neu*
	buzz*
	*buzz
	*zone
    zone*
	go*
	*blitz
	*eye
	boom*
	*boom
	*storm
	*beat
	*ex
	*burst
	*jump
	zip*
	snap*
	*snap
	*pad
	*station
	*sphere
	*point
	*post
	*box
	*soft
    *kor
    *kore
    *lix
    *lex
    *kan
    *kon
    *nex
    *us
    *plex
    *plix
    *tex
    *tix
    *trix
    mod*
    *mod
    inter*
    opti*
    syn*
    psy*
    sim*
    *lex
    *nix
    *nex
    nex*
    para*
    *dox
    opt*
    xen*
    *xen
    kor*
    *ex
    *x
    multi*
    uber*
    *r
    *er
    *ur
    *ix
    *nux
    uni*
    un*
    ze*
    *ez
    key*
    *key
    *uze
    *fuze
    *ika
    *ica
    *iq
    *ir
    star*
    midi*
    *midi
    nano*
    mini*
    *nano
    *mini
    *ka
    ka*
    xi*
    *borg
    *org
    kord*
    *kord
    *board
    *bord
    oxy*
    kyx*
    *kyx
    *yx
    *yz
    *no
    vi*
    ya*
    *ha
    *io
    ko*
    kas*
    *1
    *3
    *4
    *5
    *6
    *7
    *8
    *9
    *pro
    *kai
    *ger
    *audio
    aud*
    *sis
    *sys
    *synth
    synth*
    *haus
    nov*
    nova*
    *tech
    *tek
    *iom
    *ian
    *log
    *alog
    *ator
    *ilator
    *trol
    *tron
    elec*
    elek*
    *tz
    *s
    *rox
    *tron
    *tronix
    *tronics
    nu*
    *ius
    *ious
    *iax
    *cube
    cube*
    digi*
    *digital
    fire*
    *fire
    *ology
    *ware
    *tec
    robo*
    *bot
    source*
    *source
    *ate
    *ify
    *ity
    *ium
    *ize
    *izer
    *azor
    *one
    *master
    *ido
    *ito
    *ox
    *le
    *ce
    *ser
    *zer
);

my @words = qw(
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
if (not scalar @words) {
    my @post = map { m/^\*(.*)$/; $1 }
        grep { m/^\*(.*)$/ } @templates;
    my @pre = map { m/^(.*)\*$/; $1 }
        grep { m/^(.*)\*$/ } @templates;
    foreach my $pre (@pre) {
        foreach my $post (@post) {
            foreach my $tld (@tlds) {
                check("$pre$post$tld");
            }
        }
    }
}

sub check {
    my $dom = shift;
    print STDERR "$dom\n";
    my $result = whois($dom);
	if ($result =~ m/No match for/)
	{
        print "$dom\n";
	}
    if ($dom =~ m/(.)\1/) {
        $dom =~ s/((.)\2+)/$2/gs;
        print STDERR "$dom\n";
        $result = whois($dom);
        if ($result =~ m/No match for/) {
            print "$dom\n";                
        }
    }
}

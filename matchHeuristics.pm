#!/usr/bin/env perl
# matchHeuristics.pm -- Heuristic functions for match.pl.

package matchHeuristics;

use Modern::Perl 2013;
use autodie;
use Data::Dumper;

use Exporter;
our @ISA = ("Exporter");
our @EXPORT = qw(&extendedModelPattern &allowSuffix &doesMatch);

#use constant PROD_TYPE_CAMERA => 0;
#use constant PROD_TYPE_ACCESSORY => 1;
#use constant PROD_TYPE_UNKNOWN => 2;
#use constant TEST_MODE => 0;

#use constant DATA_PRODUCTS_TEXT => "data/products.txt";
#use constant DATA_LISTINGS_TEXT => "data/listings.txt";
#use constant RESULTS_TEXT => "results.txt";

# doesMatch() -- Apply heuristics to determine whether given listing entry
# matches given product entry.
# Precondition:  match on manufacturer has already been confirmed.
sub doesMatch
{
    my ( $prod, $lstg ) = @_;
    my $ok = 1;
    #my $family_ok = 1; # Whether family is ignored in description is kind of fuzzy.
    #if ( exists($prod->{family}) )
    #{
    #    my $pat = "$prod->{family}";
    #    $family_ok = 0  unless ( $lstg->{title} =~ m/\b$pat\b/ );
    #    #say "pat 0 ($pat), family_ok==$family_ok";
    #}
    if ( exists($prod->{model}) )
    {
        my $pat = "$prod->{model}";
        my @pat_list = split(m/[_ -]/, $pat);
        #say "pat_list==(@pat_list)";
        if ( @pat_list==1 )
        {
            $pat = extendedModelPattern($pat);
            $ok = 0  unless ( $lstg->{title} =~ m/\b$pat\b/i );
            #say "pat 3 ($pat):  ok==$ok";
        }
        else
        {
            #say "Going in:  ok==$ok";
            foreach my $pt ( @pat_list )
            {
                my $p = extendedModelPattern($pt);
                if ( $p =~ m/\d$/ )
                {
                    $ok = 0  unless ( $lstg->{title} =~ m/$p\D/i or $lstg->{title} =~ m/$p$/i );
                    #say "match a:  ok==$ok";
                }
                elsif ( $p =~ m/[[:alpha:]]+$/ )
                {
                    $ok = 0  unless ( $lstg->{title} =~ m/\b$p\w*/i );
                    #say "match b:  ok==$ok";
                }
                else
                {
                    $ok = 0  unless ( $lstg->{title} =~ m/\b$p\b/i );
                    #say "match c:  ok==$ok";
                }
                #say "p 3 ($p), ok==$ok";
                #say "title==($lstg->{title})";
            }
            if ( !$ok )
            {
                my $pt = join('', @pat_list);
                $ok = 1  if ( $lstg->{title} =~ m/\b$pt\b/i );
            }
        }
    }
    return $ok;
}


# extendedModelPattern() -- Utility to expand camera model string to one that
# matches a suffix context.
sub extendedModelPattern
{
    my ( $pat ) = @_;
    if ( $pat =~ m/^(.*)([[:alpha:]])[- _]*(\d)(.*)/ )
    {
        $pat = $1 . $2 . "[- _]*" . $3 . $4;
    }
    return $pat;
}


# allowSuffix():  Determine answer to following question for given
# manufacturer.
# Question:
# Should suffix be allowed as same model?
# For some manufacturers, the answer is yes.  For example, the Sony DSC-T99/B
# or DSC-T99B appears to be just a later minor edition of the T99, whereas
# for Nikon you get a D300S, which is definitely a different camera model
# from the D300.
sub allowSuffix
{
    my ( $manufacturer ) = @_;
    return ($manufacturer =~ m/sony/i) ? 1 : 0;
}

1;

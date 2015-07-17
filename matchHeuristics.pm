#!/usr/bin/env perl
# matchHeuristics.pm -- Heuristic functions for match.pl.

package matchHeuristics;

use Modern::Perl 2013;
use autodie;
use Data::Dumper;

use Exporter;
our @ISA = ("Exporter");
our @EXPORT = qw(&extendedModelPattern &allowSuffix &doesMatch &createManufacturerMapping
                 &prodSystemInit &prodSystemTrackProduct &prodSystemMapManufListings
                 &prodSystemListingBestMatch &parseExpressionFromProdField
                 &applyParseExpression);

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
    my $family_ok = 1; # Whether family is ignored in description is kind of fuzzy.
    if ( exists($prod->{family}) )
    {
        my $pat = "$prod->{family}";
        $family_ok = 0  unless ( $lstg->{title} =~ m/\b$pat\b/ );
        #say "pat 0 ($pat), family_ok==$family_ok";
    }
    if ( exists($prod->{model}) )
    {
        if ( $lstg->{title} =~ m/(.*)batter/i and not $1 =~ m/[kc]amera/i ) # review
        {
            $ok = 0;
        }
        if ( $ok )
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
                say "Going in:  ok==$ok, pat_list==(@pat_list)";
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
                    next  if ( not $ok );
                    #say "p 3 ($p), ok==$ok";
                    #say "title==($lstg->{title})";
                }
                if ( not $ok )
                {
                    my $pt = join('', @pat_list);
                    $ok = 1  if ( $lstg->{title} =~ m/\b$pt\b/i );
                }
            }
        }
    }
    $ok = 0  if ( not $family_ok and exists($prod->{family}) and familyImportant($prod->{manufacturer}) );
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

# Examples:
# Against these products:
#   { product_name => "Nikon_D300", manufacturer => "Nikon", model => "D300", "announced-date" => "2009-07-29T20:00:00.000-04:00"},
#
# Match these listings and pick the best fit for each:
#   { title => "Nikon D300 DX 12.3MP Digital SLR Camera with 18-135mm AF-S DX f/3.5-5.6G ED-IF Nikkor Zoom Lens", manufacturer => "Nikon", currency => "USD", price => 2899.98});
#   { title => "Nikon D3000 10.2MP Digital SLR Camera Kit (Body) with WSP Mini Tripod & Cleaning set.", manufacturer => "Nikon", currency => "USD", price => 499.95});
#   { title => "Nikon D300s 12.3mp Digital SLR Camera with 3inch LCD Display (Includes Manufacturer's Supplied Accessories) with Nikon Af-s Vr Zoom-nikkor 70-300mm F/4.5-5.6g If-ed Lens + PRO Shooter Package Including Dedicated I-ttl Digital Flash + OFF Camera Flash Shoe Cord + 16gb Sdhc Memory Card + Wide Angle Lens + Telephoto Lens + Filter Kit + 2x Extended Life Batteries + Ac-dc Rapid Charger + Soft Carrying Case + Tripod & Much More !!", manufacturer => "Digital", currency => "USD", price => 2094.99});

sub allowSuffix
{
    my ( $manufacturer ) = @_;
    return ($manufacturer =~ m/sony/i) ? 1 : 0;
}


# createManufacturerMapping() -- Take list of product manufacturer values, and
# list of listing manufacturer values.  Figure out which manufacturer names in
# the listings correspond to which manufacturer names in the products.  Return
# hash reference giving this mapping:  input listing manufacturer name, get
# back product manufacturer name.
# Parameters:
#   prod_mfg_keys:  list reference of product manufacturer fields
#   lstg_mfg_keys:  list reference of listing manufacturer fields
#
# Explanation:
# Product records will have manufacturer names like "Canon" or "Nikon".
# Listing records will have manufacturer names like "Canon Canada" or
# "Nikon PLC".
# This function applies simple string indexing rule to match them, and keeps
# results in map.
sub createManufacturerMapping
{
    my ($prod_mfg_keys, $lstg_mfg_keys) = @_;
    my $manuf_re_str = "";
    for ( my $i = 0;  $i<@$prod_mfg_keys;  ++$i )
    {
        my $m = $prod_mfg_keys->[$i];
        $manuf_re_str .= "(^$m)";
        $manuf_re_str .= "|"  if ( $i<@$prod_mfg_keys-1 );
    }
    my $manuf_re = qr/$manuf_re_str/i;
    my %mapping;
    foreach my $lstg ( @$lstg_mfg_keys )
    {
        my $prod_name = $lstg;
        if ( $prod_name =~ $manuf_re )
        {
            my $w = -1;
            foreach my $min (1..$#-)
            {
                if ( defined($-[$min]) )
                {
                    $w = $min;
                    last;
                }
            }
            if ( $w>0 )
            {
                $prod_name = $prod_mfg_keys->[$w-1];
            }
        }
        $mapping{$lstg} = $prod_name;
    }
    return \%mapping;
}


sub createManufacturerMapping_Orig
{
    my ($prod_mfg_keys, $lstg_mfg_keys) = @_;
    my %mapping;
    foreach my $lstg ( @$lstg_mfg_keys )
    {
        my $prod_name = $lstg;
        foreach my $prod ( @$prod_mfg_keys )
        {
            #$prod_name = $prod  if ( index($lstg, $prod)>=0 );
            if ( $lstg =~ m/^$prod/i )
            {
                $prod_name = $prod;
                next;
            }
        }
        $mapping{$lstg} = $prod_name;
    }
    return \%mapping;
}


sub familyImportant
{
    my ( $manufacturer ) = @_;
    return ($manufacturer =~ m/canon/i or
            $manufacturer =~ m/pentax/i) ? 1 : 0;
}


sub prodSystemInit
{
    my $prod_struct = { manuf_division => {} };
    return $prod_struct;
}


sub prodSystemMapManufListings
{
    my ( $prod_struct, $products, $listings ) = @_;
    my @product_keys;
    foreach my $prod ( @$products )
    {
        push(@product_keys, $prod->{manufacturer});
    }
    my @listing_keys;
    foreach my $list ( @$listings )
    {
        push(@listing_keys, $list->{manufacturer});
    }
    $prod_struct->{manuf_map} = createManufacturerMapping(\@product_keys, \@listing_keys);
}


sub prodSystemTrackProduct
{
    my ( $prod_struct, $prod ) = @_;
    my $manuf_division = $prod_struct->{manuf_division};
    my $manuf = $prod->{manufacturer};
    my $model_pe = parseExpressionFromProdField($prod->{model}, 0);
    $prod->{model_pe} = $model_pe;
    $prod->{model_re} = qr/$model_pe/i;
    if ( exists($prod->{family}) )
    {
        my $family_pe = parseExpressionFromProdField($prod->{family}, 0);
        $prod->{family_pe} = $family_pe;
        $prod->{family_re} = qr/$family_pe/i;
    }
    if ( exists($manuf_division->{$manuf}) )
    {
        my $prod_list = $manuf_division->{$manuf};
        push(@$prod_list, $prod);
    }
    else
    {
        $manuf_division->{$manuf} = [$prod];
    }
}


sub prodSystemListingBestMatch
{
    my ( $prod_struct, $listing ) = @_;
    #print Dumper($prod_struct);
    my ( $prod_ind, $match_strength ) = ( -1, 0 );
    my $manuf = $listing->{manufacturer};
    #say "no manuf a"  unless ( defined($manuf) );
    my $manuf_map = $prod_struct->{manuf_map};
    my $old_manuf = $manuf;
    $manuf = $manuf_map->{$manuf}; # map to product manuf name
    #say "no manuf b"  unless ( defined($manuf) );
    #say "using manuf==($manuf) from ($old_manuf)";
    my $product_list = $prod_struct->{manuf_division}{$manuf};
    if ( defined($manuf) and defined($product_list) )
    {
        for ( my $i = 0;  $i<@$product_list;  ++$i )
        {
            my $strength = matchListingProduct($listing, $product_list->[$i] );
            #say "trying product $i:  strength==$strength";
            ($prod_ind, $match_strength ) = ( $i, $strength )  if ( $strength>$match_strength );
        }
    }
    my $prod = undef;
    $prod = $product_list->[$prod_ind]  if ( $prod_ind>=0 );
    return ( $prod, (not defined($manuf)) );
}


# $listing is the basic listing structure from json
# $product is the basic product structure from json
sub matchListingProduct
{
    my ($listing, $product ) = @_;
    my $stren = 0;
    #my $model_pe = parseExpressionFromProdField($product->{model}, 0);
    my $manuf = $product->{manufacturer};
    #my $model_pe = parseExpressionFromProdField($product->{model},
    #        allowSuffix($manuf));
    #my $model_pe = parseExpressionFromProdField($product->{model}, 0);
    #say "trying parse expr for model ($model_pe) and title ($listing->{title})";
    #my $model_match_len = applyParseExpression($product->{model_pe}, $listing->{title});
    my $model_match_len = applyParseRE($product->{model_re}, $listing->{title});
    my $family_match_len = 0;
    # TODO  Possibly call familyImportant() here;  tweaking issue
    if ( $model_match_len>0 && exists($product->{family_re}) )
    {
        #my $family_pe = parseExpressionFromProdField($product->{family}, 0);
        #my $family_pe = parseExpressionFromProdField($product->{family}, 0);
        #my $family_pe = parseExpressionFromProdField($product->{family},
        #        allowSuffix($manuf));
        #$family_match_len = applyParseExpression($product->{family_pe}, $listing->{title});
        $family_match_len = applyParseRE($product->{family_re}, $listing->{title});
    }
    $stren = computeMatchStrength($model_match_len, $family_match_len);
    return $stren;
}


# parseExpressionFromProdField() -- Generate parse expression from field.
# Parameters:
#   $field:  field for which to build matching expression
#   $allow_letter_suffix:  option whether letter suffix such as "D" can be
#   allowed after numeric field
# Return value:
#   String representing parse expression that can be used in regex to match
#   appropriate values from a listing.
# Details:
#   A product name such as "Nikon_D300" might be matched against a listing
#   title such as (a)
#   "Nikon D3000 10.2MP Digital SLR Camera Kit (Body) with WSP Mini Tripod & Cleaning set."
#   or against a different listing title such as (b)
#   "Nikon D300 DX 12.3MP Digital SLR Camera with 18-135mm AF-S DX f/3.5-5.6G ED-IF Nikkor Zoom Lens"
#   or against another such as (c)
#   "Nikon D300s 12.3mp Digital SLR Camera with 3inch LCD Display (Includes Manufacturer's Supplied Accessories) with Nikon Af-s Vr Zoom-nikkor 70-300mm F/4.5-5.6g If-ed Lens + PRO Shooter Package Including Dedicated I-ttl Digital Flash + OFF Camera Flash Shoe Cord + 16gb Sdhc Memory Card + Wide Angle Lens + Telephoto Lens + Filter Kit + 2x Extended Life Batteries + Ac-dc Rapid Charger + Soft Carrying Case + Tripod & Much More !!"
#   In reality it should match (a) but not (b) or (c).
#   First of all we have to take the "Nikon_D300" and split on the separator
#   "_" and combine the two sub-fields "Nikon" and "D300" with a universal
#   separator in between that might match different reasonable separators in a
#   listing title such as whitespace or hyphen or underscore or colon.
#   Second, we have to be mindful of matching the "D300" against "D300" or "d300"
#   but not "a300" or "D3000" or "d300s".
sub parseExpressionFromProdField
{
    my ( $field, $allow_letter_suffix ) = @_;
    my $pe = "";
    my @field_list = split(m/_|-|:|\s/, $field);
    my @mod_field_list;
    foreach my $f ( @field_list )
    {
        #if ( $allow_letter_suffix )
        #{
        #    $f .= "[A-Za-z]?"  if ( $f =~ m/\d+$/ );
        #}
        #else
        #{
        #    $f .= "\\b"  if ( $f =~ m/\d+$/ );
        #}
        if ( $f =~ m/^(.*[a-zA-Z])([0-9].*)$/ )
        {
            push(@mod_field_list, $1);
            push(@mod_field_list, $2);
        }
        else
        {
            push(@mod_field_list, $f);
        }
    }
    #$pe = join("[_ -:]+", @mod_field_list);
    #$pe = join("\\[_ -:\\]+", @mod_field_list);
    #$pe = join("\\[_ -\\]+", @mod_field_list);
    for ( my $i = 0;  $i<@mod_field_list;  ++$i )
    {
        my $f = $mod_field_list[$i];
        if ( $i>0 )
        {
            #$f = "([_ -:]+$f)?";
            #$f = "([_ -:]*$f)?";
            $f = "([_ -:]*$f)";
        }
        $pe .= $f;
    }
    return $pe;
}


# applyParseExpression() -- Apply parse expression from
# parseExpressionFromProdField(), to string.  Return 0 if nothing matched,
# or length of match if it did match.
sub applyParseExpression
{
    my ( $pe, $str ) = @_;
    my $len = 0;
    $len = length($&)  if ( $str =~ m/$pe/i);
    return $len;
}


sub applyParseRE
{
    my ( $re, $str ) = @_;
    my $len = 0;
    $len = length($&)  if ( $str =~ $re);
    return $len;
}


sub computeMatchStrength
{
    my ( $model_len, $family_len ) = @_;
    return 1000*$model_len+$family_len;
}


1;

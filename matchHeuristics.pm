#!/usr/bin/env perl
# matchHeuristics.pm -- Heuristic functions for match.pl.

package matchHeuristics;

use Modern::Perl 2013;
use autodie;
use Data::Dumper;

use Exporter;
our @ISA = ("Exporter");
our @EXPORT = qw(&prodSystemInit &prodSystemTrackProduct &prodSystemMapManufListings
                 &prodSystemTrackProductList
                 &prodSystemListingBestMatch &parseExpressionFromProdField
                 applyParseRE);

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
        #say "added family_re for ($prod->{family})";
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


sub prodSystemTrackProductList
{
    my ($prod_struct, $prod_list) = @_;
    my %prod_name_used;
    foreach my $prod ( @$prod_list )
    {
        prodSystemTrackProduct($prod_struct, $prod);
        if ( exists($prod_name_used{$prod->{product_name}}) )
        {
            die "Duplicate product name $prod->{product_name}";
        }
        $prod_name_used{$prod->{product_name}} = 1;
    }
}


sub prodSystemListingBestMatch
{
    my ( $prod_struct, $listing ) = @_;
    #print Dumper($prod_struct);
    my $match_strength = 0;
    my $manuf = $listing->{manufacturer};
    my $manuf_map = $prod_struct->{manuf_map};
    $manuf = $manuf_map->{$manuf}; # map to product manuf name
    my $prod = undef;
    if ( defined($manuf) )
    {
        my $product_list = $prod_struct->{manuf_division}{$manuf};
        #my $smat = 0;
        my @prod_ind_list;
        if ( defined($manuf) and defined($product_list) )
        {
            for ( my $i = 0;  $i<@$product_list;  ++$i )
            {
                my $strength = matchListingProduct($listing, $product_list->[$i] );
                #say "trying product $i:  strength==$strength";
                if ( $strength>$match_strength )
                {
                    $match_strength = $strength;
                    #push(@prod_ind_list, $i);
                    #++$smat;
                    @prod_ind_list = ( $i ); # clear out old list of lower strength
                    #say "pushing (first) $i ($product_list->[$i]{product_name}) with strength $strength";
                }
                elsif ( $strength>0 and $strength==$match_strength )
                {
                    #say "strength matches";
                    #++$smat;
                    push(@prod_ind_list, $i);
                    #say "pushing $i ($product_list->[$i]{product_name}) with strength $strength";
                }
            }
        }
        #say "smat==$smat";
        #my $prod = undef;
        #$prod = $product_list->[$prod_ind]  if ( $prod_ind>=0 );
        $prod = getBestProd($product_list, \@prod_ind_list);
    }
    return ( $prod, (not defined($manuf)) );
}


use constant MAX_PRODUCT_COMPLEXITY => 999_999_999;

sub getBestProd
{
    my ($product_list, $prod_ind_list) = @_;
    my ( $prod, $max_prod_complexity, $min_prod_complexity ) = ( undef, 0, MAX_PRODUCT_COMPLEXITY );
    foreach my $i ( @$prod_ind_list )
    {
        #say "getBestProd() $i";
        my $p = $product_list->[$i];
        my $comp = productComplexity($p);
        #( $prod, $min_prod_complexity ) = ( $p, $comp )  if ( $comp<$min_prod_complexity );
        ( $prod, $max_prod_complexity ) = ( $p, $comp )  if ( $comp>$max_prod_complexity );
    }
    return $prod;
}


sub productComplexity
{
    my ( $prod ) = @_;
    my $comp = 1000*length($prod->{model});
    $comp += length($prod->{family})  if ( exists($prod->{family}) );
    return $comp;
}


# $listing is the basic listing structure from json
# $product is the basic product structure from json
sub matchListingProduct
{
    my ($listing, $product ) = @_;
    my $stren = 0;
    my $model_match_len = applyParseRE($product->{model_re}, $listing->{title});
    my $family_match_len = 0;
    if ( $model_match_len>0 && exists($product->{family_re}) )
    {
        $family_match_len = applyParseRE($product->{family_re}, $listing->{title});
    }
    #say "model==($product->{model}), model_pe==($product->{model_pe})"  if ( exists($product->{model}) );
    #say "model_match_len==$model_match_len, family_match_len==$family_match_len, title==($listing->{title})";
    #say "family==($product->{family}), family_pe==($product->{family_pe})"  if ( exists($product->{family}) );
    $stren = computeMatchStrength($model_match_len, $family_match_len);
    #say "  stren==$stren";
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
    #say "mod_field_list==(@mod_field_list)";
    for ( my $i = 0;  $i<@mod_field_list;  ++$i )
    {
        my $f = $mod_field_list[$i];
        if ( $i>0 )
        {
            #$f = "([_ -:]+$f)?";
            #$f = "([_ -:]*$f)?";
            if ( $f =~ m/^\d+$/ )
            {
                $f = "([_ -:]*(?<!\\d)$f(?!\\d))";
            }
            else
            {
                $f = "([_ -:]*$f)";
            }
        }
        elsif ( $i==0 and @mod_field_list>1 )
        {
            if ( $f =~ m/^\d+$/ )
            {
                $f = "((?<!\\d)$f(?!\\d))?";
            }
            else
            {
                $f = "($f)?";
            }
        }
        $pe .= $f;
    }
    return $pe;
}
# applyParseRE() -- Apply parse regex from parseExpressionFromProdField(),
# to string.  Return 0 if nothing matched, or length of match if it did match.
sub applyParseRE
{
    my ( $re, $str ) = @_;
    my $len = 0;
    if ( $str =~ $re)
    {
        $len = length($&);
        #say "    match is ($&)";
    }
    return $len;
}


# computeMatchStrength() -- Compute strength of match result.
# This is a basic heuristic against which matches are compared.
sub computeMatchStrength
{
    my ( $model_len, $family_len ) = @_;
    return 1000*$model_len+$family_len;
}


1;

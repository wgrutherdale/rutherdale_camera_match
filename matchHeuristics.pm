#!/usr/bin/env perl
# matchHeuristics.pm -- Heuristic functions for match.pl.

package matchHeuristics;

use Modern::Perl 2013;
use autodie;
use Data::Dumper;
use Time::HiRes qw/gettimeofday/;

#use Exporter;
#our @ISA = ("Exporter");
#our @EXPORT = qw(&prodSystemInit &prodSystemTrackProduct &prodSystemMapManufListings
#                 &prodSystemTrackProductList
#                 &prodSystemListingBestMatch &parseExpressionFromProdField
#                 applyParseRE);

# new() -- Constructor for matchHeuristics class.
sub new
{
    my $classname = shift;
    my $self = { };
    bless($self, $classname);
    $self->prodSystemInit(@_);
    return $self;
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


# prodSystemInit() -- Initialise basic structure for matchHeuristics.
sub prodSystemInit
{
    my $self = shift;
    $self->{manuf_division} = {};
}


# prodSystemMapManufListings() -- Do some initialisation of the matchHeuristics
# structure with products and listings.  This is intended to be run after the
# constructor.
# When this call has finished,
#   - all the products will be known and organised by manufacturer
#   - the mapping will be known between listing manufacturer names
#     and the corresponding product manufacturer names.
sub prodSystemMapManufListings
{
    my $self = shift;
    my ( $products, $listings ) = @_;
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
    $self->{manuf_map} = createManufacturerMapping(\@product_keys, \@listing_keys);
}


# prodSystemTrackProduct() -- Take an individual product and set up structures
# in the matchHeuristics object to have an organised representation of it.
# This includes extra pre-processed representation of search fields.
sub prodSystemTrackProduct
{
    my $self = shift;
    my ( $prod ) = @_;
    my $manuf_division = $self->{manuf_division};
    my $manuf = $prod->{manufacturer};
    my $product_name_pe = parseExpressionFromProdField($prod->{product_name}, 1);
    my $model_pe = parseExpressionFromProdField($prod->{model}, 0);
    $prod->{product_name_pe} = $product_name_pe;
    $prod->{product_name_re} = qr/$product_name_pe/i;
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


# prodSystemTrackProductList() -- Take a list of all products, and set them up
# fully in the matchHeuristics structure.  Also, prepare the results structure
# as an empty list for each product name, so it is ready for subsequent
# population with listings.
sub prodSystemTrackProductList
{
    my $self = shift;
    my ( $prod_list, $results ) = @_;
    my %prod_name_used;
    foreach my $prod ( @$prod_list )
    {
        $self->prodSystemTrackProduct($prod);
        if ( exists($prod_name_used{$prod->{product_name}}) )
        {
            die "Duplicate product name $prod->{product_name}";
        }
        if ( defined($results) )
        {
            $results->{$prod->{product_name}} = [];
        }
        $prod_name_used{$prod->{product_name}} = 1;
    }

    say "done prodSystemTrackProductList()";
}


# prodSystemListingBestMatch() -- Take the given listing and find the best
# match for it amongst all known product data.
# Parameter:
#   $listing:  listing structure
# Return values:
#   product reference, or undef if none found
#   indicator whether manufacturer match was even found:  1 if so, 0 if not
sub prodSystemListingBestMatch
{
    my $self = shift;
    my ( $listing ) = @_;
    #print Dumper($self);
    my $match_strength = 0;
    my $manuf = $listing->{manufacturer};
    my $manuf_map = $self->{manuf_map};
    $manuf = $manuf_map->{$manuf}; # map to product manuf name
    my $prod = undef;
    if ( defined($manuf) )
    {
        my $product_list = $self->{manuf_division}{$manuf};
        my @prod_ind_list;
        if ( defined($manuf) and defined($product_list) )
        {
            for ( my $i = 0;  $i<@$product_list;  ++$i )
            {
                my $strength = matchListingProduct($listing, $product_list->[$i] );
                if ( $strength>$match_strength )
                {
                    $match_strength = $strength;
                    @prod_ind_list = ( $i ); # clear out old list of lower strength
                    #say "pushing (first) $i ($product_list->[$i]{product_name}) with strength $strength";
                }
                elsif ( $strength>0 and $strength==$match_strength )
                {
                    push(@prod_ind_list, $i);
                    #say "pushing $i ($product_list->[$i]{product_name}) with strength $strength";
                }
            }
        }
        $prod = getBestProd($product_list, \@prod_ind_list);
    }
    return ( $prod, (not defined($manuf)) );
}


use constant MAX_PRODUCT_COMPLEXITY => 999_999_999;

# getBestProd() -- Support routine for prodSystemListingBestMatch().
# Take product list for relevant manufacturer, and index list on that product
# list.  These are entries found to have an equal, best matching strength.
# Follow a higher-level metric to pick the best matching entry from that list.
# Return its reference.
sub getBestProd
{
    my ($product_list, $prod_ind_list) = @_;
    my ( $prod, $max_prod_complexity, $min_prod_complexity ) = ( undef, 0, MAX_PRODUCT_COMPLEXITY );
    foreach my $i ( @$prod_ind_list )
    {
        my $p = $product_list->[$i];
        my $comp = productComplexity($p);
        ( $prod, $max_prod_complexity ) = ( $p, $comp )  if ( $comp>$max_prod_complexity );
    }
    return $prod;
}


use constant PROD_COMPLEXITY_MODEL_WEIGHT => 1000;

# productComplexity() -- Metric for determining higher-level complexity
# of the product.  This is used as a top-level tiebreak by getBestProd().
sub productComplexity
{
    my ( $prod ) = @_;
    my $comp = PROD_COMPLEXITY_MODEL_WEIGHT*length($prod->{model});
    $comp += length($prod->{family})  if ( exists($prod->{family}) );
    return $comp;
}


# $listing is the basic listing structure from json
# $product is the basic product structure from json
sub matchListingProduct
{
    my ($listing, $product ) = @_;
    my $stren = 0;
    my $product_name_match_len = applyParseRE($product->{product_name_re}, $listing->{title});
    my $model_match_len = applyParseRE($product->{model_re}, $listing->{title});
    my $family_match_len = 0;
    if ( $model_match_len>0 && exists($product->{family_re}) )
    {
        $family_match_len = applyParseRE($product->{family_re}, $listing->{title});
    }
    #say "product_name==($product->{product_name}), product_name_pe==($product->{product_name_pe})"  if ( exists($product->{product_name}) );
    #say "product_name_match_len==$product_name_match_len, family_match_len==$family_match_len, title==($listing->{title})";
    #say "model==($product->{model}), model_pe==($product->{model_pe})"  if ( exists($product->{model}) );
    #say "model_match_len==$model_match_len, family_match_len==$family_match_len, title==($listing->{title})";
    #say "family==($product->{family}), family_pe==($product->{family_pe})"  if ( exists($product->{family}) );
    $stren = computeMatchStrength($product_name_match_len, $model_match_len, $family_match_len);
    #say "  stren==$stren";
    return $stren;
}


# parseExpressionFromProdField() -- Generate parse expression from field.
# Parameters:
#   $field:  field for which to build matching expression
#   $high_precision:  option whether to increase precision (e.g. make fewer
#     things optional)
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
    my ( $field, $high_precision ) = @_;
    my $pe = "";
    my @field_list = split(m/_|-|:|\s/, $field);
    my @mod_field_list;
    foreach my $f ( @field_list )
    {
        # Very short fields such as "D1" must match exactly, without being
        # broken into parts.
        if ( length($f)<=2 )
        {
            push(@mod_field_list, $f);
        }
        elsif ( $f =~ m/^(.*[a-zA-Z])([0-9].*)$/ )
        {
            push(@mod_field_list, $1);
            push(@mod_field_list, $2);
        }
        else
        {
            push(@mod_field_list, $f);
        }
    }
    for ( my $i = 0;  $i<@mod_field_list;  ++$i )
    {
        my $f = $mod_field_list[$i];
        if ( $high_precision )
        {
            if ( $i>0 )
            {
                $f = "([_ -:]*\\b$f\\b)";
            }
        }
        else
        {
            if ( $i>0 )
            {
                if ( $f =~ m/^\d+$/ )
                {
                    $f = "([_ :-]*(?<!\\d)$f(?!\\d))";
                }
                else
                {
                    $f = "([_ :-]*$f)";
                }
            }
            elsif ( $i==0 and @mod_field_list>1 )
            {
                if ( $f =~ m/^\d+$/ )
                {
                    $f = "((?<!\\d)$f(?!\\d))?";
                }
                elsif ( length($f)>=2 )
                {
                    $f = "($f)?";
                }
                else
                {
                    $f = "($f)";
                }
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


use constant MATCH_STRENGTH_MODEL_WEIGHT => 1000;
use constant MATCH_STRENGTH_PRODUCT_WEIGHT => 10000;
use constant MATCH_STRENGTH_PRODUCT_OFFSET => 500_000;

# computeMatchStrength() -- Compute strength of match result.
# This is a basic heuristic against which matches are compared.
sub computeMatchStrength
{
    my ( $product_name_len, $model_len, $family_len ) = @_;
    my $stren = MATCH_STRENGTH_MODEL_WEIGHT*$model_len+$family_len;
    if ( $product_name_len>0 )
    {
        $stren += MATCH_STRENGTH_PRODUCT_OFFSET+MATCH_STRENGTH_MODEL_WEIGHT*$product_name_len;
    }
    return $stren;
}


# "Samsung_WB600" --> "WB600"
# "Nikon_Coolpix_S620" --> "S620"
# "Canon_PowerShot_G12" --> "G12"
# "Sanyo_VPC-Z400" --> "Z400"
# "Kodak_DC290" --> "DC290"
# "Kodak_EasyShare_M380" --> "M380"
# "Olympus_E-600" --> "E600"
# "Olympus_SP-600_UZ" --> "SP600"
# "Fujifilm_FinePix_S200EXR" --> S200
# "ABC123" --> "ABC123"
# "Nikon_D7000" --> "D7000"
# "blah blah blah" --> undef
# getSimpleProductNameIndicator() -- Proposed additional product discriminator
# function that is not in use now.
sub getSimpleProductNameIndicator
{
    my ( $model ) = @_;
    my $mmn = undef;
    if ( $model =~ m/(?<![a-zA-Z\d])([a-zA-Z]+\d+)(?![a-zA-Z\d])/ )
    {
        $mmn = $1;
    }
    elsif ( $model =~ m/(?<![a-zA-Z\d])([a-zA-Z]+)[ :_-]+(\d+)(?![a-zA-Z\d])/ )
    {
        $mmn = "$1$2";
    }
    elsif ( $model =~ m/(?<![a-zA-Z\d])([a-zA-Z]+\d+[a-zA-Z]+)(?![a-zA-Z\d])/ )
    {
        $mmn = $1;
    }
    elsif ( $model =~ m/(?<![a-zA-Z\d])([a-zA-Z]+)[ :_-]+(\d+)(?![a-zA-Z\d])/ )
    {
        $mmn = "$1$2";
    }
    return $mmn;
}


1;

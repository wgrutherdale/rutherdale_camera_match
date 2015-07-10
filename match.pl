#!/usr/bin/env perl
# match.pl -- Solve matching problem for Sortable.

use Modern::Perl 2013;
use autodie;
use JSON::PP;
use Data::Dumper;
use Getopt::Std;

use constant PROD_TYPE_CAMERA => 0;
use constant PROD_TYPE_ACCESSORY => 1;
use constant PROD_TYPE_UNKNOWN => 2;
use constant TEST_MODE => 0;

use constant DATA_PRODUCTS_TEXT => "data/products.txt";
use constant DATA_LISTINGS_TEXT => "data/listings.txt";
use constant RESULTS_TEXT => "results.txt";

MAIN:
{
    my %options = ( p => DATA_PRODUCTS_TEXT, l => DATA_LISTINGS_TEXT,
                    r => RESULTS_TEXT );
    getopt("tp:l:r:h", \%options);
    if ( exists($options{h}) )
    {
        help();
    }
    elsif ( exists($options{t}) )
    {
        testMatching();
    }
    else
    {
        my $products = getJsonText($options{p});
        my $listings = getJsonText($options{l});
        my $results = {};
        matchProductsListings($products, $listings, $results);
        outputJsonResults($results, $options{r});
    }
}


# help() -- Print command-line help.
sub help
{
    say STDERR "usage:  match.pl [-t] [-p <prod>] [-l <listing>] [-r <results>] [-h]";
    say STDERR "  where -t indicates to run test";
    say STDERR "        <prod> is alternative product file, default ", DATA_PRODUCTS_TEXT;
    say STDERR "        <listing> is alternative product file, default ", DATA_LISTINGS_TEXT;
    say STDERR "        <results> is alternative results file, default ", RESULTS_TEXT;
    say STDERR "        -h gives this help message";
}


# getJsonText() -- Load Json text file into data structure and return the structure.
# Structure returned is reference to list of records.  Content of that structure
# is determined by input file.
sub getJsonText
{
    my ( $fname ) = @_;
    open(my $fh, "<", $fname) or die "Couldn't open file: $!";
    my @data;
    while ( defined(my $line = <$fh>) )
    {
        chomp($line);
        push(@data, decode_json($line));
    }
    close $fh;
    return \@data;
}


# outputJsonResults() -- Dump results structure in json format to given file
# name.
# Parameters:
#   $results:  results structure
#   $fname:  file name for json output
sub outputJsonResults
{
    my ($results, $fname) = @_;
    open(my $fh, ">", $fname) or die "Couldn't open file: $!";
    my $json = JSON::PP->new;
    $json->pretty;
    $json->canonical;
    while ( my ( $product_name, $listing_array ) = each(%$results) )
    {
        my $json_record = { product_name => $product_name,
                            listings => $listing_array };
        print $fh $json->encode($json_record), "\n";
    }
    close $fh;
}


# matchProductsListings() -- Load json structures and perform matching
# heuristics between listings and products.  Log results where appropriate,
# and build results structure.
# This is the top level function.
# Parameters:
#   $products:  products as loaded from json file
#   $listings:  listings as loaded from json file
#   $results:  results structure (built here), ready for output to json file
sub matchProductsListings
{
    my ( $products, $listings, $results ) = @_;
    my %manuf_prod_list;
    my %prod_mfg_list;
    my %lstg_mfg_list;
    foreach my $prod ( @$products )
    {
        ++$prod_mfg_list{$prod->{manufacturer}};
    }
    foreach my $lstg ( @$listings )
    {
        ++$lstg_mfg_list{$lstg->{manufacturer}};
    }
    my @prod_mfg_keys = keys(%prod_mfg_list);
    my @lstg_mfg_keys = keys(%lstg_mfg_list);
    #say "prod_mfg_keys==(@prod_mfg_keys";
    #say "lstg_mfg_keys==(@lstg_mfg_keys";
    my $mfg_mapping = createManufacturerMapping(\@prod_mfg_keys, \@lstg_mfg_keys);
    #print "AAAAAAAAAAAAAAA", Dumper($mfg_mapping);
    for ( my $i = 0;  $i<@$products;  ++$i )
    {
        my $prod = $products->[$i];
        my $manuf = $prod->{manufacturer};
        #say "manufacturer==$manuf";
        $manuf_prod_list{$manuf} = []  unless exists( $manuf_prod_list{$manuf} );
        my $mpl = $manuf_prod_list{$manuf};
        push(@$mpl, $i);
        $results->{$prod->{product_name}} = [];
        #print Dumper($prod);
    }
    my $report_stats = { n_none => 0, n_cam_1 => 0, n_cam_n => 0,
                         n_reason_no_manuf => 0 };
    #foreach my $lstg ( @$listings )
    for ( my $i = 0;  $i<@$listings;  ++$i )
    {
        my $lstg = $listings->[$i];
        #print Dumper($lstg);
        #my $manuf = $lstg->{manufacturer};
        my $manuf = $mfg_mapping->{$lstg->{manufacturer}};
        #say "manuf==$manuf";
        #print Dumper(\%manuf_prod_list);
        if ( exists($manuf_prod_list{$manuf}) )
        {
            processProdCandidate($products, $manuf_prod_list{$manuf}, $i,
                                 $lstg, $report_stats, $results);
        }
        else
        {
            ++$report_stats->{n_none};
            ++$report_stats->{n_reason_no_manuf};
        }
    }
    say "Report Stats:";
    say "  Number of listings altogether:  ", int(@$listings);
    say "  Number of listings matching no products:  $report_stats->{n_none}";
    say "    Number because of no manufacturer:  $report_stats->{n_reason_no_manuf}";
    say "  Number of listings matching 1 camera only:  $report_stats->{n_cam_1}";
    say "  Number of listings matching >1 camera only:  $report_stats->{n_cam_n}";
}


# processProdCandidate() -- Take list of products, listing item and other
# values, and try matching listing item against product(s).
# Report results.
# Precondition:  manufacturer field for listing item has already been checked
# for existence.
# Parameters:
#   $products:  list reference containing product records loaded from json
#   $manuf_prod_list:  List of indices in $products corresponding to listing
#           item's manufacturer.
#   $lstg_index:  index in listing list
#   $lstg:  record contents from listing list
#   $report_stats:  statistics reporting structure, to be passed through to
#           appropriate routines for accumulating statistics on match results
#   $results:  results structure to be made ready for final json output;
#           this is a hash indexed by product name and containing for each
#           a list of listing objects that match
sub processProdCandidate
{
    my ( $products, $manuf_prod_list, $lstg_index, $lstg, $report_stats, $results ) = @_;
    #print Dumper($manuf_prod_list, $lstg);
    my $lstg_title = $lstg->{title};
    #say "lstg_title==$lstg_title";
    my @camera_prod_ind_list;
    foreach my $prod_ind ( @$manuf_prod_list )
    {
        my $prod = $products->[$prod_ind];
        my $prod_model = $prod->{model};
        my $prod_family = $prod->{family};
        my $does_match = doesMatch($prod, $lstg);
        #say "Match results:  prod_ind==$prod_ind, lstg_index==$lstg_index, does_match==$does_match";
        if ( $does_match )
        {
            #say "  match:  prod_model==($prod_model)";
            #say "  lstg_title==($lstg_title)";
            push(@camera_prod_ind_list, $prod_ind);
            my $res_item = $results->{$prod->{product_name}};
            push(@$res_item, $lstg);
        }
    }
    #say "  camera_prod_ind_list==(@camera_prod_ind_list)";
    reportListing($products, $lstg, \@camera_prod_ind_list, $report_stats);
}


# reportListing() -- Report on listing and anything found for it.  Accumulate statistics.
# Parameters:
#   $products:  list of all product structures as loaded from json
#   $lstg:  listing entry
#   $camera_prod_ind_list:  list of product indices for cameras
#   $reportListing:  statistics accumulation structure
sub reportListing
{
    my ($products, $lstg, $camera_prod_ind_list, $report_stats) = @_;
    say "Listing  $lstg->{title}";
    say "  Currency $lstg->{currency}, Price $lstg->{price}";
    say "  Matching cameras:";
    my $n_cam = 0;
    foreach my $cam ( @$camera_prod_ind_list )
    {
        my $prod = $products->[$cam];
        say "    model $prod->{model}, name $prod->{product_name}";
        ++$n_cam;
    }
    say "  Zero match"  if ( $n_cam==0 );
    say "  Dual match"  if ( $n_cam>1 );
    ++$report_stats->{n_none}  if ( $n_cam==0 );
    ++$report_stats->{n_cam_1}  if ( $n_cam==1 );
    ++$report_stats->{n_cam_n}  if ( $n_cam>1 );
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
    my %mapping;
    foreach my $lstg ( @$lstg_mfg_keys )
    {
        my $prod_name = $lstg;
        foreach my $prod ( @$prod_mfg_keys )
        {
            $prod_name = $prod  if ( index($lstg, $prod)>=0 );
        }
        $mapping{$lstg} = $prod_name;
    }
    return \%mapping;
}


# testMatching()
# Apply various test cases to determine how well doesMatch() performs.
sub testMatching
{
    if ( 0 )
    {
    my $matches0 = doesMatch( # should match
        { product_name => "Canon_PowerShot_SD980_IS", manufacturer => "Canon", model => "SD980 IS", family => "PowerShot","announced-date" => "2009-08-18T20:00:00.000-04:00" },
        { title => "Canon PowerShot SD980IS 12MP Digital Camera with 5x Ultra Wide Angle Optical Image Stabilized Zoom and 3-inch LCD (Purple)", manufacturer => "Canon", currency => "USD", price => 157.95 } );
    say "matches0==$matches0";
    my $matches1 = doesMatch( # should match
        { product_name => "Nikon_D300", manufacturer => "Nikon", model => "D300", "announced-date" => "2009-07-29T20:00:00.000-04:00"},
        { title => "Nikon D300 DX 12.3MP Digital SLR Camera with 18-135mm AF-S DX f/3.5-5.6G ED-IF Nikkor Zoom Lens", manufacturer => "Nikon", currency => "USD", price => 2899.98});
    say "matches1==$matches1";
    my $matches2 = doesMatch( # should not match
        { product_name => "Nikon_D300", manufacturer => "Nikon", model => "D300", "announced-date" => "2009-07-29T20:00:00.000-04:00"},
        { title => "Nikon D3000 10.2MP Digital SLR Camera Kit (Body) with WSP Mini Tripod & Cleaning set.", manufacturer => "Nikon", currency => "USD", price => 499.95});
    say "matches2==$matches2";
    my $matches3 = doesMatch( # should not match
        { product_name => "Nikon_D300", manufacturer => "Nikon", model => "D300", "announced-date" => "2009-07-29T20:00:00.000-04:00"},
        { title => "Nikon D300s 12.3mp Digital SLR Camera with 3inch LCD Display (Includes Manufacturer's Supplied Accessories) with Nikon Af-s Vr Zoom-nikkor 70-300mm F/4.5-5.6g If-ed Lens + PRO Shooter Package Including Dedicated I-ttl Digital Flash + OFF Camera Flash Shoe Cord + 16gb Sdhc Memory Card + Wide Angle Lens + Telephoto Lens + Filter Kit + 2x Extended Life Batteries + Ac-dc Rapid Charger + Soft Carrying Case + Tripod & Much More !!", manufacturer => "Digital", currency => "USD", price => 2094.99});
    say "matches3==$matches3";
    my $matches4 = doesMatch( # should match
        {product_name => "Nikon_D300S", manufacturer => "Nikon", model => "D300S", "announced-date" => "2009-07-29T20:00:00.000-04:00"},
        {title => "NIKON D300s (camera body only) + SLRC-201 Bag + 16 GB SDHC Memory Card + Battery EN-EL3e + AN-D300 Neck Strap (ComboKit)", manufacturer => "Nikon", currency => "GBP", price => 1618.44});
    say "matches4==$matches4";
    my $matches5 = doesMatch( # should match
        {product_name => "Olympus_Stylus_Tough-3000", manufacturer => "Olympus", model => "Tough-3000", family => "Stylus", "announced-date" => "2010-01-06T19:00:00.000-05:00"},
        {title => "Olympus Stylus Tough 3000 12 MP Digital Camera with 3.6x Wide Angle Zoom and 2.7-inch LCD (Blue)", manufacturer => "Olympus Canada", currency => "CAD", price => 161.87});
    say "matches5==$matches5";
    my $matches6 = doesMatch( # should match
        {product_name => "Olympus-T100",manufacturer => "Olympus", model => "T100", "announced-date" => "2010-03-20T20:00:00.000-04:00"},
        {title => "Olympus T-100 12MP Digital Camera with 3x Optical Zoom and 2.4 inch LCD (Red)", manufacturer => "Olympus Canada", currency => "CAD", price => 87.86});
    say "matches6==$matches6";
    }
    if ( 0 )
    {
    my $matches7 = doesMatch( # should match
        {product_name => "Sony_Cyber-shot_DSC-T99", manufacturer => "Sony", model => "DSC-T99", family => "Cyber-shot", "announced-date" => "2010-07-07T20:00:00.000-04:00"},
        {title => "Sony T Series DSC-T99 14.1 Megapixel DSC Camera with Super HAD CCD Image Sensor (Silver)", manufacturer => "Sony", currency => "CAD", price => 196.87});
    say "matches7==$matches7";
    my $matches7a = doesMatch( # should match
        {product_name => "Sony_Cyber-shot_DSC-T99", manufacturer => "Sony", model => "DSC-T99", family => "Cyber-shot", "announced-date" => "2010-07-07T20:00:00.000-04:00"},
        {title => "Sony Cyber-shot DSC-T99 - Digital camera - compact - 14.1 Mpix - optical zoom: 4 x - supported memory: MS Duo, SD, MS PRO Duo, SDXC, MS PRO Duo Mark2, SDHC, MS PRO-HG Duo - black",
         manufacturer => "Sony", currency => "GBP", price => "235.00"});
    say "matches7a==$matches7a";
    my $matches7b = doesMatch( # should match
        {product_name => "Sony_Cyber-shot_DSC-T99", manufacturer => "Sony", model => "DSC-T99", family => "Cyber-shot", "announced-date" => "2010-07-07T20:00:00.000-04:00"},
        {title => "Sony T Series DSC-T99/B 14.1 Megapixel DSC Camera with Super HAD CCD Image Sensor (Black)", manufacturer => "Sony", currency => "CAD", price => 229.99});
    say "matches7b==$matches7b";
    my $matches7c = doesMatch( # should match
        {product_name => "Sony_Cyber-shot_DSC-T99", manufacturer => "Sony", model => "DSC-T99", family => "Cyber-shot", "announced-date" => "2010-07-07T20:00:00.000-04:00"},
        {title => "Sony DSCT99B Cybershot Digital Camera - Black (14.1MP, 4x Optical Zoom, 3 inch LCD)", manufacturer => "Sony", currency => "GBP", price => 156.99});
    say "matches7c==$matches7c";
    my $matches7d = doesMatch( # should not match
        {product_name => "Sony_Cyber-shot_DSC-T99", manufacturer => "Sony", model => "DSC-T99", family => "Cyber-shot", "announced-date" => "2010-07-07T20:00:00.000-04:00"},
        {title => "Sony DSCT990B Cybershot Digital Camera - Black (14.1MP, 4x Optical Zoom, 3 inch LCD)", manufacturer => "Sony", currency => "GBP", price => 156.99});
    say "matches7d==$matches7d";
    my $matches7e = doesMatch( # should not match
        {product_name => "Sony_Cyber-shot_DSC-T99", manufacturer => "Sony", model => "DSC-T99", family => "Cyber-shot", "announced-date" => "2010-07-07T20:00:00.000-04:00"},
        {title => "Sony Cyber-shot DSC-T993 - Digital camera - compact - 14.1 Mpix - optical zoom: 4 x - supported memory: MS Duo, SD, MS PRO Duo, SDXC, MS PRO Duo Mark2, SDHC, MS PRO-HG Duo - black",
         manufacturer => "Sony", currency => "GBP", price => "235.00"});
    say "matches7e==$matches7e";
    my $matches8 = doesMatch( # should match
        {product_name => "Canon_PowerShot_SD4000_IS", manufacturer => "Canon", model => "SD4000 IS", family => "PowerShot", "announced-date" => "2010-05-10T20:00:00.000-04:00"},
        {title => "Canon PowerShot SD4000IS 10 MP CMOS Digital Camera with 3.8x Optical Zoom and f/2.0 Lens (Silver)", manufacturer => "Canon Canada", currency => "CAD", price => 372.59});
    say "matches8==$matches8";
    my $matches9 = doesMatch( # should match
        {product_name => "Olympus-VR320", manufacturer => "Olympus", model => "VR320","announced-date" => "2011-02-07T19:00:00.000-05:00"},
        {title => "Olympus VR-320 228125 14 MP Digital Camera with Super-Wide 12.5x Zoom and 3.0-Inch LCD (Black)", manufacturer => "Olympus", currency => "USD", price => 199.00});
    say "matches9==$matches9";
    }
    my $matches10 = doesMatch( # should match
        {product_name => "Canon_EOS_Rebel_T1i", manufacturer => "Canon", model => "T1i", family => "Rebel", "announced-date" => "2009-03-24T20:00:00.000-04:00"},
        {title => "Canon EOS Rebel T1i 15.1 MP CMOS Digital SLR Camera with 3-Inch LCD and EF-S 18-55mm f/3.5-5.6 IS Lens", manufacturer => "Canon", currency => "CAD", price => 899.00});
    say "matches10==$matches10";

}


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



#!/usr/bin/env perl
# match.pl -- Solve matching problem for Sortable.

use Modern::Perl 2013;
use autodie;
use JSON::PP;
use Data::Dumper;
use Getopt::Std;
use Test::Harness;

use FindBin;
use lib "FindBin::Bin";
use matchHeuristics;

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
    runtests("testMatchHeuristics.t");
}



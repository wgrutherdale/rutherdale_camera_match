#!/usr/bin/env perl
# match.pl -- Solve matching problem for Sortable.

use Modern::Perl 2013;
use autodie;
use JSON::PP;
use Data::Dumper;
use Getopt::Std;
use Test::Harness;
use Time::HiRes qw/gettimeofday/;

use FindBin;
use lib "FindBin::Bin";
use matchHeuristics;


use constant DATA_PRODUCTS_TEXT => "data/products.txt";
use constant DATA_LISTINGS_TEXT => "data/listings.txt";
use constant RESULTS_TEXT => "results.txt";

MAIN:
{
    my %options = ( p => DATA_PRODUCTS_TEXT, l => DATA_LISTINGS_TEXT,
                    r => RESULTS_TEXT );
    getopt("tp:l:r:uh", \%options);
    if ( exists($options{h}) )
    {
        help();
    }
    elsif ( exists($options{t}) )
    {
        #testParsing();
        #testMatching();
        testMatchingRevised();
    }
    else
    {
        matchItems(\%options);
    }
}


# help() -- Print command-line help.
sub help
{
    say STDERR "usage:  match.pl [-t] [-p <prod>] [-l <listing>] [-r <results>] [-u] [-a] [-h]";
    say STDERR "  where -t indicates to run test";
    say STDERR "        -n indicates running new algorithm";
    say STDERR "        <prod> is alternative product file, default ", DATA_PRODUCTS_TEXT;
    say STDERR "        <listing> is alternative product file, default ", DATA_LISTINGS_TEXT;
    say STDERR "        <results> is alternative results file, default ", RESULTS_TEXT;
    say STDERR "        -u shows unmatched listings";
    say STDERR "        -h gives this help message";
}


# getJsonText() -- Load Json text file into data structure and return the structure.
# Structure returned is reference to list of records.  Content of that structure
# is determined by input file.
sub getJsonText
{
    my ( $fname, $field_list ) = @_;
    open(my $fh, "<", $fname);
    my @data;
    while ( defined(my $line = <$fh>) )
    {
        chomp($line);
        my $record = decode_json($line);
        unless ( verifyRecordFields($record, $field_list) )
        {
            die "Invalid record in file $fname";
        }
        push(@data, $record);
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


# matchItems() -- Control reading products and listings, and performing
# matches on them.
# Parameters:
#   $options:  command-line options
sub matchItems
{
    my ( $options ) = @_;

    my $t0 = gettimeofday();
    my $products = getJsonText($options->{p},
        ["product_name", "manufacturer", "model", "announced-date"]);
    $t0 = reportAndGetTime("Loaded products", $t0);
    my $listings = getJsonText($options->{l},
        ["title", "manufacturer", "currency", "price"]);
    $t0 = reportAndGetTime("Loaded listings", $t0);
    my $match_heuristics = matchHeuristics->new();

    $t0 = reportAndGetTime("Initialised product struct", $t0);
    $match_heuristics->prodSystemMapManufListings( $products, $listings);
    $t0 = reportAndGetTime("Set up manufacturer mappings", $t0);
    my $results = {};
    $match_heuristics->prodSystemTrackProductList($products, $results);
    $t0 = reportAndGetTime("Set up all products in structure", $t0);
    my $report_stats = { n_none => 0, n_cam_1 => 0,
                         n_reason_no_manuf => 0 };
    prodMatchListings($match_heuristics, $listings, $results, $report_stats);
    $t0 = reportAndGetTime("Determined product matches for listings", $t0);
    #print Dumper($results);
    outputJsonResults($results, $options->{r});
    $t0 = reportAndGetTime("Output Json results", $t0);
    say "Report stats:";
    say "  Number of listings matching nothing:  $report_stats->{n_none}";
    say "    Due to missing manufacturer:  $report_stats->{n_reason_no_manuf}";
    say "  Number of listings matching 1 camera:  $report_stats->{n_cam_1}";
    if ( exists($options->{u}) )
    {
        say "Unused listings:";
        foreach my $list ( @$listings )
        {
            if ( exists($list->{unused}) )
            {
                say "  $list->{title}";
            }
        }
    }
}


# testParsing() -- Extra testing of parsing behaviour for fields.
sub testParsing
{
    say "testParsing()";
    testParseA("Nikon_D300", "Nikon D3000 10.2MP Digital SLR Camera Kit (Body) with WSP Mini Tripod & Cleaning set.");
    testParseA("Nikon_D300", "Nikon D3000 10.2MP Digital SLR Camera Kit (Body) with WSP Mini Tripod & Cleaning set.");
    testParseA("Nikon-D300", "Nikon D300 DX 12.3MP Digital SLR Camera with 18-135mm AF-S DX f/3.5-5.6G ED-IF Nikkor Zoom Lens");
    testParseA("Nikon:D300", "Nikon D300 DX 12.3MP Digital SLR Camera with 18-135mm AF-S DX f/3.5-5.6G ED-IF Nikkor Zoom Lens");
    testParseA("Nikon D300", "Nikon D300s 12.3mp Digital SLR Camera with 3inch LCD Display (Includes Manufacturer's Supplied Accessories) with Nikon Af-s Vr Zoom-nikkor 70-300mm F/4.5-5.6g If-ed Lens + PRO Shooter Package Including Dedicated I-ttl Digital Flash + OFF Camera Flash Shoe Cord + 16gb Sdhc Memory Card + Wide Angle Lens + Telephoto Lens + Filter Kit + 2x Extended Life Batteries + Ac-dc Rapid Charger + Soft Carrying Case + Tripod & Much More !!");
    testParseA("Nikon D300", "Nikon D300s 12.3mp Digital SLR Camera with 3inch LCD Display (Includes Manufacturer's Supplied Accessories) with Nikon Af-s Vr Zoom-nikkor 70-300mm F/4.5-5.6g If-ed Lens + PRO Shooter Package Including Dedicated I-ttl Digital Flash + OFF Camera Flash Shoe Cord + 16gb Sdhc Memory Card + Wide Angle Lens + Telephoto Lens + Filter Kit + 2x Extended Life Batteries + Ac-dc Rapid Charger + Soft Carrying Case + Tripod & Much More !!");

    testParseA("Tough-3000", "Olympus T-100 12MP Digital Camera with 3x Optical Zoom and 2.4 inch LCD (Red)");
    testParseA("T100", "Olympus T-100 12MP Digital Camera with 3x Optical Zoom and 2.4 inch LCD (Red)");

    testParseA("DMC-FZ40", "Panasonic Lumix FZ40 Black 24x Zoom Leica Lens Taxes Included!");
    testParseA("DMC-FZ40", "Panasonic Lumix DMC FZ40 Black 24x Zoom Leica Lens Taxes Included!");

    testParseA("PEN E-PL2", "Olympus PEN E-PL1 12.3MP Live MOS Micro Four Thirds Interchangeable Lens Digital Camera with 14-42mm f/3.5-5.6 Zuiko Digital Zoom Lens (Black)");
    testParseA("PEN E-PL1", "Olympus PEN E-PL1 12.3MP Live MOS Micro Four Thirds Interchangeable Lens Digital Camera with 14-42mm f/3.5-5.6 Zuiko Digital Zoom Lens (Black)");

    testParseA("D1", "Nikon Coolpix P80 10.1MP Digital Camera with 18x Wide Angle Optical Vibration Reduction Zoom (Black)");
}


# testParseA() -- Support routine for testParsing().
sub testParseA
{
    my ( $field, $str ) = @_;
    say "  testParseA($field)";
    my $pe = parseExpressionFromProdField($field, 0);
    my $re = qr/$pe/i;
    my $matches = applyParseRE($re, $str);
    say "    pe==($pe), matches==$matches";
}


# testMatching()
# Apply various test cases to determine how well doesMatch() performs.
sub testMatching
{
    runtests("testMatchHeuristics.t");
}


# testMatchingRevised()
# Apply various test cases to determine how well doesMatch() performs.
sub testMatchingRevised
{
    runtests("testMatchHeuristics.t");
}


# prodMatchListings() -- Determine matches for listings based on products.
# Parameters:
#   $prod_struct:  product structure with all pre-processed info
#   $listings:  array reference for listing values read from json file
#   $results:  place where results are to be stored.  This is a reference to
#     a hash with a list nested inside.  The hash is indexed by product name,
#     and the list is the listing reference that matched for that product.
#   $report_stats:  structure tracking some statistics to be reported later
# Results:
#   $results is populated with all listings that have a product (stored under
#     product entry)
#   $report_stats has n_cam_1, n_none, and n_reason_no_manuf fields counted
#   Each $listings entry has a field 'unused' added, containing either 1 if
#     the listing remains unused (added to $results) or deleted if used.
#     The 'unused' form is used so that there is no extra flag printed in
#     output in case the item is used.
sub prodMatchListings
{
    my ( $match_heuristics, $listings, $results, $report_stats ) = @_;
    foreach my $list ( @$listings )
    {
        $list->{unused} = 1;
    }
    foreach my $list ( @$listings )
    {
        #say "working on $list->{title}";
        my ( $prod, $no_manuf ) = $match_heuristics->prodSystemListingBestMatch($list);
        if ( defined($prod) )
        {
            my $res_item = $results->{$prod->{product_name}};
            push(@$res_item, $list);
            ++$report_stats->{n_cam_1};
            delete($list->{unused});
        }
        else
        {
            ++$report_stats->{n_none};
            ++$report_stats->{n_reason_no_manuf}  if ( $no_manuf );
        }
    }
}


# reportAndGetTime() -- Report time for operation in standard way, and get new time.
# Parameters:
#   heading:  heading to print.
#   $t0:  time prior to start of operation
# Return value: time now
sub reportAndGetTime
{
    my ( $heading, $t0 ) = @_;
    my $t1 = gettimeofday();
    printf("%s:  %0.3fs\n", $heading, $t1-$t0);
    return $t1;
}


# verifyRecordFields() -- Check whether a given hash contains all the required fields.
sub verifyRecordFields
{
    my $okay = 1;
    my ( $hash, $field_list ) = @_;
    foreach my $f ( @$field_list )
    {
        unless ( exists($hash->{$f}) )
        {
            $okay = 0;
            last;
        }
    }
    return $okay;
}



#!/usr/bin/env perl
# testMatchHeuristics.pl -- Test matchHeuristics.pm module.

use Modern::Perl 2013;
use autodie;

use FindBin;
use lib "FindBin::Bin";
use matchHeuristics;
use Test::Simple tests => 28;

MAIN:
{
    testMatching();
    testMatchingB();
    testMatchingC();
}


# testMatching()
# Apply various test cases to determine how well doesMatch() performs.
sub testMatching
{
    my $products = [
        { product_name => "Canon_PowerShot_SD980_IS", manufacturer => "Canon", model => "SD980 IS", family => "PowerShot","announced-date" => "2009-08-18T20:00:00.000-04:00" },
        { product_name => "Nikon_D300", manufacturer => "Nikon", model => "D300", "announced-date" => "2009-07-29T20:00:00.000-04:00"},
        { product_name => "Nikon_D300S", manufacturer => "Nikon", model => "D300S", "announced-date" => "2009-07-29T20:00:00.000-04:00"},
        { product_name => "Olympus_Stylus_Tough-3000", manufacturer => "Olympus", model => "Tough-3000", family => "Stylus", "announced-date" => "2010-01-06T19:00:00.000-05:00"},
        { product_name => "Olympus-T100",manufacturer => "Olympus", model => "T100", "announced-date" => "2010-03-20T20:00:00.000-04:00"},
        { product_name => "Sony_Cyber-shot_DSC-T99", manufacturer => "Sony", model => "DSC-T99", family => "Cyber-shot", "announced-date" => "2010-07-07T20:00:00.000-04:00"},
        { product_name => "Canon_PowerShot_SD4000_IS", manufacturer => "Canon", model => "SD4000 IS", family => "PowerShot", "announced-date" => "2010-05-10T20:00:00.000-04:00"},
        { product_name => "Olympus-VR320", manufacturer => "Olympus", model => "VR320","announced-date" => "2011-02-07T19:00:00.000-05:00"},
        { product_name => "Canon_EOS_Rebel_T1i", manufacturer => "Canon", model => "T1i", family => "Rebel", "announced-date" => "2009-03-24T20:00:00.000-04:00"},
        { product_name => "Canon_IXUS_300_HS", manufacturer => "Canon", model => "300 HS", family => "IXUS","announced-date" => "2010-05-10T20:00:00.000-04:00"},
        { product_name => "Canon-ELPH-300HS", manufacturer => "Canon", model => "300 HS", family => "ELPH","announced-date" => "2011-02-06T19:00:00.000-05:00"},
        { product_name => "Nikon_D3000", manufacturer => "Nikon", model => "D3000","announced-date" => "2009-07-29T20:00:00.000-04:00"},
        { product_name => "Nikon_D5000", manufacturer => "Nikon", model => "D5000","announced-date" => "2009-04-13T20:00:00.000-04:00"},
        { product_name => "Pentax-WG-1-GPS", manufacturer => "Pentax", model => "WG-1 GPS", family => "Optio","announced-date" => "2011-02-06T19:00:00.000-05:00"},
        { product_name => "Pentax-WG-1", manufacturer => "Pentax", model => "WG-1", family => "Optio","announced-date" => "2011-02-06T19:00:00.000-05:00"},
    ];
    my $listings = [ # just need to build manufacturer mapping from this list
        { manufacturer => "Canon" },
        { manufacturer => "Nikon" },
        { manufacturer => "Digital" },
        { manufacturer => "Olympus Canada" },
        { manufacturer => "Sony" },
        { manufacturer => "Canon Canada" },
        { manufacturer => "Olympus" },
        { manufacturer => "Pentax Canada" },
    ];
    my $match_heuristics = matchHeuristics->new();
    $match_heuristics->prodSystemMapManufListings($products, $listings);
    say "done map";
    $match_heuristics->prodSystemTrackProductList($products, undef);
    say "done product tracking";

    my $matches0 = testMatchRev($match_heuristics,
        { title => "Canon PowerShot SD980IS 12MP Digital Camera with 5x Ultra Wide Angle Optical Image Stabilized Zoom and 3-inch LCD (Purple)", manufacturer => "Canon", currency => "USD", price => 157.95 },
        "Canon_PowerShot_SD980_IS");
    ok($matches0==1, "matches0");

    my $matches1 = testMatchRev($match_heuristics,
        { title => "Nikon D300 DX 12.3MP Digital SLR Camera with 18-135mm AF-S DX f/3.5-5.6G ED-IF Nikkor Zoom Lens", manufacturer => "Nikon", currency => "USD", price => 2899.98},
        "Nikon_D300");
    ok($matches1==1, "matches1");

    my $matches2 = testMatchRev($match_heuristics,
        { title => "Nikon D3000 10.2MP Digital SLR Camera Kit (Body) with WSP Mini Tripod & Cleaning set.",
          manufacturer => "Nikon", currency => "USD", price => 499.95},
          "Nikon_D3000");
    ok($matches2==1, "matches2");

    my $matches3 = testMatchRev($match_heuristics,
        { title => "Nikon D300s 12.3mp Digital SLR Camera with 3inch LCD Display (Includes Manufacturer's Supplied Accessories) with Nikon Af-s Vr Zoom-nikkor 70-300mm F/4.5-5.6g If-ed Lens + PRO Shooter Package Including Dedicated I-ttl Digital Flash + OFF Camera Flash Shoe Cord + 16gb Sdhc Memory Card + Wide Angle Lens + Telephoto Lens + Filter Kit + 2x Extended Life Batteries + Ac-dc Rapid Charger + Soft Carrying Case + Tripod & Much More !!",
          manufacturer => "Digital", currency => "USD", price => 2094.99},
          "Nikon_D300S");
    say "matches3==($matches3)";
    ok($matches3==0, "matches3");

    my $matches4 = testMatchRev($match_heuristics,
        {title => "NIKON D300s (camera body only) + SLRC-201 Bag + 16 GB SDHC Memory Card + Battery EN-EL3e + AN-D300 Neck Strap (ComboKit)",
         manufacturer => "Nikon", currency => "GBP", price => 1618.44},
         "Nikon_D300S");
    ok($matches4==1, "matches4");

    my $matches5 = testMatchRev($match_heuristics,
        {title => "Olympus Stylus Tough 3000 12 MP Digital Camera with 3.6x Wide Angle Zoom and 2.7-inch LCD (Blue)",
         manufacturer => "Olympus Canada", currency => "CAD", price => 161.87},
         "Olympus_Stylus_Tough-3000");
    ok($matches5==1, "matches5");

    my $matches6 = testMatchRev($match_heuristics,
        {title => "Olympus T-100 12MP Digital Camera with 3x Optical Zoom and 2.4 inch LCD (Red)",
         manufacturer => "Olympus Canada", currency => "CAD", price => 87.86},
         "Olympus-T100");
    ok($matches6==1, "matches6");

    my $matches7 = testMatchRev($match_heuristics,
        {title => "Sony T Series DSC-T99 14.1 Megapixel DSC Camera with Super HAD CCD Image Sensor (Silver)",
         manufacturer => "Sony", currency => "CAD", price => 196.87},
         "Sony_Cyber-shot_DSC-T99");
    ok($matches7==1, "matches7");

    my $matches7a = testMatchRev($match_heuristics,
        {title => "Sony Cyber-shot DSC-T99 - Digital camera - compact - 14.1 Mpix - optical zoom: 4 x - supported memory: MS Duo, SD, MS PRO Duo, SDXC, MS PRO Duo Mark2, SDHC, MS PRO-HG Duo - black",
         manufacturer => "Sony", currency => "GBP", price => "235.00"},
         "Sony_Cyber-shot_DSC-T99");
    ok($matches7a==1, "matches7a");

    my $matches7b = testMatchRev($match_heuristics,
        {title => "Sony T Series DSC-T99/B 14.1 Megapixel DSC Camera with Super HAD CCD Image Sensor (Black)",
         manufacturer => "Sony", currency => "CAD", price => 229.99},
         "Sony_Cyber-shot_DSC-T99");
    ok($matches7b==1, "matches7b");

    my $matches7c = testMatchRev($match_heuristics,
        {title => "Sony DSCT99B Cybershot Digital Camera - Black (14.1MP, 4x Optical Zoom, 3 inch LCD)",
         manufacturer => "Sony", currency => "GBP", price => 156.99},
         "Sony_Cyber-shot_DSC-T99");
    ok($matches7c==1, "matches7c");

    my $matches7d = testMatchRev($match_heuristics,
        {title => "Sony DSCT990B Cybershot Digital Camera - Black (14.1MP, 4x Optical Zoom, 3 inch LCD)",
         manufacturer => "Sony", currency => "GBP", price => 156.99},
         "Sony_Cyber-shot_DSC-T99");
    ok($matches7d==0, "matches7d");

    my $matches7e = testMatchRev($match_heuristics,
        {title => "Sony Cyber-shot DSC-T993 - Digital camera - compact - 14.1 Mpix - optical zoom: 4 x - supported memory: MS Duo, SD, MS PRO Duo, SDXC, MS PRO Duo Mark2, SDHC, MS PRO-HG Duo - black",
         manufacturer => "Sony", currency => "GBP", price => "235.00"},
          "Sony_Cyber-shot_DSC-T99");
    ok($matches7e==0, "matches7e");

    my $matches8 = testMatchRev($match_heuristics,
        {title => "Canon PowerShot SD4000IS 10 MP CMOS Digital Camera with 3.8x Optical Zoom and f/2.0 Lens (Silver)",
         manufacturer => "Canon Canada", currency => "CAD", price => 372.59},
         "Canon_PowerShot_SD4000_IS");
    ok($matches8==1, "matches8");

    my $matches9 = testMatchRev($match_heuristics,
        {title => "Olympus VR-320 228125 14 MP Digital Camera with Super-Wide 12.5x Zoom and 3.0-Inch LCD (Black)",
         manufacturer => "Olympus", currency => "USD", price => 199.00},
         "Olympus-VR320");
    ok($matches9==1, "matches9");

    my $matches10 = testMatchRev($match_heuristics,
        {title => "Canon EOS Rebel T1i 15.1 MP CMOS Digital SLR Camera with 3-Inch LCD and EF-S 18-55mm f/3.5-5.6 IS Lens",
         manufacturer => "Canon", currency => "CAD", price => 899.00},
         "Canon_EOS_Rebel_T1i");
    ok($matches10==1, "matches10");

    my $matches11a = testMatchRev($match_heuristics,
        {title => "Canon PowerShot ELPH 300 HS (Black)",
         manufacturer => "Canon Canada", currency => "CAD", price => 259.99},
         "Canon-ELPH-300HS");
    ok($matches11a==1, "matches11a");

    my $matches11b = testMatchRev($match_heuristics,
        {title => "Canon PowerShot ELPH 300 HS (Black)",
         manufacturer => "Canon Canada", currency => "CAD", price => 259.99},
         "Canon-ELPH-300HS");
    ok($matches11b==1, "matches11b");

    my $matches12a = testMatchRev($match_heuristics,
        {title => "Nikon EN-EL9a 1080mAh Ultra High Capacity Li-ion Battery Pack for Nikon D40, D40x, D60, D3000, & D5000 Digital SLR Cameras",
         manufacturer => "Nikon", currency => "CAD", price => 29.75},
         "Nikon_D3000");
    ok($matches12a==1, "matches12a"); # TODO  Modify accessory detection and do not accept this.

    my $matches12b = testMatchRev($match_heuristics,
        {title => "Nikon EN-EL9a 1080mAh Ultra High Capacity Li-ion Battery Pack for Nikon D40, D40x, D60, D3000, & D5000 Digital SLR Cameras",
         manufacturer => "Nikon", currency => "CAD", price => 29.75},
         "Nikon_D5000");
    ok($matches12b==0, "matches12b");

    my $matches13a = testMatchRev($match_heuristics,
        {title => "PENTAX Optio WG-1 GPS 14 MP Rugged Waterproof Digital Camera with 5X Optical Zoom, 2.7-inch LCD and GPS Funtionality (Green )",
         manufacturer => "Pentax Canada", currency => "CAD", price => 387.33},
         "Pentax-WG-1-GPS");
    ok($matches13a==1, "matches13a");

    my $matches13b = testMatchRev($match_heuristics,
        {title => "PENTAX Optio WG-1 GPS 14 MP Rugged Waterproof Digital Camera with 5X Optical Zoom, 2.7-inch LCD and GPS Funtionality (Green )",
         manufacturer =>"Pentax Canada", currency => "CAD", price => 387.33},
         "Pentax-WG-1-GPS");
    ok($matches13b==1, "matches13b");
}


# testMatchingB()
# Another set of tests.
sub testMatchingB
{
    my $products = [
        { product_name => "Panasonic_Lumix_DMC-FZ40", manufacturer => "Panasonic", model => "DMC-FZ40", family => "Lumix", "announced-date" => "2010-07-16T20:00:00.000-04:00"},
        { product_name => "Panasonic_Lumix_DMC-FX75", manufacturer => "Panasonic", model => "DMC-FX75", family => "Lumix", "announced-date" => "2010-05-31T20:00:00.000-04:00"},
        { product_name => "Olympus-SP610UZ", manufacturer => "Olympus", model => "SP-610 UZ", "announced-date" => "2011-02-15T19:00:00.000-05:00"},
        { product_name => "Panasonic-ZS10", manufacturer => "Panasonic", model => "DMC-ZS10", family => "Lumix", "announced-date" => "2011-01-24T19:00:00.000-05:00"},
        { product_name => "Olympus_PEN_E-P2", manufacturer => "Olympus", model => "PEN E-P2", "announced-date" => "2009-11-04T19:00:00.000-05:00"},
        { product_name => "Olympus_PEN_E-P1", manufacturer => "Olympus", model => "PEN E-P1", "announced-date" => "2009-06-15T20:00:00.000-04:00"},
        { product_name => "Olympus_PEN_E-PL1s", manufacturer => "Olympus", model => "PEN E-PL1s", "announced-date" => "2010-11-15T19:00:00.000-05:00"},
        { product_name => "Olympus_PEN_E-PL1", manufacturer => "Olympus", model => "PEN E-PL1", "announced-date" => "2010-02-02T19:00:00.000-05:00"},
        { product_name => "Olympus-E-PL2", manufacturer => "Olympus", model => "PEN E-PL2", "announced-date" => "2010-12-31T19:00:00.000-05:00"},
        { product_name => "Sony_Alpha_DSLR-A390", manufacturer => "Sony", model => "DSLR-A390", family => "Alpha", "announced-date" => "2010-06-08T20:00:00.000-04:00"},
        { product_name => "Sony_Alpha_DSLR-A290", manufacturer => "Sony", model => "DSLR-A290", family => "Alpha", "announced-date" => "2010-06-08T20:00:00.000-04:00"},
        { product_name => "Canon_EOS_Rebel_T1i", manufacturer => "Canon", model => "T1i", family => "Rebel", "announced-date" => "2009-03-24T20:00:00.000-04:00"},
        { product_name => "Canon_EOS_Rebel_T2i", manufacturer => "Canon", model => "T2i", family => "Rebel", "announced-date" => "2010-02-07T19:00:00.000-05:00"},
        { product_name => "Canon-T3i", manufacturer => "Canon", model => "T3i", family => "Rebel", "announced-date" => "2011-02-06T19:00:00.000-05:00"},
        { product_name => "Canon-T3", manufacturer => "Canon", model => "T3", family => "Rebel", "announced-date" => "2011-02-06T19:00:00.000-05:00"},
        { product_name => "Nikon_D7000", manufacturer => "Nikon", model => "D7000", "announced-date" => "2010-09-14T20:00:00.000-04:00"},
        { product_name => "Nikon_D3100", manufacturer => "Nikon", model => "D3100", "announced-date" => "2010-08-18T20:00:00.000-04:00"},
        { product_name => "Sigma_DP1s", manufacturer => "Sigma", model => "DP1s", "announced-date" => "2009-10-01T20:00:00.000-04:00"},
        { product_name => "Sigma_DP1x", manufacturer => "Sigma", model => "DP1x", "announced-date" => "2010-02-19T19:00:00.000-05:00"},
        { product_name => "Nikon_D300S", manufacturer => "Nikon", model => "D300S", "announced-date" => "2009-07-29T20:00:00.000-04:00"},
        { product_name => "Nikon_D5000", manufacturer => "Nikon", model => "D5000", "announced-date" => "2009-04-13T20:00:00.000-04:00"},
    ];
    my $listings = [ # just need to build manufacturer mapping from this list
        {manufacturer => "Panasonic"},
        {manufacturer => "Olympus"},
        {manufacturer => "Canon Canada"},
        {manufacturer => "Sony"},
        {manufacturer => "Nikon"},
        {manufacturer => "Olympus Canada"},
    ];

    my $match_heuristics = matchHeuristics->new();
    $match_heuristics->prodSystemMapManufListings($products, $listings);
    say "done map";
    $match_heuristics->prodSystemTrackProductList($products, undef);
    say "done product tracking";

    my $matchesB0 = testMatchRev($match_heuristics,
        { title => "Panasonic Lumix FZ40 Black 24x Zoom Leica Lens Taxes Included!", manufacturer => "Panasonic", currency => "CAD", price => "469.95"},
        "Panasonic_Lumix_DMC-FZ40");
    ok($matchesB0==1, "matchesB0");

    my $matchesB1 = testMatchRev($match_heuristics,
        { title => "Panasonic Lumix DMC-FZ40 Digital Camera + Best Value 8GB, Carrying Case, Mini HDMI Cable & Tripod Complete Accessories Package",
          manufacturer => "Digital", currency => "USD", price => "749.95"},
        "Panasonic_Lumix_DMC-FZ40");
    ok($matchesB1==0, "matchesB1");

    my $matchesB2 = testMatchRev($match_heuristics,
        { title => "Olympus PEN E-PL1 12.3MP Live MOS Micro Four Thirds Interchangeable Lens Digital Camera with 14-42mm f/3.5-5.6 Zuiko Digital Zoom Lens (Black)",
          manufacturer => "Olympus Canada", currency => "CAD", price => "429.98"},
          "Olympus_PEN_E-PL1");
    ok($matchesB2==1, "matchesB2");

    my $matchesB3 = testMatchRev($match_heuristics,
        { title => "Olympus PEN E-PL1 Digital Camera (Navy Blue) with Olympus 14-42mm Micro Four Thirds Lens + SSE Best Value 8GB, Deluxe Carrying Case, Batteries, Lens & Tripod Complete Accessories Package",
          manufacturer => "Digital", currency => "USD", price => "539.95"},
         "Olympus_PEN_E-PL1");
    ok($matchesB3==0, "matchesB3");

}


# testMatchingC()
# Another set of tests.  These ones are based more on examples where at one
# time listings were reported under the wrong product.
sub testMatchingC
{
    my $products = [
        { product_name => "Nikon-s6100", manufacturer => "Nikon", model => "S6100", family => "Coolpix", "announced-date" => "2011-02-08T19:00:00.000-05:00"},
        { product_name => "Nikon-L120", manufacturer => "Nikon", model => "L120", family => "Coolpix", "announced-date" => "2011-02-07T19:00:00.000-05:00"},
        { product_name => "Nikon_D7000", manufacturer => "Nikon", model => "D7000", "announced-date" => "2010-09-14T20:00:00.000-04:00"},
        { product_name => "Nikon_Coolpix_L20", manufacturer => "Nikon", model => "L20", family => "Coolpix", "announced-date" => "2009-02-02T19:00:00.000-05:00"},
        { product_name => "Nikon_D1", manufacturer => "Nikon", model => "D1", "announced-date" => "1999-06-14T20:00:00.000-04:00"},
        { product_name => "Nikon_Coolpix_L21", manufacturer => "Nikon", model => "L21", family  =>  "Coolpix",  "announced-date" => "2010-02-02T19:00:00.000-05:00"},
        { product_name => "Nikon_D300S", manufacturer => "Nikon", model => "D300S", "announced-date" => "2009-07-29T20:00:00.000-04:00"},
        { product_name => "Nikon_Coolpix_S230", manufacturer => "Nikon", model => "S230", family  =>  "Coolpix",  "announced-date" => "2009-02-02T19:00:00.000-05:00"},
        { product_name => "Nikon_Coolpix_600", manufacturer => "Nikon", model => "600", family => "Coolpix", "announced-date" => "1998-03-15T19:00:00.000-05:00"},

        { product_name => "Panasonic_Lumix_DMC-FZ40", manufacturer => "Panasonic", model => "DMC-FZ40", family  =>  "Lumix",  "announced-date" => => "2010-07-16T20:00:00.000-04:00"},
    ];
    my $listings = [ # just need to build manufacturer mapping from this list
        {manufacturer => "Panasonic"},
        {manufacturer => "Olympus"},
        {manufacturer => "Canon Canada"},
        {manufacturer => "Sony"},
        {manufacturer => "Nikon"},
        {manufacturer => "Olympus Canada"},
    ];

    my $match_heuristics = matchHeuristics->new();
    $match_heuristics->prodSystemMapManufListings($products, $listings);
    say "done map";
    $match_heuristics->prodSystemTrackProductList($products, undef);
    say "done product tracking";

    my $matchesC0 = testMatchRev($match_heuristics,
        { title => "Nikon Coolpix P80 10.1MP Digital Camera with 18x Wide Angle Optical Vibration Reduction Zoom (Black)",
          manufacturer => "Nikon", currency => "USD", price => 184.99},
        "Nikon_D1");
    ok($matchesC0==0, "matchesC0");

    my $matchesC1 = testMatchRev($match_heuristics,
        { title => "Nikon D7000 + AF-S 24-120 mm f4G ED VR", manufacturer => "Nikon", currency => "EUR", price => 2225.00},
        "Nikon_D7000");
    ok($matchesC1==1, "matchesC1");

}


# testMatchRev() -- Run a test case on the given product structure to see if
# a listing search produces the expected product name.
# Parameters:
#   $prod_struct:  product structure used in most matching algorithms
#   $listing:  listing entry similar to what would be loaded for json file
#   $prod_name:  expected product name
# Return value:
#   1 if a match occurred and produced the expected product name, 0 if not
sub testMatchRev
{
    my ( $match_heuristics, $listing, $prod_name ) = @_;
    my ( $prod, $no_manuf ) = $match_heuristics->prodSystemListingBestMatch(
                                                         $listing);
    my $matches = 0;
    if ( $no_manuf )
    {
        say "Manufacturer nonexistent.";
    }
    elsif ( defined($prod) )
    {
        my $pn = $prod->{product_name};
        say "prod_name==($prod_name), pn==($pn)";
        if ( $pn eq $prod_name )
        {
            $matches = 1;
        }
    }
    else
    {
        say "Product undefined.";
    }
    return $matches;
}



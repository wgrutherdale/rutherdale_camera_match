#!/usr/bin/env perl
# testMatchHeuristics.pl -- Test matchHeuristics.pm module.

use Modern::Perl 2013;
use autodie;

use JSON::PP; # FIXME

use FindBin;
use lib "FindBin::Bin";
use matchHeuristics;
#use Test::Simple tests => 22;
use Test::Simple tests => 22;

MAIN:
{
    #testMatching();
    testMatchingRevised();
}


# testMatching()
# Apply various test cases to determine how well doesMatch() performs.
sub testMatching
{
    my $matches0 = doesMatch( # should match
        { product_name => "Canon_PowerShot_SD980_IS", manufacturer => "Canon", model => "SD980 IS", family => "PowerShot","announced-date" => "2009-08-18T20:00:00.000-04:00" },
        { title => "Canon PowerShot SD980IS 12MP Digital Camera with 5x Ultra Wide Angle Optical Image Stabilized Zoom and 3-inch LCD (Purple)", manufacturer => "Canon", currency => "USD", price => 157.95 } );
    ok($matches0==1, "matches0");
    my $matches1 = doesMatch( # should match
        { product_name => "Nikon_D300", manufacturer => "Nikon", model => "D300", "announced-date" => "2009-07-29T20:00:00.000-04:00"},
        { title => "Nikon D300 DX 12.3MP Digital SLR Camera with 18-135mm AF-S DX f/3.5-5.6G ED-IF Nikkor Zoom Lens", manufacturer => "Nikon", currency => "USD", price => 2899.98});
    ok($matches1==1, "matches1");
    my $matches2 = doesMatch( # should not match
        { product_name => "Nikon_D300", manufacturer => "Nikon", model => "D300", "announced-date" => "2009-07-29T20:00:00.000-04:00"},
        { title => "Nikon D3000 10.2MP Digital SLR Camera Kit (Body) with WSP Mini Tripod & Cleaning set.", manufacturer => "Nikon", currency => "USD", price => 499.95});
    ok($matches2==0, "matches2");
    my $matches3 = doesMatch( # should not match
        { product_name => "Nikon_D300", manufacturer => "Nikon", model => "D300", "announced-date" => "2009-07-29T20:00:00.000-04:00"},
        { title => "Nikon D300s 12.3mp Digital SLR Camera with 3inch LCD Display (Includes Manufacturer's Supplied Accessories) with Nikon Af-s Vr Zoom-nikkor 70-300mm F/4.5-5.6g If-ed Lens + PRO Shooter Package Including Dedicated I-ttl Digital Flash + OFF Camera Flash Shoe Cord + 16gb Sdhc Memory Card + Wide Angle Lens + Telephoto Lens + Filter Kit + 2x Extended Life Batteries + Ac-dc Rapid Charger + Soft Carrying Case + Tripod & Much More !!", manufacturer => "Digital", currency => "USD", price => 2094.99});
    ok($matches3==0, "matches3");
    my $matches4 = doesMatch( # should match
        {product_name => "Nikon_D300S", manufacturer => "Nikon", model => "D300S", "announced-date" => "2009-07-29T20:00:00.000-04:00"},
        {title => "NIKON D300s (camera body only) + SLRC-201 Bag + 16 GB SDHC Memory Card + Battery EN-EL3e + AN-D300 Neck Strap (ComboKit)", manufacturer => "Nikon", currency => "GBP", price => 1618.44});
    ok($matches4==1, "matches4");
    my $matches5 = doesMatch( # should match
        {product_name => "Olympus_Stylus_Tough-3000", manufacturer => "Olympus", model => "Tough-3000", family => "Stylus", "announced-date" => "2010-01-06T19:00:00.000-05:00"},
        {title => "Olympus Stylus Tough 3000 12 MP Digital Camera with 3.6x Wide Angle Zoom and 2.7-inch LCD (Blue)", manufacturer => "Olympus Canada", currency => "CAD", price => 161.87});
    ok($matches5==1, "matches5");
    my $matches6 = doesMatch( # should match
        {product_name => "Olympus-T100",manufacturer => "Olympus", model => "T100", "announced-date" => "2010-03-20T20:00:00.000-04:00"},
        {title => "Olympus T-100 12MP Digital Camera with 3x Optical Zoom and 2.4 inch LCD (Red)", manufacturer => "Olympus Canada", currency => "CAD", price => 87.86});
    ok($matches6==1, "matches6");
    my $matches7 = doesMatch( # should match
        {product_name => "Sony_Cyber-shot_DSC-T99", manufacturer => "Sony", model => "DSC-T99", family => "Cyber-shot", "announced-date" => "2010-07-07T20:00:00.000-04:00"},
        {title => "Sony T Series DSC-T99 14.1 Megapixel DSC Camera with Super HAD CCD Image Sensor (Silver)", manufacturer => "Sony", currency => "CAD", price => 196.87});
    ok($matches7==1, "matches7");
    my $matches7a = doesMatch( # should match
        {product_name => "Sony_Cyber-shot_DSC-T99", manufacturer => "Sony", model => "DSC-T99", family => "Cyber-shot", "announced-date" => "2010-07-07T20:00:00.000-04:00"},
        {title => "Sony Cyber-shot DSC-T99 - Digital camera - compact - 14.1 Mpix - optical zoom: 4 x - supported memory: MS Duo, SD, MS PRO Duo, SDXC, MS PRO Duo Mark2, SDHC, MS PRO-HG Duo - black",
         manufacturer => "Sony", currency => "GBP", price => "235.00"});
    ok($matches7a==1, "matches7a");
    my $matches7b = doesMatch( # should match
        {product_name => "Sony_Cyber-shot_DSC-T99", manufacturer => "Sony", model => "DSC-T99", family => "Cyber-shot", "announced-date" => "2010-07-07T20:00:00.000-04:00"},
        {title => "Sony T Series DSC-T99/B 14.1 Megapixel DSC Camera with Super HAD CCD Image Sensor (Black)", manufacturer => "Sony", currency => "CAD", price => 229.99});
    ok($matches7b==1, "matches7b");
    my $matches7c = doesMatch( # should match
        {product_name => "Sony_Cyber-shot_DSC-T99", manufacturer => "Sony", model => "DSC-T99", family => "Cyber-shot", "announced-date" => "2010-07-07T20:00:00.000-04:00"},
        {title => "Sony DSCT99B Cybershot Digital Camera - Black (14.1MP, 4x Optical Zoom, 3 inch LCD)", manufacturer => "Sony", currency => "GBP", price => 156.99});
    ok($matches7c==1, "matches7c");
    my $matches7d = doesMatch( # should not match
        {product_name => "Sony_Cyber-shot_DSC-T99", manufacturer => "Sony", model => "DSC-T99", family => "Cyber-shot", "announced-date" => "2010-07-07T20:00:00.000-04:00"},
        {title => "Sony DSCT990B Cybershot Digital Camera - Black (14.1MP, 4x Optical Zoom, 3 inch LCD)", manufacturer => "Sony", currency => "GBP", price => 156.99});
    ok($matches7d==0, "matches7d");
    my $matches7e = doesMatch( # should not match
        {product_name => "Sony_Cyber-shot_DSC-T99", manufacturer => "Sony", model => "DSC-T99", family => "Cyber-shot", "announced-date" => "2010-07-07T20:00:00.000-04:00"},
        {title => "Sony Cyber-shot DSC-T993 - Digital camera - compact - 14.1 Mpix - optical zoom: 4 x - supported memory: MS Duo, SD, MS PRO Duo, SDXC, MS PRO Duo Mark2, SDHC, MS PRO-HG Duo - black",
         manufacturer => "Sony", currency => "GBP", price => "235.00"});
    ok($matches7e==0, "matches7e");
    my $matches8 = doesMatch( # should match
        {product_name => "Canon_PowerShot_SD4000_IS", manufacturer => "Canon", model => "SD4000 IS", family => "PowerShot", "announced-date" => "2010-05-10T20:00:00.000-04:00"},
        {title => "Canon PowerShot SD4000IS 10 MP CMOS Digital Camera with 3.8x Optical Zoom and f/2.0 Lens (Silver)", manufacturer => "Canon Canada", currency => "CAD", price => 372.59});
    ok($matches8==1, "matches8");
    my $matches9 = doesMatch( # should match
        {product_name => "Olympus-VR320", manufacturer => "Olympus", model => "VR320","announced-date" => "2011-02-07T19:00:00.000-05:00"},
        {title => "Olympus VR-320 228125 14 MP Digital Camera with Super-Wide 12.5x Zoom and 3.0-Inch LCD (Black)", manufacturer => "Olympus", currency => "USD", price => 199.00});
    ok($matches9==1, "matches9");
    my $matches10 = doesMatch( # should match
        {product_name => "Canon_EOS_Rebel_T1i", manufacturer => "Canon", model => "T1i", family => "Rebel", "announced-date" => "2009-03-24T20:00:00.000-04:00"},
        {title => "Canon EOS Rebel T1i 15.1 MP CMOS Digital SLR Camera with 3-Inch LCD and EF-S 18-55mm f/3.5-5.6 IS Lens", manufacturer => "Canon", currency => "CAD", price => 899.00});
    ok($matches10==1, "matches10");
    my $matches11a = doesMatch( # should not match
        {product_name => "Canon_IXUS_300_HS", manufacturer => "Canon", model => "300 HS", family => "IXUS","announced-date" => "2010-05-10T20:00:00.000-04:00"},
        {title => "Canon PowerShot ELPH 300 HS (Black)", manufacturer => "Canon Canada", currency => "CAD", price => 259.99});
    ok($matches11a==0, "matches11a");
    my $matches11b = doesMatch( # should match
        {product_name => "Canon-ELPH-300HS", manufacturer => "Canon", model => "300 HS", family => "ELPH","announced-date" => "2011-02-06T19:00:00.000-05:00"},
        {title => "Canon PowerShot ELPH 300 HS (Black)", manufacturer => "Canon Canada", currency => "CAD", price => 259.99});
    ok($matches11b==1, "matches11b");
    my $matches12a = doesMatch( # should not match
        {product_name => "Nikon_D3000", manufacturer => "Nikon", model => "D3000","announced-date" => "2009-07-29T20:00:00.000-04:00"},
        {title => "Nikon EN-EL9a 1080mAh Ultra High Capacity Li-ion Battery Pack for Nikon D40, D40x, D60, D3000, & D5000 Digital SLR Cameras", manufacturer => "Nikon", currency => "CAD", price => 29.75});
    ok($matches12a==0, "matches12a");
    my $matches12b = doesMatch( # should not match
        {product_name => "Nikon_D5000", manufacturer => "Nikon", model => "D5000","announced-date" => "2009-04-13T20:00:00.000-04:00"},
        {title => "Nikon EN-EL9a 1080mAh Ultra High Capacity Li-ion Battery Pack for Nikon D40, D40x, D60, D3000, & D5000 Digital SLR Cameras", manufacturer => "Nikon", currency => "CAD", price => 29.75});
    ok($matches12b==0, "matches12b");
    my $matches13a = doesMatch( # should match
        {product_name => "Pentax-WG-1-GPS", manufacturer => "Pentax", model => "WG-1 GPS", family => "Optio","announced-date" => "2011-02-06T19:00:00.000-05:00"},
        {title => "PENTAX Optio WG-1 GPS 14 MP Rugged Waterproof Digital Camera with 5X Optical Zoom, 2.7-inch LCD and GPS Funtionality (Green )", manufacturer => "Pentax Canada", currency => "CAD", price => 387.33});
    ok($matches13a==1, "matches13a");
    my $matches13b = doesMatch( # should not match
        {product_name => "Pentax-WG-1", manufacturer => "Pentax", model => "WG-1", family => "Optio","announced-date" => "2011-02-06T19:00:00.000-05:00"},
        {title => "PENTAX Optio WG-1 GPS 14 MP Rugged Waterproof Digital Camera with 5X Optical Zoom, 2.7-inch LCD and GPS Funtionality (Green )", manufacturer =>"Pentax Canada", currency => "CAD", price => 387.33});
    ok($matches13b==0, "matches13b");
}


sub testMatchingRevised
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
    my $prod_struct = prodSystemInit();
    prodSystemMapManufListings( $prod_struct, $products, $listings);
    say "done map";
    foreach my $prod ( @$products )
    {
        prodSystemTrackProduct($prod_struct, $prod);
    }
    say "done product tracking";

    my $matches0 = testMatchRev($prod_struct,
        { title => "Canon PowerShot SD980IS 12MP Digital Camera with 5x Ultra Wide Angle Optical Image Stabilized Zoom and 3-inch LCD (Purple)", manufacturer => "Canon", currency => "USD", price => 157.95 },
        "Canon_PowerShot_SD980_IS", 1);
    ok($matches0==1, "matches0");

    my $matches1 = testMatchRev($prod_struct,
        { title => "Nikon D300 DX 12.3MP Digital SLR Camera with 18-135mm AF-S DX f/3.5-5.6G ED-IF Nikkor Zoom Lens", manufacturer => "Nikon", currency => "USD", price => 2899.98},
        "Nikon_D300", 1);
    ok($matches1==1, "matches1");

    my $matches2 = testMatchRev($prod_struct,
        { title => "Nikon D3000 10.2MP Digital SLR Camera Kit (Body) with WSP Mini Tripod & Cleaning set.",
          manufacturer => "Nikon", currency => "USD", price => 499.95},
          "Nikon_D3000", 1);
    ok($matches2==1, "matches2");

    my $matches3 = testMatchRev($prod_struct,
        { title => "Nikon D300s 12.3mp Digital SLR Camera with 3inch LCD Display (Includes Manufacturer's Supplied Accessories) with Nikon Af-s Vr Zoom-nikkor 70-300mm F/4.5-5.6g If-ed Lens + PRO Shooter Package Including Dedicated I-ttl Digital Flash + OFF Camera Flash Shoe Cord + 16gb Sdhc Memory Card + Wide Angle Lens + Telephoto Lens + Filter Kit + 2x Extended Life Batteries + Ac-dc Rapid Charger + Soft Carrying Case + Tripod & Much More !!",
          manufacturer => "Digital", currency => "USD", price => 2094.99},
          "Nikon_D300S", 1);
    say "matches3==($matches3)";
    ok($matches3==0, "matches3");

    my $matches4 = testMatchRev($prod_struct,
        {title => "NIKON D300s (camera body only) + SLRC-201 Bag + 16 GB SDHC Memory Card + Battery EN-EL3e + AN-D300 Neck Strap (ComboKit)",
         manufacturer => "Nikon", currency => "GBP", price => 1618.44},
         "Nikon_D300S", 1);
    ok($matches4==1, "matches4");

    my $matches5 = testMatchRev($prod_struct,
        {title => "Olympus Stylus Tough 3000 12 MP Digital Camera with 3.6x Wide Angle Zoom and 2.7-inch LCD (Blue)",
         manufacturer => "Olympus Canada", currency => "CAD", price => 161.87},
         "Olympus_Stylus_Tough-3000", 1);
    ok($matches5==1, "matches5");

    my $matches6 = testMatchRev($prod_struct,
        {title => "Olympus T-100 12MP Digital Camera with 3x Optical Zoom and 2.4 inch LCD (Red)",
         manufacturer => "Olympus Canada", currency => "CAD", price => 87.86},
         "Olympus-T100", 1);
    ok($matches6==1, "matches6");

    my $matches7 = testMatchRev($prod_struct,
        {title => "Sony T Series DSC-T99 14.1 Megapixel DSC Camera with Super HAD CCD Image Sensor (Silver)",
         manufacturer => "Sony", currency => "CAD", price => 196.87},
         "Sony_Cyber-shot_DSC-T99", 1);
    ok($matches7==1, "matches7");

    my $matches7a = testMatchRev($prod_struct,
        {title => "Sony Cyber-shot DSC-T99 - Digital camera - compact - 14.1 Mpix - optical zoom: 4 x - supported memory: MS Duo, SD, MS PRO Duo, SDXC, MS PRO Duo Mark2, SDHC, MS PRO-HG Duo - black",
         manufacturer => "Sony", currency => "GBP", price => "235.00"},
         "Sony_Cyber-shot_DSC-T99", 1);
    ok($matches7a==1, "matches7a");

    my $matches7b = testMatchRev($prod_struct,
        {title => "Sony T Series DSC-T99/B 14.1 Megapixel DSC Camera with Super HAD CCD Image Sensor (Black)",
         manufacturer => "Sony", currency => "CAD", price => 229.99},
         "Sony_Cyber-shot_DSC-T99", 1);
    ok($matches7b==1, "matches7b");

    my $matches7c = testMatchRev($prod_struct,
        {title => "Sony DSCT99B Cybershot Digital Camera - Black (14.1MP, 4x Optical Zoom, 3 inch LCD)",
         manufacturer => "Sony", currency => "GBP", price => 156.99},
         "Sony_Cyber-shot_DSC-T99", 1);
    ok($matches7c==1, "matches7c");

    my $matches7d = testMatchRev($prod_struct,
        {title => "Sony DSCT990B Cybershot Digital Camera - Black (14.1MP, 4x Optical Zoom, 3 inch LCD)",
         manufacturer => "Sony", currency => "GBP", price => 156.99},
         "Sony_Cyber-shot_DSC-T99", 1);
    ok($matches7d==1, "matches7d");
    # in larger set of products this should not be accepted

    my $matches7e = testMatchRev($prod_struct,
        {title => "Sony Cyber-shot DSC-T993 - Digital camera - compact - 14.1 Mpix - optical zoom: 4 x - supported memory: MS Duo, SD, MS PRO Duo, SDXC, MS PRO Duo Mark2, SDHC, MS PRO-HG Duo - black",
         manufacturer => "Sony", currency => "GBP", price => "235.00"},
          "Sony_Cyber-shot_DSC-T99", 1);
    ok($matches7e==1, "matches7e");
    # in larger set of products this should not be accepted

    my $matches8 = testMatchRev($prod_struct,
        {title => "Canon PowerShot SD4000IS 10 MP CMOS Digital Camera with 3.8x Optical Zoom and f/2.0 Lens (Silver)",
         manufacturer => "Canon Canada", currency => "CAD", price => 372.59},
         "Canon_PowerShot_SD4000_IS", 1);
    ok($matches8==1, "matches8");

    my $matches9 = testMatchRev($prod_struct,
        {title => "Olympus VR-320 228125 14 MP Digital Camera with Super-Wide 12.5x Zoom and 3.0-Inch LCD (Black)",
         manufacturer => "Olympus", currency => "USD", price => 199.00},
         "Olympus-VR320", 1);
    ok($matches9==1, "matches9");

    my $matches10 = testMatchRev($prod_struct,
        {title => "Canon EOS Rebel T1i 15.1 MP CMOS Digital SLR Camera with 3-Inch LCD and EF-S 18-55mm f/3.5-5.6 IS Lens",
         manufacturer => "Canon", currency => "CAD", price => 899.00},
         "Canon_EOS_Rebel_T1i", 1);
    ok($matches10==1, "matches10");

    my $matches11a = testMatchRev($prod_struct,
        {title => "Canon PowerShot ELPH 300 HS (Black)",
         manufacturer => "Canon Canada", currency => "CAD", price => 259.99},
         "Canon-ELPH-300HS", 1);
    ok($matches11a==1, "matches11a");
    # in larger set of products this should not be accepted

    my $matches11b = testMatchRev($prod_struct,
        {title => "Canon PowerShot ELPH 300 HS (Black)",
         manufacturer => "Canon Canada", currency => "CAD", price => 259.99},
         "Canon-ELPH-300HS", 1);
    ok($matches11b==1, "matches11b");

    my $matches12a = testMatchRev($prod_struct,
        {title => "Nikon EN-EL9a 1080mAh Ultra High Capacity Li-ion Battery Pack for Nikon D40, D40x, D60, D3000, & D5000 Digital SLR Cameras",
         manufacturer => "Nikon", currency => "CAD", price => 29.75},
         "Nikon_D3000", 1);
    ok($matches12a==1, "matches12a");
    # in larger set of products this should not be accepted

    my $matches12b = testMatchRev($prod_struct,
        {title => "Nikon EN-EL9a 1080mAh Ultra High Capacity Li-ion Battery Pack for Nikon D40, D40x, D60, D3000, & D5000 Digital SLR Cameras",
         manufacturer => "Nikon", currency => "CAD", price => 29.75},
         "Nikon_D5000", 1);
    ok($matches12b==0, "matches12b");
    # in larger set of products this should not be accepted

    my $matches13a = testMatchRev($prod_struct,
        {title => "PENTAX Optio WG-1 GPS 14 MP Rugged Waterproof Digital Camera with 5X Optical Zoom, 2.7-inch LCD and GPS Funtionality (Green )",
         manufacturer => "Pentax Canada", currency => "CAD", price => 387.33},
         "Pentax-WG-1-GPS", 1);
    ok($matches13a==1, "matches13a");

    my $matches13b = testMatchRev($prod_struct,
        {title => "PENTAX Optio WG-1 GPS 14 MP Rugged Waterproof Digital Camera with 5X Optical Zoom, 2.7-inch LCD and GPS Funtionality (Green )",
         manufacturer =>"Pentax Canada", currency => "CAD", price => 387.33},
         "Pentax-WG-1-GPS", 1);
    ok($matches13b==1, "matches13b");
}


sub testMatchRev
{
    my ( $prod_struct, $listing, $prod_name, $eq ) = @_;
    my ( $prod, $no_manuf ) = prodSystemListingBestMatch($prod_struct,
                                                         $listing);
    my $matches = 0;
    if ( defined($prod) )
    {
        my $pn = $prod->{product_name};
        say "prod_name==($prod_name), pn==($pn)";
        if ( ($eq==1 and $pn eq $prod_name) or
             ($eq==0 and $pn ne $prod_name ) )
        {
            $matches = 1;
        }
    }
    else
    {
        say "prod undefined";
    }
    return $matches;
}


# Test version of load routine.  FIXME
sub getJsonTextTest
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

#!/usr/bin/env perl
# testMatchHeuristics.pl -- Test matchHeuristics.pm module.

use Modern::Perl 2013;
use autodie;

use FindBin;
use lib "FindBin::Bin";
use matchHeuristics;
use Test::Simple tests => 16;

MAIN:
{
    testMatching();
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
}



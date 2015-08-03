#!/usr/bin/env perl
# NaiveBayesianAccumulator.pm -- Accumulator for Naive Bayesian inference.

package NaiveBayesianAccumulator;

use Modern::Perl 2013;
use autodie;


# NaiveBayesianAccumulator::new() -- Constructor for NaiveBayesianAccumulator
# class.
sub new
{
    my $classname = shift;
    my $self = { };
    bless($self, $classname);
    $self->{eta} = 0.0; # Accumulates log-based probability.
    return $self;
}


# NaiveBayesianAccumulator::accumulate() -- Given probability value in (0, 1),
# accumulate it.
sub accumulate
{
    my $self = shift;
    my ( $d ) = @_;
    $self->{eta} += log(1.0-$d) - log($d)  if ( $d>0.0 and $d<1.0 );
}


# NaiveBayesianAccumulator::predict() -- Given accumulated Bayesian
# probabilities, return the currently predicted probability.
sub predict
{
    my $self = shift;
    return 1.0/(1.0+exp($self->{eta}));
}


1;

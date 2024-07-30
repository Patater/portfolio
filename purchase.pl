#!/usr/bin/env perl

# purchase.pl
# Patater Portfolio Utils
#
# Created by Jaeden Amero on 2024-07-30.
# Copyright 2024. SPDX-License-Identifier: AGPL-3.0-or-later

use strict;
use warnings;
use lib 'lib';
use List::Util qw(sum);
use PortfolioUtils qw(print_adjustments print_portfolio);

# Allocate new funds to move the portfolio closer to the target allocation
# without selling any existing investments. The intention is to use this
# monthly to determine how best to use the any new monthly investment funds.
sub allocate_funds {
    my ($target_allocation, $portfolio, $monthly_investment) = @_;

    # Calculate the total value of the portfolio.
    my $total_value = sum values %$portfolio;

    # Calculate the current asset allocations.
    my %current_allocation =
      map { $_ => $portfolio->{$_} / $total_value }
      keys %$portfolio;

    # Calculate the deviation from target.
    my %deviation =
      map { $_ => $target_allocation->{$_} - ($current_allocation{$_} // 0) }
      keys %$target_allocation;

    # Determine which funds are underrepresented.
    my %underrepresented = map { $_ => $deviation{$_} }
      grep { $deviation{$_} > 0 } keys %deviation;

    # Allocate the funds proportionally.
    my $total_deviation = sum values %underrepresented;
    my %adjustments =
      map { $_ => ($deviation{$_} / $total_deviation) * $monthly_investment }
      keys %underrepresented;

    # Update the portfolio with the investments.
    @$portfolio{keys %adjustments} =
      map { $portfolio->{$_} + $adjustments{$_} }
      keys %adjustments;

    return ($portfolio, \%adjustments);
}

sub main {

    my %target_allocation = (
        'Fund A' => 0.50,
        'Fund B' => 0.30,
        'Fund C' => 0.20
    );

    my %actual_portfolio = (
        'Fund A' => 50000,
        'Fund B' => 20000,
        'Fund C' => 10000
    );

    my $monthly_investment = 10000;

    print "Current Portfolio:\n";
    print_portfolio(\%actual_portfolio, \%target_allocation);
    print "\n";

    my ($updated_portfolio, $adjustments) =
      allocate_funds(\%target_allocation, \%actual_portfolio,
        $monthly_investment);

    # Print buy amounts
    print_adjustments($adjustments);
    print "\n";

    print "Resulting Portfolio:\n";
    print_portfolio($updated_portfolio, \%target_allocation);
}

main();

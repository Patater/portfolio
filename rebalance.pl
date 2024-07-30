#!/usr/bin/env perl

# rebalance.pl
# Patater Portfolio Utils
#
# Created by Jaeden Amero on 2024-07-30.
# Copyright 2024. SPDX-License-Identifier: AGPL-3.0-or-later

use strict;
use warnings;
use lib 'lib';
use List::Util qw(sum);
use PortfolioUtils qw(print_adjustments print_portfolio);

# Rebalance the portfolio to match the target allocation. When rebalancing,
# selling is permitted to move closer to the target portfolio than buying alone
# could accomplish.
sub rebalance_portfolio {
    my ($target_allocation, $portfolio, $monthly_investment) = @_;

    # Calculate the total value of the portfolio.
    my $total_value = sum values %$portfolio;

    # Add the monthly investment to the total value.
    $total_value += $monthly_investment;

    # Calculate the target amounts for each fund.
    my %target_values = map { $_ => $target_allocation->{$_} * $total_value }
      keys %$target_allocation;

    # Calculate the required buy/sell amounts for each fund to achieve the
    # target allocations.
    my %adjustments =
      map { $_ => $target_values{$_} - ($portfolio->{$_} // 0) }
      keys %$target_allocation;

    # Execute the buy/sell operations.
    my %rebalanced_portfolio = %$portfolio;
    @rebalanced_portfolio{keys %adjustments} =
      map { $rebalanced_portfolio{$_} + $adjustments{$_} }
      keys %adjustments;

    return (\%rebalanced_portfolio, \%adjustments);
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

    my ($rebalanced_portfolio, $adjustments) =
      rebalance_portfolio(\%target_allocation, \%actual_portfolio,
        $monthly_investment);

    print_adjustments($adjustments);
    print "\n";

    print "Rebalanced Portfolio:\n";
    print_portfolio($rebalanced_portfolio, \%target_allocation);
}

main();

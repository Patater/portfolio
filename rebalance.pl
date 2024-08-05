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
use PortfolioUtils
  qw(print_adjustments print_comparison print_portfolio read_csv);

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
    my $target_allocation = read_csv('target.csv', 'Symbol', 'Ratio');
    my $actual_portfolio = read_csv('holdings.csv', 'Symbol', 'Amount');
    my $monthly_investment = 10000;

    my $old_portfolio = {%$actual_portfolio};

    my ($rebalanced_portfolio, $adjustments) =
      rebalance_portfolio($target_allocation, $actual_portfolio,
        $monthly_investment);

    print_adjustments($adjustments);
    print "\n";

    print "Comparison:\n";
    print_comparison($old_portfolio, $rebalanced_portfolio,
        $target_allocation);
}

main();

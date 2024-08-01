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
use PortfolioUtils qw(print_adjustments print_portfolio read_csv);

# Allocate new funds to move the portfolio closer to the target allocation
# without selling any existing investments. The intention is to use this
# monthly to determine how best to use the any new monthly investment funds.
sub allocate_funds {
    my ($target_allocation, $portfolio, $monthly_investment) = @_;

    # Calculate the total value of the portfolio.
    my $total_value = sum values %$portfolio;
    my $new_total = $total_value + $monthly_investment;

    # Calculate the current asset allocations accounting for the new
    # investment.
    my %current_allocation =
      map { $_ => $portfolio->{$_} / $new_total }
      keys %$portfolio;

    # Calculate the deviation from target.
    my %deviation =
      map { $_ => $target_allocation->{$_} - ($current_allocation{$_} // 0) }
      keys %$target_allocation;

    # Determine which funds are underrepresented.
    my %underrepresented = map { $_ => $deviation{$_} }
      grep { $deviation{$_} > 0 } keys %deviation;

    # Allocate the funds proportionally according to their distance from
    # target. Limit the new investment in the deviation to ensure that if, for
    # example, the monthly investment is large, the underrepresented funds
    # don't become over represented.
    my $total_deviation = sum values %underrepresented;
    sub cap { $_[0] > $_[1] ? $_[1] : $_[0] }
    my %adjustments = map {
        $_ => cap(($deviation{$_} / $total_deviation) * $monthly_investment,
            $deviation{$_} * $new_total)
    } keys %underrepresented;

    my %purchases = map { $_ => $adjustments{$_} }
      grep { $adjustments{$_} > 0 } keys %adjustments;

    # Update the portfolio with the investments.
    @$portfolio{keys %adjustments} =
      map { $portfolio->{$_} + $adjustments{$_} }
      keys %adjustments;

    return ($portfolio, \%adjustments);
}

sub main {
    my $target_allocation = read_csv('target.csv', 'Symbol', 'Ratio');

    # Verify target allocations sum to about 1 (within an epsilon)
    my $whole = sum values %$target_allocation;
    if ($whole - 1e-4 > 1.0) {
        die "Target allocation does not sum to 1";
    }

    my $actual_portfolio = read_csv('holdings.csv', 'Symbol', 'Amount');
    my $monthly_investment = 10000;

    print "Current Portfolio:\n";
    print_portfolio($actual_portfolio, $target_allocation);
    print "\n";

    my ($updated_portfolio, $adjustments) =
      allocate_funds($target_allocation, $actual_portfolio,
        $monthly_investment);

    # Print buy amounts
    print_adjustments($adjustments);
    print "\n";

    print "Resulting Portfolio:\n";
    print_portfolio($updated_portfolio, $target_allocation);
}

main();

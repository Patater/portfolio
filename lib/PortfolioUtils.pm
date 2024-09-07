# PortfolioUtils.pm
# Patater Portfolio Utils
#
# Created by Jaeden Amero on 2024-07-30.
# Copyright 2024. SPDX-License-Identifier: AGPL-3.0-or-later

package PortfolioUtils;

use strict;
use warnings;
use List::Util qw(sum);
use Text::CSV qw(csv);
use Exporter qw(import);

our @EXPORT_OK =
  qw(allocate_funds print_adjustments print_comparison print_portfolio read_csv rebalance_portfolio);

# Print the buy/sell adjustments
sub print_adjustments {
    my ($adjustments) = @_;
    print "Adjustments (Buy/Sell amounts):\n";
    printf "%s: %s %.2f\n", $_,
      $adjustments->{$_} >= 0 ? "Buy " : "Sell", abs($adjustments->{$_})
      for sort keys %$adjustments;
}

# Print the portfolio details including comparison to target allocation (if
# provided)
sub print_portfolio {
    my ($portfolio, $target_allocation) = @_;
    my $total_value = sum values %$portfolio;

    for my $fund (sort keys %$portfolio) {
        my $value = $portfolio->{$fund};
        my $percentage = ($value / $total_value) * 100;

        printf "%s: %.2f (%.2f%%", $fund, $value, $percentage;

        if ($target_allocation && exists $target_allocation->{$fund}) {
            printf " vs %.2f%%", $target_allocation->{$fund} * 100;
        }

        print ")\n";
    }
}

# Print a comparison of allocation between two the provided portfolios)
sub print_comparison {
    my ($portfolio_a, $portfolio_b, $target_allocation) = @_;
    my $total_value_a = sum values %$portfolio_a;
    my $total_value_b = sum values %$portfolio_b;

    for my $fund (sort keys %$portfolio_a) {
        my $value_a = $portfolio_a->{$fund};
        my $percentage_a = ($value_a / $total_value_a) * 100;
        my $value_b = $portfolio_b->{$fund};
        my $percentage_b = ($value_b / $total_value_b) * 100;

        printf "%s: %.2f => %.2f ", $fund, $value_a, $value_b;
        printf "(%.2f%% => %.2f%%", $percentage_a, $percentage_b;

        if ($target_allocation && exists $target_allocation->{$fund}) {
            printf " [%.2f%%]", $target_allocation->{$fund} * 100;
        }

        print ")\n";
    }
}

# Read a hash from two columns of a CSV file
sub read_csv {
    my ($file_path, $key, $value) = @_;

    my $ref = csv(
        in => $file_path,
        key => $key,
        value => $value
    );

    return $ref;
}

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

# Allocate new funds to move the portfolio closer to the target allocation
# without selling any existing investments. The intention is to use this
# monthly to determine how best to use the any new monthly investment funds.
sub allocate_funds {
    my ($target_allocation, $portfolio, $cash, $monthly_investment) = @_;

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

    # Determine which cash funds are over represented.
    my %cash_over =
      map { $_ => $deviation{$_} } grep { $deviation{$_} < 0 } keys %$cash;

    # Sell any excess cash and add it to the available investment pool
    my %adjustments =
      map { $_ => $deviation{$_} * $new_total } keys %cash_over;
    my $cash_avail = sum(map { abs($_) } values %adjustments) // 0;
    my $investment = $monthly_investment + $cash_avail;

    # Determine which funds are underrepresented.
    my %underrepresented = map { $_ => $deviation{$_} }
      grep { $deviation{$_} > 0 } keys %deviation;

    # Allocate the funds proportionally according to their distance from
    # target. Limit the new investment in the deviation to ensure that if, for
    # example, the monthly investment is large, the underrepresented funds
    # don't become over represented.
    my $total_deviation = sum values %underrepresented;
    sub cap { $_[0] > $_[1] ? $_[1] : $_[0] }
    @adjustments{keys %underrepresented} = map {
        cap(($deviation{$_} / $total_deviation) * $investment,
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

1;

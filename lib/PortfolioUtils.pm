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
  qw(print_adjustments print_comparison print_portfolio read_csv);

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

1;

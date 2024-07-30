# PortfolioUtils.pm
# Patater Portfolio Utils
#
# Created by Jaeden Amero on 2024-07-30.
# Copyright 2024. SPDX-License-Identifier: AGPL-3.0-or-later

package PortfolioUtils;

use strict;
use warnings;
use List::Util qw(sum);
use Exporter qw(import);

our @EXPORT_OK = qw(print_adjustments print_portfolio);

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

1;

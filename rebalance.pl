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
  qw(print_adjustments print_comparison print_portfolio read_csv rebalance_portfolio);

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

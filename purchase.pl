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
use PortfolioUtils
  qw(allocate_funds print_adjustments print_comparison print_portfolio read_csv);

sub main {
    my $target_allocation = read_csv('target.csv', 'Symbol', 'Ratio');

    # Verify target allocations sum to about 1 (within an epsilon)
    my $whole = sum values %$target_allocation;
    if ($whole - 1e-4 > 1.0) {
        die "Target allocation does not sum to 1";
    }

    my $actual_portfolio = read_csv('holdings.csv', 'Symbol', 'Amount');
    my $cash = read_csv('cash.csv', 'Symbol', 'IsCash?');
    my $monthly_investment = 10000;

    my $old_portfolio = {%$actual_portfolio};

    my ($updated_portfolio, $adjustments) =
      allocate_funds($target_allocation, $actual_portfolio,
        $cash, $monthly_investment);

    # Print buy amounts
    print_adjustments($adjustments);
    print "\n";

    print "Comparison:\n";
    print_comparison($old_portfolio, $updated_portfolio, $target_allocation);
}

main();

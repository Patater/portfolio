#!/usr/bin/env perl

# rebalance.t
# Patater Portfolio Utils
#
# Created by Jaeden Amero on 2024-08-06.
# Copyright 2024. SPDX-License-Identifier: AGPL-3.0-or-later

use strict;
use warnings;
use Test::More;
use List::Util qw(sum);
use PortfolioUtils qw(rebalance_portfolio);

# Helper function to check if two floating point numbers are close enough.
sub float_cmp {
    my ($a, $b, $epsilon) = @_;
    $epsilon //= 0.01;
    return abs($a - $b) < $epsilon;
}

my $target_allocation = {'Fund A' => 0.5, 'Fund B' => 0.3, 'Fund C' => 0.2};

subtest 'Rebalance underweight portfolio' => sub {
    my $actual_portfolio =
      {'Fund A' => 40000, 'Fund B' => 30000, 'Fund C' => 10000};
    my $monthly_investment = 20000;
    my ($rebalanced_portfolio, $adjustments) =
      rebalance_portfolio($target_allocation, $actual_portfolio,
        $monthly_investment);

    cmp_ok($adjustments->{'Fund A'}, '>', 0, 'Fund A should be bought');
    ok(float_cmp($adjustments->{'Fund B'} // 0, 0),
        'Fund B should remain the same');
    cmp_ok($adjustments->{'Fund C'}, '>', 0, 'Fund C should be bought');
};

subtest 'Rebalance overweight portfolio' => sub {
    my $actual_portfolio =
      {'Fund A' => 60000, 'Fund B' => 30000, 'Fund C' => 30000};
    my $monthly_investment = 0;
    my ($rebalanced_portfolio, $adjustments) =
      rebalance_portfolio($target_allocation, $actual_portfolio,
        $monthly_investment);

    cmp_ok($adjustments->{'Fund A'}, '==', 0, 'Fund A should remain the same');
    cmp_ok($adjustments->{'Fund B'}, '>', 0, 'Fund B should be bought');
    cmp_ok($adjustments->{'Fund C'}, '<', 0, 'Fund C should be sold');
};

subtest 'Total adjustments equal monthly investment for balanced portfolio' =>
  sub {
    my $actual_portfolio =
      {'Fund A' => 50000, 'Fund B' => 30000, 'Fund C' => 20000};
    my $monthly_investment = 10000;
    my ($rebalanced_portfolio, $adjustments) =
      rebalance_portfolio($target_allocation, $actual_portfolio,
        $monthly_investment);

    ok(
        float_cmp(sum(values %$adjustments), $monthly_investment),
        'Sum of adjustments equals monthly investment'
    );
  };

subtest 'New investment in balanced portfolio maintains target allocation' =>
  sub {
    my $actual_portfolio =
      {'Fund A' => 50000, 'Fund B' => 30000, 'Fund C' => 20000};
    my $monthly_investment = 10000;
    my ($rebalanced_portfolio, $adjustments) =
      rebalance_portfolio($target_allocation, $actual_portfolio,
        $monthly_investment);

    my $new_total = sum(values %$rebalanced_portfolio);
    ok(
        float_cmp(
            $rebalanced_portfolio->{'Fund A'} / $new_total,
            $target_allocation->{'Fund A'}
        ),
        "Rebalanced 'Fund A' matches target allocation"
    );
    ok(
        float_cmp(
            $rebalanced_portfolio->{'Fund B'} / $new_total,
            $target_allocation->{'Fund B'}
        ),
        "Rebalanced 'Fund B' matches target allocation"
    );
    ok(
        float_cmp(
            $rebalanced_portfolio->{'Fund C'} / $new_total,
            $target_allocation->{'Fund C'}
        ),
        "Rebalanced 'Fund C' matches target allocation"
    );
  };

subtest 'Total adjustments equal monthly investment for empty portfolio' =>
  sub {
    my $actual_portfolio = {'Fund A' => 0, 'Fund B' => 0, 'Fund C' => 0};
    my $monthly_investment = 10000;
    my ($rebalanced_portfolio, $adjustments) =
      rebalance_portfolio($target_allocation, $actual_portfolio,
        $monthly_investment);

    ok(
        float_cmp(sum(values %$adjustments), $monthly_investment),
        'Sum of adjustments equals monthly investment'
    );
  };

subtest 'Adjustments match target allocation for empty portfolio' => sub {
    my $actual_portfolio = {'Fund A' => 0, 'Fund B' => 0, 'Fund C' => 0};
    my $monthly_investment = 10000;
    my ($rebalanced_portfolio, $adjustments) =
      rebalance_portfolio($target_allocation, $actual_portfolio,
        $monthly_investment);

    ok(
        float_cmp(
            $adjustments->{'Fund A'},
            $target_allocation->{'Fund A'} * $monthly_investment
        ),
        "Adjustment for 'Fund A' matches target allocation"
    );
    ok(
        float_cmp(
            $adjustments->{'Fund B'},
            $target_allocation->{'Fund B'} * $monthly_investment
        ),
        "Adjustment for 'Fund B' matches target allocation"
    );
    ok(
        float_cmp(
            $adjustments->{'Fund C'},
            $target_allocation->{'Fund C'} * $monthly_investment
        ),
        "Adjustment for 'Fund C' matches target allocation"
    );
};

subtest 'Rebalanced portfolio has only positive allocations' => sub {
    my $actual_portfolio =
      {'Fund A' => 1000, 'Fund B' => 500, 'Fund C' => 100};
    my $monthly_investment = 0;
    my ($rebalanced_portfolio, $adjustments) =
      rebalance_portfolio($target_allocation, $actual_portfolio,
        $monthly_investment);

    cmp_ok($rebalanced_portfolio->{'Fund A'},
        '>=', 0, "Rebalanced 'Fund A' should not be negative");
    cmp_ok($rebalanced_portfolio->{'Fund B'},
        '>=', 0, "Rebalanced 'Fund B' should not be negative");
    cmp_ok($rebalanced_portfolio->{'Fund C'},
        '>=', 0, "Rebalanced 'Fund C' should not be negative");
};

subtest 'Sum of rounded adjustments should equal monthly investment' => sub {
    my $actual_portfolio =
      {'Fund A' => 50000, 'Fund B' => 30000, 'Fund C' => 20000};
    my $monthly_investment = 9.99; # An amount that might cause rounding issues
    my ($rebalanced_portfolio, $adjustments) =
      rebalance_portfolio($target_allocation, $actual_portfolio,
        $monthly_investment);

    my $total_adjustments =
      sum map { sprintf("%.2f", $_) } values %$adjustments;
    ok(
        float_cmp($total_adjustments, $monthly_investment),
        'Total adjustments equal monthly investment'
    );
};

done_testing();

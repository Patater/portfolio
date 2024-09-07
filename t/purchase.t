#!/usr/bin/env perl

# purchase.t
# Patater Portfolio Utils
#
# Created by Jaeden Amero on 2024-08-06.
# Copyright 2024. SPDX-License-Identifier: AGPL-3.0-or-later

use strict;
use warnings;
use Test::More;
use List::Util qw(sum);
use lib 'lib';
use PortfolioUtils qw(allocate_funds);

# Helper function to check if two floating point numbers are close enough.
sub float_cmp {
    my ($a, $b, $epsilon) = @_;
    $epsilon //= 0.01;
    return abs($a - $b) < $epsilon;
}

my $target_allocation = {'Fund A' => 0.5, 'Fund B' => 0.3, 'Fund C' => 0.2};
my $target_allocation_cash =
  {'Fund A' => 0.48, 'Fund B' => 0.3, 'Fund C' => 0.2, 'Cash' => 0.02};

subtest 'Investment plan is correct for normal allocation' => sub {
    my $actual_portfolio =
      {'Fund A' => 50000, 'Fund B' => 20000, 'Fund C' => 10000};
    my $monthly_investment = 10000;
    my (undef, $investment_plan) =
      allocate_funds($target_allocation, $actual_portfolio,
        {}, $monthly_investment);

    ok(float_cmp($investment_plan->{'Fund A'} // 0, 0),
        'No new investment in Fund A');
    ok(float_cmp($investment_plan->{'Fund B'}, 4666.66),
        'Correct investment in Fund B');
    ok(float_cmp($investment_plan->{'Fund C'}, 5333.33),
        'Correct investment in Fund C');
};

subtest 'Investment plan maintains balance for already balanced portfolio' =>
  sub {
    my $actual_portfolio =
      {'Fund A' => 50000, 'Fund B' => 30000, 'Fund C' => 20000};
    my $monthly_investment = 10000;
    my (undef, $investment_plan) =
      allocate_funds($target_allocation, $actual_portfolio,
        {}, $monthly_investment);

    ok(float_cmp($investment_plan->{'Fund A'}, 5000),
        'Correct investment in Fund A');
    ok(float_cmp($investment_plan->{'Fund B'}, 3000),
        'Correct investment in Fund B');
    ok(float_cmp($investment_plan->{'Fund C'}, 2000),
        'Correct investment in Fund C');
  };

subtest 'Investment plan is correct for empty portfolio' => sub {
    my $actual_portfolio = {'Fund A' => 0, 'Fund B' => 0, 'Fund C' => 0};
    my $monthly_investment = 10000;
    my (undef, $investment_plan) =
      allocate_funds($target_allocation, $actual_portfolio,
        {}, $monthly_investment);

    ok(float_cmp($investment_plan->{'Fund A'}, 5000),
        'Correct investment in Fund A');
    ok(float_cmp($investment_plan->{'Fund B'}, 3000),
        'Correct investment in Fund B');
    ok(float_cmp($investment_plan->{'Fund C'}, 2000),
        'Correct investment in Fund C');
};

subtest 'Investment plan does not sell overweight fund' => sub {
    my $actual_portfolio =
      {'Fund A' => 70000, 'Fund B' => 20000, 'Fund C' => 10000};
    my $monthly_investment = 10000;
    my (undef, $investment_plan) =
      allocate_funds($target_allocation, $actual_portfolio,
        {}, $monthly_investment);

    ok(float_cmp($investment_plan->{'Fund A'} // 0, 0), 'Fund A is unsold');
};

subtest 'Total investment matches monthly investment' => sub {
    my $actual_portfolio =
      {'Fund A' => 50000, 'Fund B' => 20000, 'Fund C' => 10000};
    my $monthly_investment = 10000;
    my (undef, $investment_plan) =
      allocate_funds($target_allocation, $actual_portfolio,
        {}, $monthly_investment);

    my $total_invested = sum(values %$investment_plan);
    ok(float_cmp($total_invested - $monthly_investment, 0),
        'No change in Fund A');
};

subtest 'Updated portfolio reflects investments' => sub {
    my $actual_portfolio =
      {'Fund A' => 50000, 'Fund B' => 20000, 'Fund C' => 10000};
    my $old_portfolio = {%$actual_portfolio};
    my $monthly_investment = 10000;
    my ($updated_portfolio, $investment_plan) =
      allocate_funds($target_allocation, $actual_portfolio,
        {}, $monthly_investment);

    ok(
        float_cmp(
            $updated_portfolio->{'Fund A'},
            $old_portfolio->{'Fund A'} + ($investment_plan->{'Fund A'} // 0)
        ),
        'Updated Fund A is sum of old portfolio and investment plan'
    );
    ok(
        float_cmp(
            $updated_portfolio->{'Fund B'},
            $old_portfolio->{'Fund B'} + ($investment_plan->{'Fund B'} // 0)
        ),
        'Updated Fund B is sum of old portfolio and investment plan'
    );
    ok(
        float_cmp(
            $updated_portfolio->{'Fund C'},
            $old_portfolio->{'Fund C'} + ($investment_plan->{'Fund C'} // 0)
        ),
        'Updated Fund C is sum of old portfolio and investment plan'
    );
};

subtest
  'Investment plan with cash maintains balance for already balanced portfolio'
  => sub {
    my $actual_portfolio = {
        'Fund A' => 48000,
        'Fund B' => 30000,
        'Fund C' => 20000,
        'Cash' => 2000
    };
    my $cash = {'Cash' => 1};
    my $monthly_investment = 10000;
    my (undef, $investment_plan) =
      allocate_funds($target_allocation_cash, $actual_portfolio,
        $cash, $monthly_investment);

    ok(float_cmp($investment_plan->{'Fund A'}, 4800),
        'Correct investment in Fund A');
    ok(float_cmp($investment_plan->{'Fund B'}, 3000),
        'Correct investment in Fund B');
    ok(float_cmp($investment_plan->{'Fund C'}, 2000),
        'Correct investment in Fund C');
    ok(float_cmp($investment_plan->{'Fund C'}, 2000),
        'Correct investment in Cash');
  };

subtest
  'Investment plan with cash achieves balance for cash heavy portfolio' =>
  sub {
    my $actual_portfolio = {
        'Fund A' => 48000,
        'Fund B' => 30000,
        'Fund C' => 20000,
        'Cash' => 8000
    };
    my $cash = {'Cash' => 1};
    my $monthly_investment = 0;
    my (undef, $investment_plan) =
      allocate_funds($target_allocation_cash, $actual_portfolio,
        $cash, $monthly_investment);

    ok(float_cmp($investment_plan->{'Fund A'}, 2880),
        'Correct investment in Fund A');
    ok(float_cmp($investment_plan->{'Fund B'}, 1800),
        'Correct investment in Fund B');
    ok(float_cmp($investment_plan->{'Fund C'}, 1200),
        'Correct investment in Fund C');
    ok(float_cmp($investment_plan->{'Cash'}, -5880),
        'Correct investment in Cash');
  };

subtest 'Investment plan with cash is correct for normal allocation' => sub {
    my $actual_portfolio = {
        'Fund A' => 50000,
        'Fund B' => 27638,
        'Fund C' => 8000.20,
        'Cash' => 6502
    };
    my $cash = {'Cash' => 1};
    my $monthly_investment = 2.56;
    my (undef, $investment_plan) =
      allocate_funds($target_allocation_cash, $actual_portfolio,
        $cash, $monthly_investment);

    ok(float_cmp($investment_plan->{'Fund A'} // 0, 0),
        'No new investment in Fund A');
    ok(float_cmp($investment_plan->{'Fund B'}, 2.16),
        'Correct investment in Fund B');
    ok(float_cmp($investment_plan->{'Fund C'}, 4659.55),
        'Correct investment in Fund C');
    ok(float_cmp($investment_plan->{'Cash'}, -4659.14),
        'Correct investment in Cash');
};

done_testing();

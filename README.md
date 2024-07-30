# Portfolio

### Purpose

Scripts you can use to calculate adjustments to your investment portfolio,
helping to bring it more inline with your target portfolio.

### Instructions

#### For monthly investing

Assuming you wish to only buy new assets without selling existing ones, you can
use `purchase.pl` to help bring your portfolio as close as possible to your
target portfolio.

1. Enter your target asset allocations in `purchase.pl`.
1. Enter your actual asset holdings in `purchase.pl`.
1. Enter the total amount you want to invest this month (we assume monthly
   investing).
1. Run the `purchase.pl` script. It will let you know what assets to buy this
   month in order to bring your portfolio closest to your target portfolio.

#### For rebalancing

Assuming you wish to rebalance your portfolio completely, including both
selling and buying assets, you can use `rebalance.pl` to bring your portfolio
exactly in line with your target portfolio.

1. Enter your target asset allocations in `rebalance.pl`.
1. Enter your actual asset holdings in `rebalance.pl`.
1. Enter the total amount you want to invest during this investment period
   (this can be zero if you don't wish to invest more money during
   rebalancing).
1. Run the `rebalance.pl` script. It will let you know what assets to buy and
    sell in order to make your portfolio match your target portfolio.

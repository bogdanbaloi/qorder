import 'package:flutter/foundation.dart';

import '../../core/money.dart';
import 'sales_metrics.dart';

/// The latest recorded day against the one before it: how orders and revenue
/// moved. [revenueRatio] is the fractional change (0.15 = +15%), null when the
/// previous day had no revenue (a change from zero has no percentage).
@immutable
class DayComparison {
  final int ordersDelta;
  final Money revenueDelta;
  final double? revenueRatio;

  const DayComparison({
    required this.ordersDelta,
    required this.revenueDelta,
    required this.revenueRatio,
  });
}

/// Today's average order value (revenue / orders), or zero when no orders today.
/// Integer bani division, so no float creeps into money.
Money averageOrderValue(SalesMetrics metrics) {
  if (metrics.ordersToday == 0) return const Money(0);
  return Money(metrics.revenueToday.amountMinor ~/ metrics.ordersToday);
}

/// The most recent recorded day compared with the previous one, or null when
/// there are fewer than two days of history to compare.
DayComparison? dayOverDay(List<DailyMetric> history) {
  if (history.length < 2) return null;
  final previous = history[history.length - 2];
  final latest = history[history.length - 1];
  final revenueDeltaMinor =
      latest.revenue.amountMinor - previous.revenue.amountMinor;
  final previousMinor = previous.revenue.amountMinor;
  return DayComparison(
    ordersDelta: latest.orders - previous.orders,
    revenueDelta: Money(revenueDeltaMinor),
    revenueRatio: previousMinor == 0 ? null : revenueDeltaMinor / previousMinor,
  );
}

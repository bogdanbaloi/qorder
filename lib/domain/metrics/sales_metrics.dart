import 'package:flutter/foundation.dart';

import '../../core/money.dart';

/// One day in the owner's history: how many orders and how much revenue.
@immutable
class DailyMetric {
  final String date; // YYYY-MM-DD
  final int orders;
  final Money revenue;

  const DailyMetric({
    required this.date,
    required this.orders,
    required this.revenue,
  });

  factory DailyMetric.fromJson(Map<String, dynamic> j) => DailyMetric(
    date: j['date'] as String,
    orders: (j['orders'] as num).toInt(),
    revenue: Money((j['revenueMinor'] as num).toInt()),
  );
}

/// The owner's sales metrics: today's orders and revenue, the average acceptance
/// and delivery times, and a daily history. Comes from the backend (which keeps
/// past orders); the in-app mock returns [SalesMetrics.empty] since it does not
/// persist history.
@immutable
class SalesMetrics {
  final int ordersToday;
  final Money revenueToday;
  final Duration? avgAcceptance;
  final Duration? avgDelivery;
  final List<DailyMetric> history;

  const SalesMetrics({
    required this.ordersToday,
    required this.revenueToday,
    this.avgAcceptance,
    this.avgDelivery,
    this.history = const [],
  });

  const SalesMetrics.empty()
    : ordersToday = 0,
      revenueToday = const Money(0),
      avgAcceptance = null,
      avgDelivery = null,
      history = const [];

  factory SalesMetrics.fromJson(Map<String, dynamic> j) {
    Duration? millis(Object? v) =>
        v == null ? null : Duration(milliseconds: (v as num).toInt());
    return SalesMetrics(
      ordersToday: (j['ordersToday'] as num?)?.toInt() ?? 0,
      revenueToday: Money((j['revenueTodayMinor'] as num?)?.toInt() ?? 0),
      avgAcceptance: millis(j['avgAcceptanceMs']),
      avgDelivery: millis(j['avgDeliveryMs']),
      history: ((j['daily'] as List?) ?? const [])
          .map((e) => DailyMetric.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

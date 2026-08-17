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

/// One hour of today's trading: how many orders and how much revenue.
@immutable
class HourlyMetric {
  final int hour; // 0..23
  final int orders;
  final Money revenue;

  const HourlyMetric({
    required this.hour,
    required this.orders,
    required this.revenue,
  });

  factory HourlyMetric.fromJson(Map<String, dynamic> j) => HourlyMetric(
    hour: (j['hour'] as num).toInt(),
    orders: (j['orders'] as num).toInt(),
    revenue: Money((j['revenueMinor'] as num).toInt()),
  );
}

/// A product and how many units of it sold, for the "top products" ranking.
@immutable
class ProductCount {
  final String name;
  final int qty;

  const ProductCount({required this.name, required this.qty});

  factory ProductCount.fromJson(Map<String, dynamic> j) =>
      ProductCount(name: j['name'] as String, qty: (j['qty'] as num).toInt());
}

/// The owner's sales metrics: today's orders and revenue, the average acceptance
/// and delivery times, a daily history, today's hourly breakdown and the top
/// products by units sold. Comes from the backend (which keeps past orders); the
/// in-app mock returns [SalesMetrics.empty] since it does not persist history.
@immutable
class SalesMetrics {
  final int ordersToday;
  final Money revenueToday;
  final Duration? avgAcceptance;
  final Duration? avgDelivery;
  final List<DailyMetric> history;
  final List<HourlyMetric> hourly;
  final List<ProductCount> topProducts;

  const SalesMetrics({
    required this.ordersToday,
    required this.revenueToday,
    this.avgAcceptance,
    this.avgDelivery,
    this.history = const [],
    this.hourly = const [],
    this.topProducts = const [],
  });

  const SalesMetrics.empty()
    : ordersToday = 0,
      revenueToday = const Money(0),
      avgAcceptance = null,
      avgDelivery = null,
      history = const [],
      hourly = const [],
      topProducts = const [];

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
      hourly: ((j['hourly'] as List?) ?? const [])
          .map((e) => HourlyMetric.fromJson(e as Map<String, dynamic>))
          .toList(),
      topProducts: ((j['topProducts'] as List?) ?? const [])
          .map((e) => ProductCount.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

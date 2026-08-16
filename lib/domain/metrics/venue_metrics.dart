import 'package:flutter/foundation.dart';

import '../timing/order_timings.dart';

/// A live operational snapshot for the owner: how many things wait, how many are
/// in progress, and the average acceptance and delivery times (the owner's key
/// metric). Pure value object, computed by [computeVenueMetrics], so it is
/// unit-tested without the UI or a backend. Historical / daily analytics and
/// revenue come later, when the backend persists past orders.
@immutable
class VenueMetrics {
  final int pending; // orders awaiting a waiter's acceptance
  final int inProgress; // accepted, not yet delivered
  final int openRequests; // call-waiter / bill requests
  final Duration? avgAcceptance; // submit -> accept, null when no data
  final Duration? avgDelivery; // ready -> table, null when no data

  const VenueMetrics({
    required this.pending,
    required this.inProgress,
    required this.openRequests,
    this.avgAcceptance,
    this.avgDelivery,
  });
}

/// Computes the snapshot from the counts and the in-progress orders' timings.
/// Averages ignore orders whose stamp for that leg has not happened yet.
VenueMetrics computeVenueMetrics({
  required int pending,
  required int openRequests,
  required List<OrderTimings> inProgressTimings,
}) {
  Duration? average(Iterable<Duration?> durations) {
    final present = durations.whereType<Duration>().toList();
    if (present.isEmpty) return null;
    final totalMs = present
        .map((d) => d.inMilliseconds)
        .reduce((a, b) => a + b);
    return Duration(milliseconds: totalMs ~/ present.length);
  }

  return VenueMetrics(
    pending: pending,
    inProgress: inProgressTimings.length,
    openRequests: openRequests,
    avgAcceptance: average(inProgressTimings.map((t) => t.acceptance)),
    avgDelivery: average(inProgressTimings.map((t) => t.delivery)),
  );
}

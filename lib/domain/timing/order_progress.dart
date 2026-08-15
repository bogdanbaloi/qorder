import 'package:flutter/foundation.dart';

import 'order_timings.dart';

/// An accepted order the waiter is moving to the table. Carries the timing
/// stamps so the surface can show the durations. JSON-serializable for the
/// shared store (Phase 0) and the BFF's REST contract (Phase 1).
@immutable
class ProgressOrder {
  final String serverOrderId;
  final String venueId;
  final int tableNumber;
  final int sequence;
  final String? customerName;
  final OrderStamps stamps;

  const ProgressOrder({
    required this.serverOrderId,
    required this.venueId,
    required this.tableNumber,
    required this.sequence,
    required this.stamps,
    this.customerName,
  });

  OrderTimings get timings => OrderTimings(stamps);

  Map<String, dynamic> toJson() => {
    'serverOrderId': serverOrderId,
    'venueId': venueId,
    'tableNumber': tableNumber,
    'sequence': sequence,
    'customerName': customerName,
    'stamps': stamps,
  };

  factory ProgressOrder.fromJson(Map<String, dynamic> j) => ProgressOrder(
    serverOrderId: j['serverOrderId'] as String,
    venueId: j['venueId'] as String,
    tableNumber: (j['tableNumber'] as num).toInt(),
    sequence: (j['sequence'] as num).toInt(),
    customerName: j['customerName'] as String?,
    stamps: ((j['stamps'] as Map?) ?? const <String, dynamic>{}).map(
      (k, v) => MapEntry(k as String, (v as num).toInt()),
    ),
  );
}

/// Waiter-side seam for moving an accepted order to the table and reading the
/// in-progress list. Segregated from `OrderAcceptanceService` (Interface
/// Segregation): accepting an order is one action, driving it to the table is
/// another. The mock fulfils it in memory, the BFF over REST.
abstract interface class OrderProgress {
  /// Orders accepted but not yet delivered, on this venue, oldest first.
  Future<List<ProgressOrder>> inProgress(String venueId);

  /// Mark the drink ready (bar or waiter). Stamps 'ready'.
  Future<void> markReady(String serverOrderId);

  /// Mark the order delivered to the table (waiter). Stamps 'delivered' and
  /// removes it from the in-progress list.
  Future<void> markDelivered(String serverOrderId);
}

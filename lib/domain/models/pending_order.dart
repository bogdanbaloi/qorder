import 'package:flutter/foundation.dart';

import 'cart.dart';

/// A durable snapshot of an order that has not been confirmed yet. It carries
/// everything needed to resend it later (after an app kill or on the next
/// launch), including the [idempotencyKey] so a resend never creates a
/// duplicate order.
@immutable
class PendingOrder {
  final String idempotencyKey;
  final String venueId;
  final int tableNumber;
  final List<CartLine> lines;
  final int totalMinor;
  final int createdAtMicros;
  final int attempts;

  const PendingOrder({
    required this.idempotencyKey,
    required this.venueId,
    required this.tableNumber,
    required this.lines,
    required this.totalMinor,
    required this.createdAtMicros,
    this.attempts = 0,
  });

  Map<String, dynamic> toJson() => {
    'idempotencyKey': idempotencyKey,
    'venueId': venueId,
    'tableNumber': tableNumber,
    'lines': lines.map((l) => l.toJson()).toList(),
    'totalMinor': totalMinor,
    'createdAtMicros': createdAtMicros,
    'attempts': attempts,
  };

  factory PendingOrder.fromJson(Map<String, dynamic> j) => PendingOrder(
    idempotencyKey: j['idempotencyKey'] as String,
    venueId: j['venueId'] as String,
    tableNumber: (j['tableNumber'] as num).toInt(),
    lines: (j['lines'] as List)
        .map((e) => CartLine.fromJson(e as Map<String, dynamic>))
        .toList(),
    totalMinor: (j['totalMinor'] as num).toInt(),
    createdAtMicros: (j['createdAtMicros'] as num).toInt(),
    attempts: (j['attempts'] as num?)?.toInt() ?? 0,
  );
}

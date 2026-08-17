import 'package:flutter/foundation.dart';

import '../../core/money.dart';

/// One of the customer's past orders, for their loyalty order history. Comes
/// from the backend (which keeps past orders); the in-app mock has none.
@immutable
class PastOrder {
  final int sequence;
  final int tableNumber;
  final Money total;
  final String stage;
  final int submittedAtMs;

  const PastOrder({
    required this.sequence,
    required this.tableNumber,
    required this.total,
    required this.stage,
    required this.submittedAtMs,
  });

  factory PastOrder.fromJson(Map<String, dynamic> j) => PastOrder(
    sequence: (j['sequence'] as num).toInt(),
    tableNumber: (j['tableNumber'] as num).toInt(),
    total: Money((j['totalMinor'] as num?)?.toInt() ?? 0),
    stage: j['stage'] as String? ?? '',
    submittedAtMs: ((j['stamps'] as Map?)?['submitted'] as num?)?.toInt() ?? 0,
  );
}

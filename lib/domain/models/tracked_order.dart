import 'package:flutter/foundation.dart';

import 'order.dart';

/// One of the customer's submitted orders, tracked for its live status. The
/// [stage] is null until the backend reports the first status.
@immutable
class TrackedOrder {
  final String serverOrderId;
  final int? sequence; // FIFO number shown to the customer
  final OrderStage? stage;

  const TrackedOrder({required this.serverOrderId, this.sequence, this.stage});

  TrackedOrder withStage(OrderStage stage) => TrackedOrder(
    serverOrderId: serverOrderId,
    sequence: sequence,
    stage: stage,
  );
}

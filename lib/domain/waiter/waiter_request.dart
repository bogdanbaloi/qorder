import 'package:flutter/foundation.dart';

/// What a table is asking the waiter for. A named domain seam: a new ask
/// (water, cutlery, ...) is a new enum value, not an `if` scattered around.
enum WaiterRequestKind { callWaiter, bill }

/// A pending request from a table to the waiter ("come over" / "the bill").
/// JSON-serializable, so it is shared across browser tabs (Phase 0 store) and
/// carried over the BFF's REST contract (Phase 1). Independent of orders and of
/// the POS: it never touches Ebriza, it only pings staff.
@immutable
class WaiterRequest {
  final String id;
  final String venueId;
  final int tableNumber;
  final WaiterRequestKind kind;
  final String? customerName;
  final int createdAtMs;

  const WaiterRequest({
    required this.id,
    required this.venueId,
    required this.tableNumber,
    required this.kind,
    required this.createdAtMs,
    this.customerName,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'venueId': venueId,
    'tableNumber': tableNumber,
    'kind': kind.name,
    'customerName': customerName,
    'createdAtMs': createdAtMs,
  };

  factory WaiterRequest.fromJson(Map<String, dynamic> j) => WaiterRequest(
    id: j['id'] as String,
    venueId: j['venueId'] as String,
    tableNumber: (j['tableNumber'] as num).toInt(),
    kind: waiterRequestKindFrom(j['kind'] as String?),
    customerName: j['customerName'] as String?,
    createdAtMs: (j['createdAtMs'] as num).toInt(),
  );
}

WaiterRequestKind waiterRequestKindFrom(String? name) => switch (name) {
  'bill' => WaiterRequestKind.bill,
  _ => WaiterRequestKind.callWaiter,
};

/// Customer-side seam: raise a request from a table. Segregated so a customer
/// widget never depends on the waiter's read/clear ops (Interface Segregation),
/// mirroring the `OrderingService` vs `OrderAcceptanceService` split.
abstract interface class WaiterCaller {
  /// Raise a request from a table. Idempotent per (venue, table, kind): a
  /// second tap while one is still pending refreshes it, it does not pile up.
  Future<void> raise({
    required String venueId,
    required int tableNumber,
    required WaiterRequestKind kind,
    String? customerName,
  });
}

/// Waiter-side seam: read and clear pending requests. Segregated from
/// [WaiterCaller]. The mock fulfils both in memory, the BFF over REST, both
/// behind these interfaces (Dependency Inversion).
abstract interface class WaiterRequestBoard {
  /// Requests currently waiting on this venue, oldest first.
  Future<List<WaiterRequest>> requests(String venueId);

  /// Mark a request handled (a waiter action), removing it from the list.
  Future<void> resolve(String requestId);
}

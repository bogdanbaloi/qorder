import 'models.dart';

/// The order store PORT (Dependency Inversion). Phase 1 ships an in-memory
/// implementation. A persistent one (SQLite/Postgres) and the Ebriza adapter
/// (which also injects to the POS) drop in behind this same interface.
abstract interface class OrderStore {
  /// Submit an order. Idempotent by `idempotencyKey`, so a resend after a lost
  /// response never creates a second order.
  BffOrder submit(
      {required String venueId, required Map<String, dynamic> order});

  /// Orders awaiting a waiter's confirmation, on this venue.
  List<BffOrder> pending(String venueId);

  /// Accept an order (a waiter action), releasing it into processing. Returns
  /// null when the id is unknown.
  BffOrder? accept(String serverOrderId);

  /// Current state of an order, or null when the id is unknown.
  BffOrder? status(String serverOrderId);

  /// Every order on a table (all phones), for the shared "table view".
  List<BffOrder> forTable(String venueId, int tableNumber);
}

class InMemoryOrderStore implements OrderStore {
  /// Whether a submitted order waits for a waiter before it is processed.
  final bool requiresWaiter;

  InMemoryOrderStore({this.requiresWaiter = true});

  int _sequence = 0;
  final Map<String, BffOrder> _orders = {};
  final Map<String, String> _idByKey = {};

  @override
  BffOrder submit({
    required String venueId,
    required Map<String, dynamic> order,
  }) {
    final key = order['idempotencyKey'] as String?;
    if (key != null) {
      final existingId = _idByKey[key];
      if (existingId != null) return _orders[existingId]!; // idempotent
    }
    _sequence += 1;
    final id = 'BFF-$_sequence';
    final placed = BffOrder(
      serverOrderId: id,
      venueId: venueId,
      tableNumber: (order['tableNumber'] as num).toInt(),
      sequence: _sequence,
      stage:
          requiresWaiter ? OrderStage.pendingAcceptance : OrderStage.received,
      lines: (order['lines'] as List?) ?? const [],
      customerName: order['customerName'] as String?,
      clientId: order['clientId'] as String?,
      idempotencyKey: key,
    );
    _orders[id] = placed;
    if (key != null) _idByKey[key] = id;
    return placed;
  }

  @override
  List<BffOrder> pending(String venueId) => _orders.values
      .where(
        (o) => o.venueId == venueId && o.stage == OrderStage.pendingAcceptance,
      )
      .toList();

  @override
  BffOrder? accept(String serverOrderId) {
    final order = _orders[serverOrderId];
    if (order == null) return null;
    if (order.stage == OrderStage.pendingAcceptance) {
      order.stage = OrderStage.received;
    }
    return order;
  }

  @override
  BffOrder? status(String serverOrderId) => _orders[serverOrderId];

  @override
  List<BffOrder> forTable(String venueId, int tableNumber) => _orders.values
      .where((o) => o.venueId == venueId && o.tableNumber == tableNumber)
      .toList();
}

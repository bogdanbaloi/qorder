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

  /// Mark the drink ready (stamps 'ready'). Null when the id is unknown.
  BffOrder? markReady(String serverOrderId);

  /// Mark the order delivered to the table (stamps 'delivered'). Null when the
  /// id is unknown.
  BffOrder? markDelivered(String serverOrderId);

  /// Orders accepted but not yet delivered, on this venue, for the waiter's
  /// in-progress view.
  List<BffOrder> inProgress(String venueId);

  /// Every order the venue has (kept after delivery), for owner metrics.
  List<BffOrder> forVenue(String venueId);

  /// Every order a customer placed on the venue (all tables, newest first), for
  /// their loyalty order history.
  List<BffOrder> forCustomer(String venueId, String clientId);

  /// Re-key every order from an anonymous [oldClientId] to [newClientId] (the
  /// customerId), so a customer's pre-sign-in orders follow them. Idempotent.
  void relink(String oldClientId, String newClientId);
}

class InMemoryOrderStore implements OrderStore {
  /// Whether a submitted order waits for a waiter before it is processed.
  final bool requiresWaiter;

  InMemoryOrderStore({this.requiresWaiter = true});

  int _sequence = 0;
  final Map<String, BffOrder> _orders = {};
  final Map<String, String> _idByKey = {};

  int _now() => DateTime.now().millisecondsSinceEpoch;

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
    final now = _now();
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
      totalMinor: (order['totalMinor'] as num?)?.toInt() ?? 0,
      // Auto mode has no waiter step, so it is accepted at submit.
      stamps: requiresWaiter
          ? {'submitted': now}
          : {'submitted': now, 'accepted': now},
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
      order.stamps['accepted'] = _now();
    }
    return order;
  }

  @override
  BffOrder? status(String serverOrderId) => _orders[serverOrderId];

  @override
  List<BffOrder> forTable(String venueId, int tableNumber) => _orders.values
      .where((o) => o.venueId == venueId && o.tableNumber == tableNumber)
      .toList();

  @override
  BffOrder? markReady(String serverOrderId) {
    final order = _orders[serverOrderId];
    if (order == null) return null;
    order.stamps.putIfAbsent('ready', _now);
    // The drink is ready, so the customer's status advances to done ("Gata");
    // without this the stage stays 'received' and the customer never sees it.
    order.stage = OrderStage.done;
    return order;
  }

  @override
  BffOrder? markDelivered(String serverOrderId) {
    final order = _orders[serverOrderId];
    if (order == null) return null;
    order.stamps.putIfAbsent('delivered', _now);
    // The waiter brought it to the table: the customer's final status.
    order.stage = OrderStage.delivered;
    return order;
  }

  @override
  List<BffOrder> inProgress(String venueId) => _orders.values
      .where(
        (o) =>
            o.venueId == venueId &&
            o.stamps.containsKey('accepted') &&
            !o.stamps.containsKey('delivered'),
      )
      .toList();

  @override
  List<BffOrder> forVenue(String venueId) =>
      _orders.values.where((o) => o.venueId == venueId).toList();

  @override
  List<BffOrder> forCustomer(String venueId, String clientId) => _orders.values
      .where((o) => o.venueId == venueId && o.clientId == clientId)
      .toList()
    ..sort(
      (a, b) => (b.stamps['submitted'] ?? 0).compareTo(
        a.stamps['submitted'] ?? 0,
      ),
    );

  @override
  void relink(String oldClientId, String newClientId) {
    for (final o in _orders.values) {
      if (o.clientId == oldClientId) o.clientId = newClientId;
    }
  }
}

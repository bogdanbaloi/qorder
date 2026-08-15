import 'models.dart';

/// The waiter-request store PORT (Dependency Inversion), separate from the order
/// store: a table-to-waiter ping is not an order and never touches the POS. A
/// persistent implementation drops in behind this same interface later.
abstract interface class WaiterRequestStore {
  /// Raise a request. Idempotent per (venue, table, kind), so a second tap
  /// while one is still pending refreshes it instead of piling up.
  BffWaiterRequest raise({
    required String venueId,
    required int tableNumber,
    required String kind,
    String? customerName,
  });

  /// Pending requests on a venue, oldest first.
  List<BffWaiterRequest> list(String venueId);

  /// Remove a handled request. Returns whether it existed.
  bool resolve(String requestId);
}

class InMemoryWaiterRequestStore implements WaiterRequestStore {
  final Map<String, BffWaiterRequest> _requests = {};
  int _clock = 0;

  @override
  BffWaiterRequest raise({
    required String venueId,
    required int tableNumber,
    required String kind,
    String? customerName,
  }) {
    final id = '$venueId-t$tableNumber-$kind';
    _clock += 1;
    final req = BffWaiterRequest(
      id: id,
      venueId: venueId,
      tableNumber: tableNumber,
      kind: kind,
      customerName: customerName,
      createdAtMs: _clock,
    );
    _requests[id] = req;
    return req;
  }

  @override
  List<BffWaiterRequest> list(String venueId) =>
      _requests.values.where((r) => r.venueId == venueId).toList()
        ..sort((a, b) => a.createdAtMs.compareTo(b.createdAtMs));

  @override
  bool resolve(String requestId) => _requests.remove(requestId) != null;
}

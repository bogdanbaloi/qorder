import 'dart:async';

import '../../core/storage/local_store.dart';
import '../../domain/acceptance/order_acceptance.dart';
import '../../domain/models/order.dart';
import '../../domain/models/table_orders.dart';
import '../../domain/services/ordering_service.dart';
import '../../domain/waiter/waiter_request.dart';
import 'in_memory_table_ledger.dart';

/// In-memory backend for Phase 0. It:
///  - assigns a MONOTONIC sequence number (demonstrates FIFO ordering),
///  - is IDEMPOTENT (a resend with the same key returns the same confirmation),
///  - simulates latency, can be forced to fail (degrade-open),
///  - streams timed status updates.
/// It implements BOTH the customer-side [OrderingService] and the waiter-side
/// [OrderAcceptanceService]. The awaiting-orders state lives in a [LocalStore],
/// so on web it is shared across browser tabs on the same device (the demo runs
/// the customer and the waiter in two tabs). The [OrderAcceptancePolicy] decides
/// whether a submitted order waits for a waiter before it is processed.
class MockOrderingService
    implements
        OrderingService,
        OrderAcceptanceService,
        WaiterCaller,
        WaiterRequestBoard {
  static const _awaitingBox = 'awaiting';
  static const _requestsBox = 'waiter_requests';

  int _sequence = 0;
  final Map<String, SubmitConfirmed> _byKey = {};
  final InMemoryTableLedger _ledger;
  final OrderAcceptancePolicy _policy;
  final LocalStore _store;

  /// How often `watchOrder` re-checks whether a waiter has accepted an order.
  /// Small in tests, a second or so in the app.
  final Duration pollInterval;

  final bool forceFailure;
  final Duration latency;
  final Duration stageGap;

  MockOrderingService({
    this.forceFailure = false,
    this.latency = const Duration(milliseconds: 400),
    this.stageGap = const Duration(seconds: 1),
    this.pollInterval = const Duration(milliseconds: 1500),
    bool seedDemo = true,
    OrderAcceptancePolicy acceptancePolicy = const AutoAcceptPolicy(),
    LocalStore? sharedStore,
  }) : _ledger = InMemoryTableLedger(seedDemo: seedDemo),
       _policy = acceptancePolicy,
       _store = sharedStore ?? InMemoryLocalStore();

  int get lastSequence => _sequence;

  @override
  Future<SubmitResult> submitOrder(Order order) async {
    if (latency > Duration.zero) await Future.delayed(latency);
    if (forceFailure) {
      return const SubmitFailed(reason: 'Rețea indisponibilă', retryable: true);
    }
    final key = order.idempotencyKey;
    if (key != null) {
      final existing = _byKey[key];
      if (existing != null) return existing; // idempotent: no duplicate
    }
    _sequence += 1;
    final id = order.id;
    final shortId = id.length >= 6 ? id.substring(id.length - 6) : id;
    final confirmed = SubmitConfirmed(
      serverOrderId: 'MOCK-$shortId',
      sequence: _sequence,
    );
    if (key != null) _byKey[key] = confirmed;

    final name =
        (order.customerName == null || order.customerName!.trim().isEmpty)
        ? 'Client'
        : order.customerName!.trim();
    _ledger.record(
      table: order.tableRef.number,
      name: name,
      clientId: order.clientId ?? 'unknown',
      lines: order.lines
          .map((l) => TableLine(name: l.nameSnapshot, qty: l.qty))
          .toList(),
    );

    if (_policy.requiresWaiter) {
      final awaiting = AwaitingOrder(
        serverOrderId: confirmed.serverOrderId,
        venueId: order.venueId,
        tableNumber: order.tableRef.number,
        sequence: confirmed.sequence,
        customerName: order.customerName,
      );
      await _store.put(
        _awaitingBox,
        confirmed.serverOrderId,
        awaiting.toJson(),
      );
    }
    return confirmed;
  }

  @override
  Stream<OrderStatus> watchOrder(String orderId) async* {
    if (await _isAwaiting(orderId)) {
      yield OrderStatus(orderId: orderId, stage: OrderStage.pendingAcceptance);
      while (await _isAwaiting(orderId)) {
        await Future.delayed(pollInterval);
      }
    }
    yield OrderStatus(orderId: orderId, stage: OrderStage.received);
    if (stageGap > Duration.zero) await Future.delayed(stageGap);
    yield OrderStatus(orderId: orderId, stage: OrderStage.preparing);
    if (stageGap > Duration.zero) await Future.delayed(stageGap);
    yield OrderStatus(orderId: orderId, stage: OrderStage.done);
  }

  @override
  Future<TableOrders> tableOrders(
    String venueId,
    int tableNumber, {
    required String myClientId,
  }) async => _ledger.ordersFor(tableNumber, myClientId: myClientId);

  @override
  Future<List<AwaitingOrder>> pending(String venueId) async {
    final rows = await _store.all(_awaitingBox);
    return rows
        .map(AwaitingOrder.fromJson)
        .where((a) => a.venueId == venueId)
        .toList();
  }

  @override
  Future<void> accept(String serverOrderId) =>
      _store.delete(_awaitingBox, serverOrderId);

  @override
  Future<void> raise({
    required String venueId,
    required int tableNumber,
    required WaiterRequestKind kind,
    String? customerName,
  }) async {
    final req = WaiterRequest(
      id: '$venueId-t$tableNumber-${kind.name}',
      venueId: venueId,
      tableNumber: tableNumber,
      kind: kind,
      customerName: customerName,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    await _store.put(_requestsBox, req.id, req.toJson());
  }

  @override
  Future<List<WaiterRequest>> requests(String venueId) async {
    final rows = await _store.all(_requestsBox);
    return rows
        .map(WaiterRequest.fromJson)
        .where((r) => r.venueId == venueId)
        .toList()
      ..sort((a, b) => a.createdAtMs.compareTo(b.createdAtMs));
  }

  @override
  Future<void> resolve(String requestId) =>
      _store.delete(_requestsBox, requestId);

  Future<bool> _isAwaiting(String orderId) async =>
      await _store.get(_awaitingBox, orderId) != null;
}

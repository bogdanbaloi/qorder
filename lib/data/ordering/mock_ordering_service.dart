import 'dart:async';

import '../../domain/acceptance/order_acceptance.dart';
import '../../domain/models/order.dart';
import '../../domain/models/table_orders.dart';
import '../../domain/services/ordering_service.dart';
import 'in_memory_table_ledger.dart';

/// In-memory backend for Phase 0. It:
///  - assigns a MONOTONIC sequence number (demonstrates FIFO ordering),
///  - is IDEMPOTENT (a resend with the same key returns the same confirmation),
///  - simulates latency, can be forced to fail (degrade-open),
///  - streams timed status updates.
/// It implements BOTH the customer-side [OrderingService] and the waiter-side
/// [OrderAcceptanceService], so a waiter accept and a customer status share the
/// same state. The shared "table view" is delegated to an [InMemoryTableLedger]
/// (Single Responsibility). The [OrderAcceptancePolicy] decides whether a
/// submitted order waits for a waiter before it is processed.
class MockOrderingService implements OrderingService, OrderAcceptanceService {
  int _sequence = 0;
  final Map<String, SubmitConfirmed> _byKey = {};
  final InMemoryTableLedger _ledger;
  final OrderAcceptancePolicy _policy;

  /// Orders submitted in waiterConfirm mode, keyed by server order id, waiting
  /// for `accept`. The completer releases the paused status stream.
  final Map<String, AwaitingOrder> _awaiting = {};
  final Map<String, Completer<void>> _acceptSignals = {};

  final bool forceFailure;
  final Duration latency;
  final Duration stageGap;

  MockOrderingService({
    this.forceFailure = false,
    this.latency = const Duration(milliseconds: 400),
    this.stageGap = const Duration(seconds: 1),
    bool seedDemo = true,
    OrderAcceptancePolicy acceptancePolicy = const AutoAcceptPolicy(),
  }) : _ledger = InMemoryTableLedger(seedDemo: seedDemo),
       _policy = acceptancePolicy;

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
      _awaiting[confirmed.serverOrderId] = AwaitingOrder(
        serverOrderId: confirmed.serverOrderId,
        tableNumber: order.tableRef.number,
        sequence: confirmed.sequence,
        customerName: order.customerName,
      );
      _acceptSignals[confirmed.serverOrderId] = Completer<void>();
    }
    return confirmed;
  }

  @override
  Stream<OrderStatus> watchOrder(String orderId) async* {
    if (_awaiting.containsKey(orderId)) {
      yield OrderStatus(orderId: orderId, stage: OrderStage.pendingAcceptance);
      await (_acceptSignals[orderId]?.future ?? Future<void>.value());
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
  Future<List<AwaitingOrder>> pending(String venueId) async =>
      _awaiting.values.toList();

  @override
  Future<void> accept(String serverOrderId) async {
    _awaiting.remove(serverOrderId);
    _acceptSignals.remove(serverOrderId)?.complete();
  }
}

import 'dart:async';

import '../../domain/models/order.dart';
import '../../domain/models/table_orders.dart';
import '../../domain/services/ordering_service.dart';
import 'in_memory_table_ledger.dart';

/// In-memory OrderingService for Phase 0. It:
///  - assigns a MONOTONIC sequence number (demonstrates FIFO ordering),
///  - is IDEMPOTENT (a resend with the same key returns the same confirmation),
///  - simulates latency, can be forced to fail (degrade-open),
///  - streams timed status updates.
/// The shared "table view" is delegated to an [InMemoryTableLedger], so this
/// class keeps a single responsibility: submit + status.
class MockOrderingService implements OrderingService {
  int _sequence = 0;
  final Map<String, SubmitConfirmed> _byKey = {};
  final InMemoryTableLedger _ledger;
  final bool forceFailure;
  final Duration latency;
  final Duration stageGap;

  MockOrderingService({
    this.forceFailure = false,
    this.latency = const Duration(milliseconds: 400),
    this.stageGap = const Duration(seconds: 1),
    bool seedDemo = true,
  }) : _ledger = InMemoryTableLedger(seedDemo: seedDemo);

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
    return confirmed;
  }

  @override
  Stream<OrderStatus> watchOrder(String orderId) async* {
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
}

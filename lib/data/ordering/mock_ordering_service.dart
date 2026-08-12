import 'dart:async';

import '../../domain/models/order.dart';
import '../../domain/models/table_orders.dart';
import '../../domain/services/ordering_service.dart';

class _Recorded {
  final int table;
  final String name;
  final String clientId;
  final List<TableLine> lines;
  _Recorded(this.table, this.name, this.clientId, this.lines);
}

/// In-memory OrderingService for Phase 0. It:
///  - assigns a MONOTONIC sequence number (demonstrates FIFO ordering),
///  - is IDEMPOTENT (a resend with the same key returns the same confirmation),
///  - simulates latency, can be forced to fail (degrade-open),
///  - streams timed status updates,
///  - records orders per table and exposes the shared "table view"
///    (seeded with a couple of pretend customers for the demo).
class MockOrderingService implements OrderingService {
  int _sequence = 0;
  final Map<String, SubmitConfirmed> _byKey = {};
  final List<_Recorded> _recorded = [];
  final bool forceFailure;
  final Duration latency;
  final Duration stageGap;

  MockOrderingService({
    this.forceFailure = false,
    this.latency = const Duration(milliseconds: 400),
    this.stageGap = const Duration(seconds: 1),
    bool seedDemo = true,
  }) {
    if (seedDemo) {
      // Pretend other customers already ordered at these tables (for the demo).
      _recorded.add(
        _Recorded(7, 'Maria', 'seed-maria', const [
          TableLine(name: 'Cappuccino 160ml', qty: 1),
        ]),
      );
      _recorded.add(
        _Recorded(12, 'Ana', 'seed-ana', const [
          TableLine(name: 'Pilsner Urquell 0.5L', qty: 2),
        ]),
      );
      _recorded.add(
        _Recorded(12, 'Radu', 'seed-radu', const [
          TableLine(name: 'Nachos 160g + sos 40g', qty: 1),
        ]),
      );
    }
  }

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
    _recorded.add(
      _Recorded(
        order.tableRef.number,
        name,
        order.clientId ?? 'unknown',
        order.lines
            .map((l) => TableLine(name: l.nameSnapshot, qty: l.qty))
            .toList(),
      ),
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
  }) async {
    final entries = _recorded
        .where((r) => r.table == tableNumber)
        .map(
          (r) => TableEntry(
            name: r.name,
            clientId: r.clientId,
            lines: r.lines,
            isMine: r.clientId == myClientId,
          ),
        )
        .toList();
    return TableOrders(tableNumber: tableNumber, entries: entries);
  }
}

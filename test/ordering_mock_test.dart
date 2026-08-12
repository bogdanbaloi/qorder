import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/core/money.dart';
import 'package:qorder/data/ordering/mock_ordering_service.dart';
import 'package:qorder/domain/models/order.dart';
import 'package:qorder/domain/models/table_ref.dart';

Order _order(String id) => Order(
  id: id,
  venueId: 'v',
  tableRef: const TableRef(
    number: 1,
    source: TableSource.manual,
    validated: true,
  ),
  lines: const [],
  total: const Money(0),
);

void main() {
  // REQ-ORD-002: orders get a monotonic FIFO sequence.
  test('sequence is monotonic across submits (FIFO)', () async {
    final mock = MockOrderingService(
      latency: Duration.zero,
      stageGap: Duration.zero,
    );
    final r1 = await mock.submitOrder(_order('ord-1'));
    final r2 = await mock.submitOrder(_order('ord-2'));
    expect((r1 as SubmitConfirmed).sequence, 1);
    expect((r2 as SubmitConfirmed).sequence, 2);
  });

  // REQ-ERR-001: a forced failure is reported explicitly, never a silent drop.
  test('forced failure yields SubmitFailed', () async {
    final mock = MockOrderingService(
      forceFailure: true,
      latency: Duration.zero,
    );
    final r = await mock.submitOrder(_order('ord-x'));
    expect(r, isA<SubmitFailed>());
    expect((r as SubmitFailed).retryable, true);
  });

  // REQ-ORD-003: processing streams received -> preparing -> done.
  test('watchOrder streams the lifecycle stages in order', () async {
    final mock = MockOrderingService(stageGap: Duration.zero);
    final stages = await mock.watchOrder('id').map((s) => s.stage).toList();
    expect(stages, [
      OrderStage.received,
      OrderStage.preparing,
      OrderStage.done,
    ]);
  });
}

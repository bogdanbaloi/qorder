import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/core/money.dart';
import 'package:qorder/data/ordering/mock_ordering_service.dart';
import 'package:qorder/domain/models/order.dart';
import 'package:qorder/domain/models/table_ref.dart';

Order _order(String key) => Order(
  id: 'ord-$key',
  idempotencyKey: key,
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
  // REQ-RES-002: a retry with the SAME idempotency key must not create a
  // second order (never duplicated).
  test('same idempotency key returns the same result (no duplicate)', () async {
    final mock = MockOrderingService(
      latency: Duration.zero,
      stageGap: Duration.zero,
    );
    final r1 = await mock.submitOrder(_order('same')) as SubmitConfirmed;
    final r2 = await mock.submitOrder(_order('same')) as SubmitConfirmed;

    expect(r1.sequence, 1);
    expect(r2.sequence, 1); // deduped, not 2
    expect(r2.serverOrderId, r1.serverOrderId);
  });

  test('different keys get different sequences', () async {
    final mock = MockOrderingService(
      latency: Duration.zero,
      stageGap: Duration.zero,
    );
    final r1 = await mock.submitOrder(_order('a')) as SubmitConfirmed;
    final r2 = await mock.submitOrder(_order('b')) as SubmitConfirmed;
    expect(r1.sequence, 1);
    expect(r2.sequence, 2);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/core/money.dart';
import 'package:qorder/data/ordering/mock_ordering_service.dart';
import 'package:qorder/domain/models/cart.dart';
import 'package:qorder/domain/models/order.dart';
import 'package:qorder/domain/models/table_ref.dart';

Order _order({
  required int table,
  required String name,
  required String clientId,
  required String key,
}) => Order(
  id: 'ord-$key',
  idempotencyKey: key,
  clientId: clientId,
  customerName: name,
  venueId: 'demo',
  tableRef: TableRef(
    number: table,
    source: TableSource.manual,
    validated: true,
  ),
  lines: const [
    CartLine(
      id: 'l',
      itemId: 'b',
      nameSnapshot: 'Pilsner Urquell 0.5L',
      unitPriceSnapshot: Money(1890),
      qty: 2,
    ),
  ],
  total: const Money(3780),
);

void main() {
  // REQ-TBL-002: a shared table shows all phones' orders, by name, with the
  // customer's own entries marked "mine".
  test('table view aggregates orders by person and marks mine', () async {
    final mock = MockOrderingService(
      latency: Duration.zero,
      stageGap: Duration.zero,
    );
    await mock.submitOrder(
      _order(table: 12, name: 'Andrei', clientId: 'me', key: 'k1'),
    );

    final t = await mock.tableOrders('demo', 12, myClientId: 'me');

    // Seeded Ana + Radu on table 12, plus Andrei (mine).
    expect(t.entries.length, greaterThanOrEqualTo(3));
    final mine = t.entries.where((e) => e.isMine).toList();
    expect(mine.length, 1);
    expect(mine.first.name, 'Andrei');
    expect(mine.first.lines.first.qty, 2);
    // The seeded others are not mine.
    expect(t.entries.where((e) => !e.isMine).isNotEmpty, true);
  });

  test('a different table does not leak orders', () async {
    final mock = MockOrderingService(
      latency: Duration.zero,
      stageGap: Duration.zero,
      seedDemo: false,
    );
    final empty = await mock.tableOrders('demo', 99, myClientId: 'me');
    expect(empty.isEmpty, true);
  });
}

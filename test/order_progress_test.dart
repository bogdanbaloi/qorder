import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/core/money.dart';
import 'package:qorder/data/ordering/mock_ordering_service.dart';
import 'package:qorder/domain/acceptance/order_acceptance.dart';
import 'package:qorder/domain/models/cart.dart';
import 'package:qorder/domain/models/order.dart';
import 'package:qorder/domain/models/table_ref.dart';

Order _order(int table) => Order(
  id: 'ord-$table',
  idempotencyKey: 'k$table',
  venueId: 'demo',
  customerName: 'Andrei',
  tableRef: TableRef(
    number: table,
    source: TableSource.manual,
    validated: true,
  ),
  lines: const [
    CartLine(
      id: 'l1',
      itemId: 'b',
      nameSnapshot: 'Beer',
      unitPriceSnapshot: Money(1000),
      qty: 1,
    ),
  ],
  total: const Money(1000),
);

void main() {
  // REQ-TIME-001: accept records the acceptance time; ready then delivered give
  // the delivery gap; a delivered order leaves the in-progress list.
  test(
    'accept adds to in-progress with acceptance; delivered removes it',
    () async {
      final mock = MockOrderingService(
        latency: Duration.zero,
        seedDemo: false,
        acceptancePolicy: const WaiterConfirmationPolicy(),
      );
      final res = await mock.submitOrder(_order(7)) as SubmitConfirmed;

      // Not in progress until a waiter accepts it.
      expect(await mock.inProgress('demo'), isEmpty);

      await mock.accept(res.serverOrderId);
      final list = await mock.inProgress('demo');
      expect(list.length, 1);
      expect(list.single.timings.acceptance, isNotNull);
      expect(list.single.stamps.containsKey('ready'), false);

      await mock.markReady(res.serverOrderId);
      final ready = await mock.inProgress('demo');
      expect(ready.single.stamps.containsKey('ready'), true);

      await mock.markDelivered(res.serverOrderId);
      expect(await mock.inProgress('demo'), isEmpty);
    },
  );
}

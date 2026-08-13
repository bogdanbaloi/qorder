import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/core/money.dart';
import 'package:qorder/data/ordering/mock_ordering_service.dart';
import 'package:qorder/domain/acceptance/order_acceptance.dart';
import 'package:qorder/domain/models/cart.dart';
import 'package:qorder/domain/models/order.dart';
import 'package:qorder/domain/models/table_ref.dart';

Order _order(String key) => Order(
  id: 'ord-$key',
  idempotencyKey: key,
  venueId: 'demo',
  customerName: 'Andrei',
  tableRef: const TableRef(
    number: 5,
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
  group('OrderAcceptancePolicy', () {
    test('auto does not require a waiter, waiterConfirm does', () {
      expect(acceptancePolicyFor(AcceptanceMode.auto).requiresWaiter, false);
      expect(
        acceptancePolicyFor(AcceptanceMode.waiterConfirm).requiresWaiter,
        true,
      );
    });
  });

  group('waiter confirmation flow (mock)', () {
    // REQ-ACC-001: in waiterConfirm mode a submitted order waits
    // (pendingAcceptance) until a waiter accepts it, then processes normally.
    test('an order waits pending until a waiter accepts it', () async {
      final mock = MockOrderingService(
        latency: Duration.zero,
        stageGap: Duration.zero,
        seedDemo: false,
        acceptancePolicy: const WaiterConfirmationPolicy(),
      );

      final result = await mock.submitOrder(_order('k1'));
      final id = (result as SubmitConfirmed).serverOrderId;

      // It is registered as awaiting a waiter, with the table + who ordered.
      final waiting = await mock.pending('demo');
      expect(waiting.length, 1);
      expect(waiting.single.serverOrderId, id);
      expect(waiting.single.tableNumber, 5);
      expect(waiting.single.customerName, 'Andrei');

      // The status stream holds at pendingAcceptance and does not advance.
      final collected = mock.watchOrder(id).toList();
      await pumpEventQueue();
      expect((await mock.pending('demo')).length, 1); // still waiting

      // The waiter accepts: the order clears pending and runs to completion.
      await mock.accept(id);
      final stages = (await collected).map((s) => s.stage).toList();

      expect(await mock.pending('demo'), isEmpty);
      expect(stages, [
        OrderStage.pendingAcceptance,
        OrderStage.received,
        OrderStage.preparing,
        OrderStage.done,
      ]);
    });

    test('auto mode never holds an order pending', () async {
      final mock = MockOrderingService(
        latency: Duration.zero,
        stageGap: Duration.zero,
        seedDemo: false,
      );
      await mock.submitOrder(_order('k2'));
      expect(await mock.pending('demo'), isEmpty);
    });
  });
}

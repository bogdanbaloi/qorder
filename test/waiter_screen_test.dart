import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/core/money.dart';
import 'package:qorder/data/ordering/mock_ordering_service.dart';
import 'package:qorder/di/providers.dart';
import 'package:qorder/domain/acceptance/order_acceptance.dart';
import 'package:qorder/domain/models/cart.dart';
import 'package:qorder/domain/models/order.dart';
import 'package:qorder/domain/alerts/alert_signal.dart';
import 'package:qorder/domain/models/table_ref.dart';
import 'package:qorder/domain/waiter/waiter_request.dart';
import 'package:qorder/features/waiter/waiter_screen.dart';

class _RecordingAlert implements AlertSignal {
  int fired = 0;

  @override
  Future<void> fire() async => fired++;
}

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
  // REQ-ACC-002: the waiter surface lists orders awaiting confirmation and
  // accepts them, clearing the order from the pending list.
  testWidgets('waiter sees a pending order and confirms it', (tester) async {
    final backend = MockOrderingService(
      latency: Duration.zero,
      stageGap: Duration.zero,
      seedDemo: false,
      acceptancePolicy: const WaiterConfirmationPolicy(),
    );
    await backend.submitOrder(_order('k1'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [mockBackendProvider.overrideWithValue(backend)],
        child: const MaterialApp(home: WaiterScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Masa 5'), findsOneWidget);
    expect(find.textContaining('Andrei'), findsOneWidget);
    expect(find.textContaining('Comenzi noi (1)'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Confirmă'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Masa 5'), findsNothing);
    expect(find.text('Nimic în așteptare'), findsOneWidget);
    expect(await backend.pending('demo'), isEmpty);
  });

  testWidgets('empty state when nothing is awaiting', (tester) async {
    final backend = MockOrderingService(
      latency: Duration.zero,
      stageGap: Duration.zero,
      seedDemo: false,
      acceptancePolicy: const WaiterConfirmationPolicy(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [mockBackendProvider.overrideWithValue(backend)],
        child: const MaterialApp(home: WaiterScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Nimic în așteptare'), findsOneWidget);
  });

  // REQ-CALL-001: a table's request shows on the waiter surface and resolving
  // it clears it from the list.
  testWidgets('waiter sees a request and resolves it', (tester) async {
    final backend = MockOrderingService(
      latency: Duration.zero,
      stageGap: Duration.zero,
      seedDemo: false,
      acceptancePolicy: const WaiterConfirmationPolicy(),
    );
    await backend.raise(
      venueId: 'demo',
      tableNumber: 9,
      kind: WaiterRequestKind.bill,
      customerName: 'Ana',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [mockBackendProvider.overrideWithValue(backend)],
        child: const MaterialApp(home: WaiterScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Masa 9'), findsOneWidget);
    expect(find.textContaining('Cere nota'), findsOneWidget);
    expect(find.textContaining('Cereri (1)'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Rezolvă'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Masa 9'), findsNothing);
    expect(await backend.requests('demo'), isEmpty);
  });

  // REQ-CALL-001 (alert): a new request buzzes/sounds the waiter's device, so
  // staff do not have to watch the screen.
  testWidgets('a new request fires the staff alert', (tester) async {
    final backend = MockOrderingService(
      latency: Duration.zero,
      stageGap: Duration.zero,
      seedDemo: false,
      acceptancePolicy: const WaiterConfirmationPolicy(),
    );
    final alert = _RecordingAlert();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mockBackendProvider.overrideWithValue(backend),
          alertSignalProvider.overrideWithValue(alert),
        ],
        child: const MaterialApp(home: WaiterScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(alert.fired, 0);

    await backend.raise(
      venueId: 'demo',
      tableNumber: 3,
      kind: WaiterRequestKind.callWaiter,
    );
    await tester.pump(const Duration(seconds: 2)); // the poll timer fires
    await tester.pump(const Duration(milliseconds: 100)); // futures resolve

    expect(alert.fired, greaterThanOrEqualTo(1));
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/core/money.dart';
import 'package:qorder/data/ordering/mock_ordering_service.dart';
import 'package:qorder/di/providers.dart';
import 'package:qorder/domain/acceptance/order_acceptance.dart';
import 'package:qorder/domain/models/cart.dart';
import 'package:qorder/domain/models/order.dart';
import 'package:qorder/domain/models/table_ref.dart';
import 'package:qorder/features/waiter/waiter_screen.dart';

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
    expect(find.text('Andrei'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Confirmă'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Masa 5'), findsNothing);
    expect(find.text('Nicio comandă în așteptare'), findsOneWidget);
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

    expect(find.text('Nicio comandă în așteptare'), findsOneWidget);
  });
}

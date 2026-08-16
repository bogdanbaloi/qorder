import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/core/money.dart';
import 'package:qorder/data/ordering/mock_ordering_service.dart';
import 'package:qorder/di/providers.dart';
import 'package:qorder/domain/models/menu.dart';
import 'package:qorder/features/cart/cart_controller.dart';
import 'package:qorder/features/cart/cart_screen.dart';
import 'package:qorder/features/table/customer_provider.dart';
import 'package:qorder/features/table/table_controller.dart';

const _beer = MenuItem(
  id: 'b',
  categoryId: 'x',
  name: 'Beer',
  basePrice: Money(1000),
);

void main() {
  // REQ-ORD-005: tapping submit shows a review dialog first; the order fires
  // only after confirming it.
  testWidgets('submit asks for confirmation, then sends', (tester) async {
    final container = ProviderContainer(
      overrides: [
        orderingServiceProvider.overrideWithValue(
          MockOrderingService(latency: Duration.zero, stageGap: Duration.zero),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(cartProvider.notifier).addItem(_beer);
    container.read(tableProvider.notifier).setManual(5);
    container.read(customerNameProvider.notifier).set('Andrei');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CartScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Trimite comanda'));
    await tester.pumpAndSettle();

    // The review dialog shows the table and lets the customer confirm.
    expect(find.text('Trimiți comanda?'), findsOneWidget);
    expect(find.text('Masa 5'), findsWidgets);

    await tester.tap(find.widgetWithText(FilledButton, 'Trimite'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Comandă #'), findsOneWidget);
  });
}

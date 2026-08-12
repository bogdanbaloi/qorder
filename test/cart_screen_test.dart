import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/core/money.dart';
import 'package:qorder/domain/models/menu.dart';
import 'package:qorder/features/cart/cart_controller.dart';
import 'package:qorder/features/cart/cart_screen.dart';
import 'package:qorder/features/table/table_controller.dart';

const _beer = MenuItem(
  id: 'b',
  categoryId: 'x',
  name: 'Beer',
  basePrice: Money(1000),
);

void main() {
  // REQ-UX-001: an empty cart offers a way back to the menu, not a dead form.
  testWidgets('empty cart shows "Vezi meniul", not the order form', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: CartScreen())),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Coșul e gol'), findsOneWidget);
    expect(find.text('Vezi meniul'), findsOneWidget);
    expect(find.text('Trimite comanda'), findsNothing);
  });

  testWidgets('with an item + a table, the order form and submit appear', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: CartScreen())),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CartScreen)),
    );
    container.read(cartProvider.notifier).addItem(_beer);
    container.read(tableProvider.notifier).setManual(5);
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Beer'), findsOneWidget);
    expect(find.text('Trimite comanda'), findsOneWidget);
    expect(find.text('Vezi meniul'), findsNothing);
  });
}

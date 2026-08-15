import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/core/money.dart';
import 'package:qorder/core/result.dart';
import 'package:qorder/di/providers.dart';
import 'package:qorder/domain/models/menu.dart';
import 'package:qorder/domain/repositories/menu_repository.dart';
import 'package:qorder/features/menu/menu_screen.dart';

class _FakeMenuRepository implements MenuRepository {
  @override
  Future<Result<Menu>> loadMenu(
    String venueId, {
    bool forceRefresh = false,
  }) async {
    return const Ok(
      Menu(
        venueId: 'v',
        version: 1,
        categories: [
          Category(
            id: 'lb',
            name: 'LIVE BEERS',
            sortOrder: 0,
            items: [
              MenuItem(
                id: 'b',
                categoryId: 'lb',
                name: 'Ursus Premium',
                basePrice: Money(1290),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void main() {
  // REQ-MENU-001 (view): the menu screen renders categories from the model.
  testWidgets('menu screen shows a category from the repository', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          menuRepositoryProvider.overrideWithValue(_FakeMenuRepository()),
        ],
        child: const MaterialApp(home: MenuScreen()),
      ),
    );

    // Resolve the FutureProvider (loader -> data), without pumpAndSettle
    // because a progress indicator would animate forever while loading.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // The category name now appears both as a jump-to chip and as the section
    // header, so it is shown at least once.
    expect(find.text('LIVE BEERS'), findsWidgets);
    expect(find.text('Ursus Premium'), findsOneWidget);
    expect(find.text('12.90 lei'), findsOneWidget);
  });

  // REQ-DL-001 (view): a /t/:table deep link pre-fills the table, shown on the
  // menu app bar, and a persistent cart action is always available.
  testWidgets('deep-link table shows in the app bar + persistent cart action', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          menuRepositoryProvider.overrideWithValue(_FakeMenuRepository()),
        ],
        child: const MaterialApp(home: MenuScreen(tableParam: 7)),
      ),
    );

    await tester.pump(); // runs the post-frame callback that sets the table
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Meniu · Masa 7'), findsOneWidget);
    expect(find.byIcon(Icons.shopping_cart), findsOneWidget);
  });

  // REQ-MENU-002 (view): typing in the search box filters the menu live.
  testWidgets('search filters the menu live', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          menuRepositoryProvider.overrideWithValue(_FakeMenuRepository()),
        ],
        child: const MaterialApp(home: MenuScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.enterText(find.byType(TextField), 'xyz');
    await tester.pump();
    expect(find.text('Nimic găsit'), findsOneWidget);
    expect(find.text('Ursus Premium'), findsNothing);

    await tester.enterText(find.byType(TextField), 'ursus');
    await tester.pump();
    expect(find.text('Ursus Premium'), findsOneWidget);
  });

  // REQ-MENU-003 (view): tapping an item opens a detail sheet; adding from it
  // puts the item in the cart.
  testWidgets('item detail sheet adds to the cart', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          menuRepositoryProvider.overrideWithValue(_FakeMenuRepository()),
        ],
        child: const MaterialApp(home: MenuScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Ursus Premium'));
    await tester.pumpAndSettle();
    expect(find.text('Adaugă în coș'), findsOneWidget);

    await tester.tap(find.text('Adaugă în coș'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Coș (1)'), findsOneWidget);
  });
}

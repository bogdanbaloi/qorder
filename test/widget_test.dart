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

    expect(find.text('LIVE BEERS'), findsOneWidget);
    expect(find.text('Ursus Premium'), findsOneWidget);
    expect(find.text('12.90 lei'), findsOneWidget);
  });
}

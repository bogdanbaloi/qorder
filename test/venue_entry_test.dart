import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/core/config/app_config.dart';
import 'package:qorder/core/money.dart';
import 'package:qorder/core/result.dart';
import 'package:qorder/data/config/in_memory_venue_config_source.dart';
import 'package:qorder/di/providers.dart';
import 'package:qorder/domain/models/menu.dart';
import 'package:qorder/domain/repositories/menu_repository.dart';
import 'package:qorder/features/menu/menu_screen.dart';
import 'package:qorder/features/table/table_controller.dart';
import 'package:qorder/features/table/unknown_venue_screen.dart';
import 'package:qorder/features/table/venue_entry_screen.dart';

class _FakeMenuRepository implements MenuRepository {
  @override
  Future<Result<Menu>> loadMenu(String venueId, {bool forceRefresh = false}) async {
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
              MenuItem(id: 'b', categoryId: 'lb', name: 'Ursus', basePrice: Money(1290)),
            ],
          ),
        ],
      ),
    );
  }
}

const _otherVenue = AppConfig(
  venueId: 'other',
  branding: Branding(
    venueName: 'Other Pub',
    backgroundColor: 0xFF000000,
    surfaceColor: 0xFF111111,
    primaryColor: 0xFF00FF00,
    accentColor: 0xFFFF0000,
  ),
  tablePolicy: TableNumberPolicy(),
  menuAsset: 'assets/menu/other.json',
);

ProviderContainer _container() => ProviderContainer(
  overrides: [
    menuRepositoryProvider.overrideWithValue(_FakeMenuRepository()),
    venueConfigSourceProvider.overrideWithValue(
      InMemoryVenueConfigSource(const [AppConfig.demo, _otherVenue]),
    ),
  ],
);

void main() {
  // REQ-CFG-002: a known venue in the link becomes the active venue and opens
  // the menu with the table pre-filled.
  testWidgets('a known venue link sets the active venue and shows the menu', (
    tester,
  ) async {
    final c = _container();
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(
          home: VenueEntryScreen(venue: 'other', tableParam: 7),
        ),
      ),
    );
    await tester.pump(); // post-frame: sets the active venue then the table
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(MenuScreen), findsOneWidget);
    expect(find.byType(UnknownVenueScreen), findsNothing);
    expect(c.read(activeVenueIdProvider), 'other');
    expect(c.read(tableProvider)?.number, 7);
    expect(c.read(tableProvider)?.validated, true);
  });

  // REQ-CFG-002: an unknown venue is a dead end, not a wrong menu; the active
  // venue is left untouched.
  testWidgets('an unknown venue link shows the error screen, no menu', (
    tester,
  ) async {
    final c = _container();
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(
          home: VenueEntryScreen(venue: 'ghost', tableParam: 7),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(UnknownVenueScreen), findsOneWidget);
    expect(find.byType(MenuScreen), findsNothing);
    expect(c.read(activeVenueIdProvider), AppConfig.demo.venueId); // unchanged
  });

  // REQ-DL-001: the normal deep link validates a valid table against the policy.
  testWidgets('a valid deep-link table is validated', (tester) async {
    final c = ProviderContainer(
      overrides: [menuRepositoryProvider.overrideWithValue(_FakeMenuRepository())],
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(home: MenuScreen(tableParam: 7)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(c.read(tableProvider)?.number, 7);
    expect(c.read(tableProvider)?.validated, true);
  });

  // REQ-DL-001: an out-of-policy table from the link is set but not validated,
  // so the submit gate stays closed.
  testWidgets('an out-of-policy deep-link table is not validated', (
    tester,
  ) async {
    final c = ProviderContainer(
      overrides: [menuRepositoryProvider.overrideWithValue(_FakeMenuRepository())],
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(home: MenuScreen(tableParam: 9999)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(c.read(tableProvider)?.number, 9999);
    expect(c.read(tableProvider)?.validated, false);
  });
}

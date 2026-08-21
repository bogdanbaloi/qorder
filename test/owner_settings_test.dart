import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/core/config/app_config.dart';
import 'package:qorder/di/providers.dart';
import 'package:qorder/domain/config/venue_config_api.dart';
import 'package:qorder/features/settings/owner_settings_screen.dart';

/// Records what the Settings screen saves and replays it on fetch, so the test
/// proves the edit round-trips through the write port.
class _RecordingApi implements VenueConfigApi {
  AppConfig? saved;

  @override
  Future<AppConfig?> fetch(String venueId) async => saved;

  @override
  Future<void> save(String venueId, AppConfig config) async {
    saved = config;
  }
}

void main() {
  // REQ-CFG-004: the owner edits the venue name and saves it through the port.
  testWidgets('editing the venue name saves it and confirms', (tester) async {
    final api = _RecordingApi();
    _tallWindow(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [venueConfigApiProvider.overrideWithValue(api)],
        child: const MaterialApp(home: OwnerSettingsScreen()),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, 'Local Nou');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(api.saved, isNotNull);
    expect(api.saved!.branding.venueName, 'Local Nou');
    expect(find.text('Salvat.'), findsOneWidget);
  });

  // REQ-CFG-004: the owner picks a brand colour from the palette (no hex typing).
  testWidgets('picking an accent colour from the palette saves it', (
    tester,
  ) async {
    const picked = 0xFF3AA0FF;
    final api = _RecordingApi();
    _tallWindow(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [venueConfigApiProvider.overrideWithValue(api)],
        child: const MaterialApp(home: OwnerSettingsScreen()),
      ),
    );

    // Open the accent picker, then tap a specific palette swatch.
    final accentRow = find
        .ancestor(of: find.text('Accent secundar'), matching: find.byType(Row))
        .first;
    await tester.tap(
      find.descendant(of: accentRow, matching: find.byType(InkWell)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('swatch_$picked')));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(api.saved!.branding.accentColor, picked);
  });
}

void _tallWindow(WidgetTester tester) {
  // A tall window, so the whole form (preview + rows + button) fits.
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

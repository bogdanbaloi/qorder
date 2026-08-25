import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/core/config/app_config.dart';
import 'package:qorder/di/providers.dart';
import 'package:qorder/domain/config/venue_config_api.dart';
import 'package:qorder/domain/identity/session.dart';
import 'package:qorder/domain/identity/session_expired.dart';
import 'package:qorder/features/session/session_controller.dart';
import 'package:qorder/features/settings/owner_settings_controller.dart';
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

class _ExpiredApi implements VenueConfigApi {
  @override
  Future<AppConfig?> fetch(String venueId) async => null;

  @override
  Future<void> save(String venueId, AppConfig config) async =>
      throw const SessionExpiredException();
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

  // REQ-CFG-006: a saved edit applies to the running app, no reload.
  test('a saved edit applies live to appConfigProvider', () async {
    final api = _RecordingApi();
    final container = ProviderContainer(
      overrides: [venueConfigApiProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);

    final controller = container.read(ownerSettingsControllerProvider.notifier);
    controller.setVenueName('Local Live');
    await controller.save();

    expect(container.read(appConfigProvider).branding.venueName, 'Local Live');
  });

  // REQ-LOYAL-007: the owner edits the reward ladder and rate, and it saves.
  test('editing loyalty saves the rate and the reward ladder', () async {
    final api = _RecordingApi();
    final container = ProviderContainer(
      overrides: [venueConfigApiProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);

    final controller = container.read(ownerSettingsControllerProvider.notifier);
    final startTiers = container
        .read(ownerSettingsControllerProvider)
        .loyalty
        .tiers
        .length;

    controller.setPointsRate(2);
    controller.addTier();
    controller.updateTier(
      startTiers,
      thresholdPoints: 150,
      reward: 'Cafea gratis',
    );
    controller.removeTier(0);
    await controller.save();

    final saved = api.saved!.loyaltyProgram;
    expect(saved.pointsPerMajorUnit, 2);
    expect(saved.tiers.length, startTiers); // added one, removed one
    expect(saved.tiers.last.thresholdPoints, 150);
    expect(saved.tiers.last.reward, 'Cafea gratis');
  });

  // REQ-IDENT-005: a save rejected as expired signs the owner out, so the guard
  // shows the code gate instead of a stuck "could not save".
  test('a save rejected as expired signs the owner out', () async {
    final container = ProviderContainer(
      overrides: [venueConfigApiProvider.overrideWithValue(_ExpiredApi())],
    );
    addTearDown(container.dispose);

    container
        .read(sessionProvider.notifier)
        .signInAs(AppRole.owner, staffToken: 'dead');
    expect(container.read(sessionProvider).role, AppRole.owner);

    await container.read(ownerSettingsControllerProvider.notifier).save();

    // No longer owner: the owner RoleGuard now shows the access-code gate.
    expect(container.read(sessionProvider).role, isNot(AppRole.owner));
  });
}

void _tallWindow(WidgetTester tester) {
  // A tall window, so the whole form (preview + fields + button) fits.
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

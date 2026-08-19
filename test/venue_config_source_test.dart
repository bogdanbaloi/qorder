import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/core/config/app_config.dart';
import 'package:qorder/data/config/in_memory_venue_config_source.dart';
import 'package:qorder/di/providers.dart';

/// A second venue, so the tests prove the source is multi-tenant and not just
/// the single demo config wearing a port.
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

void main() {
  // REQ-CFG-001: config is resolved per venue through a source port.
  group('InMemoryVenueConfigSource', () {
    test('returns the demo config for the demo venue', () {
      final source = InMemoryVenueConfigSource.demo();
      expect(source.configFor('demo'), same(AppConfig.demo));
    });

    test('returns null for an unknown venue', () {
      final source = InMemoryVenueConfigSource.demo();
      expect(source.configFor('nope'), isNull);
    });

    test('resolves each venue by its id (multi-tenant)', () {
      final source = InMemoryVenueConfigSource(
        const [AppConfig.demo, _otherVenue],
      );
      expect(source.configFor('demo'), same(AppConfig.demo));
      expect(source.configFor('other'), same(_otherVenue));
    });
  });

  group('appConfigProvider', () {
    test('resolves the demo venue by default (no behaviour change)', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(appConfigProvider), same(AppConfig.demo));
    });

    test('resolves the active venue through the source', () {
      final c = ProviderContainer(
        overrides: [
          venueConfigSourceProvider.overrideWithValue(
            InMemoryVenueConfigSource(const [AppConfig.demo, _otherVenue]),
          ),
          activeVenueIdProvider.overrideWithValue('other'),
        ],
      );
      addTearDown(c.dispose);
      expect(c.read(appConfigProvider).venueId, 'other');
      expect(c.read(appConfigProvider).branding.venueName, 'Other Pub');
    });

    test('falls back to the demo config for an unknown active venue', () {
      final c = ProviderContainer(
        overrides: [activeVenueIdProvider.overrideWithValue('nope')],
      );
      addTearDown(c.dispose);
      expect(c.read(appConfigProvider), same(AppConfig.demo));
    });
  });
}

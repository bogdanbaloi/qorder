import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/core/config/app_config.dart';
import 'package:qorder/data/config/asset_venue_config_source.dart';
import 'package:qorder/domain/acceptance/order_acceptance.dart';

const _catalog = '''
{
  "version": 1,
  "venues": [
    {
      "venueId": "alpha",
      "branding": {
        "venueName": "Alpha",
        "backgroundColor": "0xFF010203",
        "surfaceColor": "0xFF040506",
        "primaryColor": "0xFF070809",
        "accentColor": "0xFF0A0B0C"
      },
      "menuAsset": "assets/menu/alpha.json"
    },
    {
      "venueId": "beta",
      "branding": {
        "venueName": "Beta",
        "backgroundColor": "0xFF111111",
        "surfaceColor": "0xFF222222",
        "primaryColor": "0xFF333333",
        "accentColor": "0xFF444444"
      },
      "menuAsset": "assets/menu/beta.json",
      "acceptanceMode": "waiterConfirm",
      "requireCustomerName": true,
      "staffAccessCode": "1111",
      "loyaltyProgram": {
        "tiers": [ { "thresholdPoints": 50, "reward": "Free coffee" } ]
      }
    }
  ]
}
''';

/// A bundle whose asset load always fails, to exercise the degrade-open path.
class _ThrowingBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => throw Exception('no asset');
}

void main() {
  // REQ-CFG-003: a venue is DATA parsed from JSON, not a compile-time constant.
  group('parseVenueCatalog', () {
    test('parses every venue, hex colours and defaults', () {
      final venues = parseVenueCatalog(_catalog);
      expect(venues.map((v) => v.venueId), ['alpha', 'beta']);

      final alpha = venues.first;
      expect(alpha.branding.venueName, 'Alpha');
      expect(alpha.branding.backgroundColor, 0xFF010203);
      expect(alpha.branding.accentColor, 0xFF0A0B0C);
      // Omitted fields fall back to the constructor defaults.
      expect(alpha.acceptanceMode, AcceptanceMode.auto);
      expect(alpha.requireCustomerName, false);
      expect(alpha.staffAccessCode, '0000');
      expect(alpha.loyaltyProgram.tiers, isEmpty);

      final beta = venues.last;
      expect(beta.acceptanceMode, AcceptanceMode.waiterConfirm);
      expect(beta.requireCustomerName, true);
      expect(beta.staffAccessCode, '1111');
      expect(beta.loyaltyProgram.tiers.single.thresholdPoints, 50);
      expect(beta.loyaltyProgram.tiers.single.reward, 'Free coffee');
    });

    test('overlays the deployment backend URL only when empty', () {
      final venues = parseVenueCatalog(_catalog, backendBaseUrl: 'http://bff');
      expect(venues.first.backendBaseUrl, 'http://bff');
      expect(venues.first.useRemoteBackend, true);

      final own = parseVenueCatalog(
        '{"venues":[{"venueId":"g","branding":{"venueName":"G",'
        '"backgroundColor":"0xFF000000","surfaceColor":"0xFF000000",'
        '"primaryColor":"0xFF000000","accentColor":"0xFF000000"},'
        '"menuAsset":"m","backendBaseUrl":"http://own"}]}',
        backendBaseUrl: 'http://bff',
      );
      expect(own.single.backendBaseUrl, 'http://own'); // kept, not overlaid
    });
  });

  group('loadVenueConfigSource', () {
    test('degrades to the built-in demo when the asset fails to load', () async {
      final source = await loadVenueConfigSource(bundle: _ThrowingBundle());
      expect(source.configFor('demo'), isNotNull);
      expect(source.configFor('demo')!.venueId, 'demo');
    });
  });

  // REQ-CFG-003: the shipped venue asset matches the built-in demo config, so
  // moving the config to JSON changed the source, not the values.
  test('the bundled demo asset matches AppConfig.demo', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final text = await rootBundle.loadString(venuesAsset);
    final demo = parseVenueCatalog(text).single;

    expect(demo.venueId, AppConfig.demo.venueId);
    expect(demo.branding.venueName, AppConfig.demo.branding.venueName);
    expect(demo.branding.backgroundColor, AppConfig.demo.branding.backgroundColor);
    expect(demo.branding.primaryColor, AppConfig.demo.branding.primaryColor);
    expect(
      demo.branding.alternatingCategoryBands,
      AppConfig.demo.branding.alternatingCategoryBands,
    );
    expect(demo.menuAsset, AppConfig.demo.menuAsset);
    expect(demo.acceptanceMode, AppConfig.demo.acceptanceMode);
    expect(demo.requireCustomerName, AppConfig.demo.requireCustomerName);
    expect(demo.staffAccessCode, AppConfig.demo.staffAccessCode);
    expect(demo.ownerAccessCode, AppConfig.demo.ownerAccessCode);
    expect(
      demo.loyaltyProgram.tiers.length,
      AppConfig.demo.loyaltyProgram.tiers.length,
    );
    expect(
      demo.loyaltyProgram.tiers.first.reward,
      AppConfig.demo.loyaltyProgram.tiers.first.reward,
    );
  });
}

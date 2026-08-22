import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/core/config/app_config.dart';
import 'package:qorder/data/config/asset_venue_config_source.dart';
import 'package:qorder/domain/config/venue_config_api.dart';

/// A bundle that serves a fixed catalogue string, so the loader is tested with
/// no real asset.
class _FakeBundle extends AssetBundle {
  final String text;
  _FakeBundle(this.text);

  @override
  Future<ByteData> load(String key) => throw UnimplementedError();

  @override
  Future<String> loadString(String key, {bool cache = true}) async => text;
}

class _FakeApi implements VenueConfigApi {
  final AppConfig? saved;
  final bool fail;
  _FakeApi({this.saved, this.fail = false});

  @override
  Future<AppConfig?> fetch(String venueId) async {
    if (fail) throw Exception('backend down');
    return saved;
  }

  @override
  Future<void> save(String venueId, AppConfig config) async {}
}

void main() {
  final catalog = jsonEncode({
    'venues': [AppConfig.demo.toJson()],
  });

  // REQ-CFG-005: a server-saved config overlays the bundled asset, so an owner
  // edit reaches the customer app at its next open.
  test('a saved config overlays the asset, deployment URL re-applied', () async {
    final saved = AppConfig.demo.copyWith(
      branding: AppConfig.demo.branding.copyWith(primaryColor: 0xFF0000FF),
    );
    final source = await loadVenueConfigSource(
      bundle: _FakeBundle(catalog),
      backendBaseUrl: 'http://bff',
      remoteOverrides: _FakeApi(saved: saved),
    );

    final config = source.configFor('demo')!;
    expect(config.branding.primaryColor, 0xFF0000FF);
    // backendBaseUrl is omitted from the saved document, so it is re-overlaid.
    expect(config.backendBaseUrl, 'http://bff');
  });

  test('a down backend keeps the asset config (degrade open)', () async {
    final source = await loadVenueConfigSource(
      bundle: _FakeBundle(catalog),
      remoteOverrides: _FakeApi(fail: true),
    );
    expect(
      source.configFor('demo')!.branding.primaryColor,
      AppConfig.demo.branding.primaryColor,
    );
  });

  test('no override reads the asset as before', () async {
    final source = await loadVenueConfigSource(bundle: _FakeBundle(catalog));
    expect(
      source.configFor('demo')!.branding.venueName,
      AppConfig.demo.branding.venueName,
    );
  });
}

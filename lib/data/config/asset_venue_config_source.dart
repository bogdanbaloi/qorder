import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../../core/config/app_config.dart';
import '../../domain/config/venue_config_source.dart';
import 'in_memory_venue_config_source.dart';

/// The bundled venue catalogue. A remote endpoint replaces this asset later,
/// behind the same `VenueConfigSource` port.
const String venuesAsset = 'assets/venues/demo.json';

/// Parses a venue catalogue JSON document (`{ "venues": [ ... ] }`) into configs.
/// Pure, so the parsing is unit-tested without an asset bundle. `backendBaseUrl`
/// is a deployment concern (the BFF URL, same for every venue in a build), so it
/// is overlaid here when the document leaves a venue's value empty.
List<AppConfig> parseVenueCatalog(
  String jsonText, {
  String backendBaseUrl = '',
}) {
  final document = jsonDecode(jsonText) as Map<String, dynamic>;
  final venues = (document['venues'] as List).cast<Map<String, dynamic>>();
  return [
    for (final venue in venues)
      _withBackend(AppConfig.fromJson(venue), backendBaseUrl),
  ];
}

AppConfig _withBackend(AppConfig config, String backendBaseUrl) =>
    config.backendBaseUrl.isEmpty && backendBaseUrl.isNotEmpty
    ? config.copyWith(backendBaseUrl: backendBaseUrl)
    : config;

/// Loads the venue catalogue from the app bundle into a `VenueConfigSource`.
/// Degrade-open (ADR-0007 style): a missing or malformed asset must not brick
/// startup, so it falls back to the built-in demo config. [backendBaseUrl]
/// overlays the deployment BFF URL onto venues that leave it empty.
Future<VenueConfigSource> loadVenueConfigSource({
  AssetBundle? bundle,
  String backendBaseUrl = '',
}) async {
  try {
    final text = await (bundle ?? rootBundle).loadString(venuesAsset);
    final venues = parseVenueCatalog(text, backendBaseUrl: backendBaseUrl);
    if (venues.isEmpty) return InMemoryVenueConfigSource.demo();
    return InMemoryVenueConfigSource(venues);
  } on Object catch (_) {
    // Missing or corrupt asset must not stop the app from starting.
    return InMemoryVenueConfigSource.demo();
  }
}

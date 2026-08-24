import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../../core/config/app_config.dart';
import '../../domain/config/venue_config_api.dart';
import '../../domain/config/venue_config_source.dart';
import '../../domain/diagnostics/app_logger.dart';
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
///
/// When [remoteOverrides] is given (a configured backend), each venue's saved
/// config is fetched from the server and overlaid on the asset, so an owner's
/// Settings edit reaches customers at their next app open, no release needed
/// (REQ-CFG-005). Each fetch degrades open: a miss or an error keeps the asset
/// config, so a down backend never blocks startup.
Future<VenueConfigSource> loadVenueConfigSource({
  AssetBundle? bundle,
  String backendBaseUrl = '',
  VenueConfigApi? remoteOverrides,
  AppLogger logger = const SilentLogger(),
}) async {
  try {
    final text = await (bundle ?? rootBundle).loadString(venuesAsset);
    var venues = parseVenueCatalog(text, backendBaseUrl: backendBaseUrl);
    if (venues.isEmpty) return InMemoryVenueConfigSource.demo();
    if (remoteOverrides != null) {
      venues = await _overlaySaved(
        venues,
        remoteOverrides,
        backendBaseUrl,
        logger,
      );
    }
    return InMemoryVenueConfigSource(venues);
  } on Object catch (e, s) {
    // Missing or corrupt asset must not stop the app from starting.
    logger.warning(
      'venue catalogue load failed, using demo config',
      error: e,
      stackTrace: s,
    );
    return InMemoryVenueConfigSource.demo();
  }
}

/// Overlays each venue's server-saved config on its asset config, keeping the
/// asset when nothing is saved or the fetch fails (degrade-open per venue). The
/// fetches run in parallel, so many venues do not serialise startup. Each
/// `_withSaved` catches its own error, so the batch never rejects.
Future<List<AppConfig>> _overlaySaved(
  List<AppConfig> venues,
  VenueConfigApi remote,
  String backendBaseUrl,
  AppLogger logger,
) => Future.wait([
  for (final venue in venues) _withSaved(venue, remote, backendBaseUrl, logger),
]);

Future<AppConfig> _withSaved(
  AppConfig asset,
  VenueConfigApi remote,
  String backendBaseUrl,
  AppLogger logger,
) async {
  try {
    final saved = await remote.fetch(asset.venueId);
    // The saved document omits backendBaseUrl (a deployment overlay), so re-apply
    // it, exactly as the asset path does.
    return saved == null ? asset : _withBackend(saved, backendBaseUrl);
  } on Object catch (e, s) {
    logger.warning(
      'venue config overlay failed for ${asset.venueId}',
      error: e,
      stackTrace: s,
    );
    return asset; // a down backend keeps the asset config
  }
}

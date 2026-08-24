import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'data/config/asset_venue_config_source.dart';
import 'data/config/remote_venue_config_api.dart';
import 'data/diagnostics/console_logger.dart';
import 'data/storage/prefs_local_store.dart';
import 'di/providers.dart';
import 'domain/diagnostics/app_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  // Venue configs come from a JSON asset (data, not code); the BFF URL is a
  // deployment concern, passed via --dart-define and overlaid onto every venue.
  // With a backend configured, each venue's server-saved config is overlaid on
  // the asset, so an owner's Settings edit reaches customers (REQ-CFG-005).
  const bffUrl = String.fromEnvironment('QORDER_BFF_URL');
  final AppLogger logger = ConsoleLogger();
  final venueConfigSource = await loadVenueConfigSource(
    backendBaseUrl: bffUrl,
    logger: logger,
    remoteOverrides: bffUrl.isEmpty
        ? null
        : RemoteVenueConfigApi(
            baseUrl: bffUrl,
            client: http.Client(),
            logger: logger,
          ),
  );
  runApp(
    ProviderScope(
      overrides: [
        // Real durable storage on device/web. Tests keep the in-memory default.
        localStoreProvider.overrideWithValue(PrefsLocalStore(prefs)),
        venueConfigSourceProvider.overrideWithValue(venueConfigSource),
        loggerProvider.overrideWithValue(logger),
      ],
      child: const QorderApp(),
    ),
  );
}

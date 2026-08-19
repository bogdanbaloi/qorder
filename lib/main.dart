import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'data/config/asset_venue_config_source.dart';
import 'data/storage/prefs_local_store.dart';
import 'di/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  // Venue configs come from a JSON asset (data, not code); the BFF URL is a
  // deployment concern, passed via --dart-define and overlaid onto every venue.
  final venueConfigSource = await loadVenueConfigSource(
    backendBaseUrl: const String.fromEnvironment('QORDER_BFF_URL'),
  );
  runApp(
    ProviderScope(
      overrides: [
        // Real durable storage on device/web. Tests keep the in-memory default.
        localStoreProvider.overrideWithValue(PrefsLocalStore(prefs)),
        venueConfigSourceProvider.overrideWithValue(venueConfigSource),
      ],
      child: const QorderApp(),
    ),
  );
}

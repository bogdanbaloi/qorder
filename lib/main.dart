import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'data/storage/prefs_local_store.dart';
import 'di/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        // Real durable storage on device/web; tests keep the in-memory default.
        localStoreProvider.overrideWithValue(PrefsLocalStore(prefs)),
      ],
      child: const QorderApp(),
    ),
  );
}

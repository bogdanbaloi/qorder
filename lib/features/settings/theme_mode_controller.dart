import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';

/// The user's light/dark preference for the app. A per-device choice (like the
/// language), available to owner and customer alike. Defaults to following the
/// system, is restored from storage on launch and persisted on change, so a
/// returning user keeps their choice (REQ-CFG-008).
class ThemeModeController extends Notifier<ThemeMode> {
  static const _box = 'settings';
  static const _key = 'themeMode';

  @override
  ThemeMode build() {
    unawaited(_restore());
    return ThemeMode.system;
  }

  Future<void> _restore() async {
    final stored = await ref.read(localStoreProvider).get(_box, _key);
    final name = stored?['mode'] as String?;
    if (name != null) state = _fromName(name);
  }

  void set(ThemeMode mode) {
    state = mode;
    unawaited(
      ref.read(localStoreProvider).put(_box, _key, {'mode': mode.name}),
    );
  }

  static ThemeMode _fromName(String name) => ThemeMode.values.firstWhere(
    (mode) => mode.name == name,
    orElse: () => ThemeMode.system,
  );
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

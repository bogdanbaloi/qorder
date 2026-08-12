import 'package:flutter/material.dart';

import '../core/config/app_config.dart';

/// Builds the app theme from the venue [Branding]. The colors are design tokens
/// extracted from the venue site, not hard-coded in widgets.
ThemeData buildTheme(Branding b) {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: Color(b.primaryColor),
        brightness: Brightness.dark,
      ).copyWith(
        primary: Color(b.primaryColor),
        secondary: Color(b.accentColor),
        surface: Color(b.surfaceColor),
      );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Color(b.backgroundColor),
    appBarTheme: const AppBarTheme(foregroundColor: Colors.white),
  );
}

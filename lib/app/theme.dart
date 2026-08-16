import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/config/app_config.dart';

/// Builds the app theme from the venue [Branding]. Colors AND the display font
/// are design tokens from the venue config, not hard-coded in widgets, so a new
/// venue is a new [Branding], not a rewrite.
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
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Color(b.backgroundColor),
    appBarTheme: const AppBarTheme(foregroundColor: Colors.white),
  );

  final font = b.displayFont;
  if (font == null) return base;
  // The venue's headings are a techno display font; body text stays a readable
  // sans. Applied only to the title/headline styles the headers use.
  TextStyle head(TextStyle? s) =>
      GoogleFonts.getFont(font, textStyle: s, fontWeight: FontWeight.w700);
  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      titleLarge: head(base.textTheme.titleLarge),
      titleMedium: head(base.textTheme.titleMedium),
      titleSmall: head(base.textTheme.titleSmall),
      headlineSmall: head(base.textTheme.headlineSmall),
    ),
  );
}

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

  // Headings in the signature colour and weight, like the venue site.
  final orange = Color(b.primaryColor);
  TextStyle? colored(TextStyle? s) =>
      s?.copyWith(color: orange, fontWeight: FontWeight.w700);
  var textTheme = base.textTheme.copyWith(
    titleLarge: colored(base.textTheme.titleLarge),
    titleMedium: colored(base.textTheme.titleMedium),
    titleSmall: colored(base.textTheme.titleSmall),
    headlineSmall: colored(base.textTheme.headlineSmall),
  );

  // Optional techno display font for the headings. Body text stays a plain sans.
  final font = b.displayFont;
  if (font != null) {
    TextStyle withFont(TextStyle? s) => GoogleFonts.getFont(font, textStyle: s);
    textTheme = textTheme.copyWith(
      titleLarge: withFont(textTheme.titleLarge),
      titleMedium: withFont(textTheme.titleMedium),
      titleSmall: withFont(textTheme.titleSmall),
      headlineSmall: withFont(textTheme.headlineSmall),
    );
  }
  return base.copyWith(textTheme: textTheme);
}

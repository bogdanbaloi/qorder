import 'package:flutter/material.dart';

import '../core/config/app_config.dart';

/// Builds the app theme from the venue [Branding]. Colours and the display font
/// are design tokens from the venue config, not hard-coded in widgets, so a new
/// venue is a new [Branding], not a rewrite.
///
/// The brightness is derived from the background, so a light venue theme gets
/// dark text and a dark one gets light text. Readability holds whatever palette
/// the owner picks, instead of assuming a dark background.
ThemeData buildTheme(Branding b) {
  final background = Color(b.backgroundColor);
  final surface = Color(b.surfaceColor);
  final brightness = ThemeData.estimateBrightnessForColor(background);
  final onColor = brightness == Brightness.dark ? Colors.white : Colors.black87;

  final scheme =
      ColorScheme.fromSeed(
        seedColor: Color(b.primaryColor),
        brightness: brightness,
      ).copyWith(
        primary: Color(b.primaryColor),
        secondary: Color(b.accentColor),
        surface: surface,
      );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      foregroundColor: onColor,
    ),
  );

  // Headings in the signature colour and weight, like the venue site.
  final heading = Color(b.primaryColor);
  TextStyle? colored(TextStyle? s) =>
      s?.copyWith(color: heading, fontWeight: FontWeight.w700);
  var textTheme = base.textTheme.copyWith(
    titleLarge: colored(base.textTheme.titleLarge),
    titleMedium: colored(base.textTheme.titleMedium),
    titleSmall: colored(base.textTheme.titleSmall),
    headlineSmall: colored(base.textTheme.headlineSmall),
  );

  // Optional techno display font for the headings. Body text stays a plain sans.
  // The font is bundled (see pubspec `fonts:`), so this is a local family lookup,
  // not a network fetch. It renders reliably offline and on mobile web.
  final font = b.displayFont;
  if (font != null) {
    TextStyle? withFont(TextStyle? s) => s?.copyWith(fontFamily: font);
    textTheme = textTheme.copyWith(
      titleLarge: withFont(textTheme.titleLarge),
      titleMedium: withFont(textTheme.titleMedium),
      titleSmall: withFont(textTheme.titleSmall),
      headlineSmall: withFont(textTheme.headlineSmall),
    );
  }
  return base.copyWith(textTheme: textTheme);
}

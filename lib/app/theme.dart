import 'package:flutter/material.dart';

import '../core/config/app_config.dart';

/// Builds the app theme from the venue [Branding] and a [mode] (light or dark).
///
/// The venue's brand is a single seed colour ([Branding.primaryColor]). Each
/// mode has its own background and surface shade. Material 3 derives the text and
/// on-colours for the mode's brightness, so the venue keeps its own dark and
/// light look (for example Carbon charcoal or Espresso brown) while text stays
/// readable by construction. The palette is operator-set from a predefined,
/// contrast-checked list (ADR-0065). The mode is a per-user choice (ADR-0064).
ThemeData buildTheme(Branding b, Brightness mode) {
  final dark = mode == Brightness.dark;
  final background = Color(dark ? b.backgroundColor : b.lightBackgroundColor);
  final surface = Color(dark ? b.surfaceColor : b.lightSurfaceColor);

  // Seed the full scheme from the brand accent, then pin the venue's own surface.
  // The brightness matches the shade, so Material 3's on-colours contrast with it.
  final scheme = ColorScheme.fromSeed(
    seedColor: Color(b.primaryColor),
    brightness: mode,
  ).copyWith(surface: surface);
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      foregroundColor: scheme.onSurface,
    ),
  );

  // Headings in the brand colour and weight, like the venue site. `scheme.primary`
  // (not the raw seed) keeps the heading readable in both modes.
  TextStyle? colored(TextStyle? s) =>
      s?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700);
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

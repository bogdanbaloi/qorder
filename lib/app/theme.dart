import 'package:flutter/material.dart';

import '../core/config/app_config.dart';

/// Builds the app theme from the venue [Branding] and a [mode] (light or dark).
///
/// The venue's brand is a single seed colour ([Branding.primaryColor]). Material
/// 3 derives a full, contrast-safe scheme from it for the requested brightness,
/// so the same venue reads correctly in both light and dark. The mode is a
/// per-user choice (see themeModeProvider), not baked into the palette. The other
/// stored colours (background, surface, accent) are legacy inputs the scheme now
/// derives. Bespoke exact-colour branding is an operator concern, not owner
/// self-serve (ADR-0064).
ThemeData buildTheme(Branding b, Brightness mode) {
  final scheme = ColorScheme.fromSeed(
    seedColor: Color(b.primaryColor),
    brightness: mode,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);

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

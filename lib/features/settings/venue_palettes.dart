import '../../core/config/app_config.dart';

/// A curated, contrast-checked venue palette. The operator picks one whole
/// palette for a venue (ADR-0065), so it is coherent and readable by
/// construction instead of composed by hand. A palette carries one brand accent
/// plus a dark and a light pair (background and surface), so the same venue keeps
/// its own look in both modes while the user toggles light/dark (ADR-0064). The
/// name is operator-facing content, so it stays as written, not translated.
class VenuePalette {
  final String name;
  final int accent; // brand seed colour
  final int darkBackground;
  final int darkSurface;
  final int lightBackground;
  final int lightSurface;
  final bool alternatingBands;

  const VenuePalette({
    required this.name,
    required this.accent,
    required this.darkBackground,
    required this.darkSurface,
    required this.lightBackground,
    required this.lightSurface,
    this.alternatingBands = false,
  });

  /// Applies this palette onto [current], keeping the venue name and font (those
  /// are not part of a colour palette).
  Branding applyTo(Branding current) => current.copyWith(
    primaryColor: accent,
    backgroundColor: darkBackground,
    surfaceColor: darkSurface,
    lightBackgroundColor: lightBackground,
    lightSurfaceColor: lightSurface,
    alternatingCategoryBands: alternatingBands,
  );

  /// Whether [branding] currently uses this palette (accent plus both pairs).
  bool matches(Branding branding) =>
      branding.primaryColor == accent &&
      branding.backgroundColor == darkBackground &&
      branding.surfaceColor == darkSurface &&
      branding.lightBackgroundColor == lightBackground &&
      branding.lightSurfaceColor == lightSurface;
}

/// The curated set, tuned for bars, pubs, restaurants and hotels. Each palette
/// works in both modes: a moody dark pair for the evening and a clean light pair
/// for the day, around one brand accent.
const venuePalettes = <VenuePalette>[
  VenuePalette(
    name: 'Carbon',
    accent: 0xFFF26A21,
    darkBackground: 0xFF2A2A2C,
    darkSurface: 0xFF1E1E20,
    lightBackground: 0xFFF7F5F2,
    lightSurface: 0xFFFFFFFF,
    alternatingBands: true,
  ),
  VenuePalette(
    name: 'Espresso',
    accent: 0xFFD69A4C,
    darkBackground: 0xFF241C16,
    darkSurface: 0xFF1A140F,
    lightBackground: 0xFFFBF6EE,
    lightSurface: 0xFFFFFFFF,
  ),
  VenuePalette(
    name: 'Bordeaux',
    accent: 0xFFC24D6A,
    darkBackground: 0xFF2A1420,
    darkSurface: 0xFF1E0E17,
    lightBackground: 0xFFFBF2F4,
    lightSurface: 0xFFFFFFFF,
  ),
  VenuePalette(
    name: 'Smarald',
    accent: 0xFF3FA97F,
    darkBackground: 0xFF14231C,
    darkSurface: 0xFF0E1A14,
    lightBackground: 0xFFF0F6F2,
    lightSurface: 0xFFFFFFFF,
  ),
  VenuePalette(
    name: 'Miezul nopții',
    accent: 0xFF5B8DEF,
    darkBackground: 0xFF151C2E,
    darkSurface: 0xFF0F1422,
    lightBackground: 0xFFEFF3FA,
    lightSurface: 0xFFFFFFFF,
  ),
  VenuePalette(
    name: 'Cărbune și aur',
    accent: 0xFFC9A24B,
    darkBackground: 0xFF201F22,
    darkSurface: 0xFF17161A,
    lightBackground: 0xFFF7F4EC,
    lightSurface: 0xFFFFFFFF,
  ),
  VenuePalette(
    name: 'Cremă',
    accent: 0xFFB4552D,
    darkBackground: 0xFF241E17,
    darkSurface: 0xFF1A150F,
    lightBackground: 0xFFF5EFE4,
    lightSurface: 0xFFFFFFFF,
  ),
  VenuePalette(
    name: 'Litoral',
    accent: 0xFF2E7D74,
    darkBackground: 0xFF122320,
    darkSurface: 0xFF0C1815,
    lightBackground: 0xFFEEF2F1,
    lightSurface: 0xFFFFFFFF,
  ),
];

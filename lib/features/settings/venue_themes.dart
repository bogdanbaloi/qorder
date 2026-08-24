import '../../core/config/app_config.dart';

/// A curated, contrast-checked branding preset for a hospitality venue. The
/// owner picks one whole theme, so the palette is always coherent and readable,
/// instead of composing four colours by hand (which risks an unreadable mix).
/// The name is venue-facing content, so it stays as written, not translated.
class VenueTheme {
  final String name;
  final int background;
  final int surface;
  final int primary;
  final int accent;
  final bool alternatingBands;

  const VenueTheme({
    required this.name,
    required this.background,
    required this.surface,
    required this.primary,
    required this.accent,
    this.alternatingBands = false,
  });

  /// Applies this theme's colours onto [current], keeping the venue name and
  /// font (those are not part of a colour theme).
  Branding applyTo(Branding current) => current.copyWith(
    backgroundColor: background,
    surfaceColor: surface,
    primaryColor: primary,
    accentColor: accent,
    alternatingCategoryBands: alternatingBands,
  );

  /// Whether [branding] currently matches this theme's four colours.
  bool matches(Branding branding) =>
      branding.backgroundColor == background &&
      branding.surfaceColor == surface &&
      branding.primaryColor == primary &&
      branding.accentColor == accent;
}

/// The curated set, tuned for bars, pubs, restaurants and hotels. Six moody dark
/// palettes and two bright ones, each with text-on-surface contrast that holds.
const venueThemes = <VenueTheme>[
  // Dark, moody: bars, pubs, lounges, hotel bars.
  VenueTheme(
    name: 'Carbon',
    background: 0xFF2A2A2C,
    surface: 0xFF1E1E20,
    primary: 0xFFF26A21,
    accent: 0xFFFFD400,
    alternatingBands: true,
  ),
  VenueTheme(
    name: 'Espresso',
    background: 0xFF241C16,
    surface: 0xFF1A140F,
    primary: 0xFFD69A4C,
    accent: 0xFFE8C98A,
  ),
  VenueTheme(
    name: 'Bordeaux',
    background: 0xFF2A1420,
    surface: 0xFF1E0E17,
    primary: 0xFFC24D6A,
    accent: 0xFFE0B25C,
  ),
  VenueTheme(
    name: 'Smarald',
    background: 0xFF14231C,
    surface: 0xFF0E1A14,
    primary: 0xFF3FA97F,
    accent: 0xFFD8B65A,
  ),
  VenueTheme(
    name: 'Miezul nopții',
    background: 0xFF151C2E,
    surface: 0xFF0F1422,
    primary: 0xFF5B8DEF,
    accent: 0xFFE2C36B,
  ),
  VenueTheme(
    name: 'Cărbune și aur',
    background: 0xFF201F22,
    surface: 0xFF17161A,
    primary: 0xFFC9A24B,
    accent: 0xFFE8D08A,
  ),
  // Bright: cafés, brunch, Mediterranean restaurants.
  VenueTheme(
    name: 'Cremă',
    background: 0xFFF5EFE4,
    surface: 0xFFFFFFFF,
    primary: 0xFFB4552D,
    accent: 0xFF6E8B5B,
  ),
  VenueTheme(
    name: 'Litoral',
    background: 0xFFEEF2F1,
    surface: 0xFFFFFFFF,
    primary: 0xFF2E7D74,
    accent: 0xFFE0803C,
  ),
];

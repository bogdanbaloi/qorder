# 0064 - Theme: venue accent plus per-user light/dark mode

## Status

Accepted. Supersedes the theming parts of ADR-0060 (owner self-serve colours)
and the curated-preset picker (REQ-CFG-007).

## Context

Two earlier steps let the owner shape the look. ADR-0060 gave the owner four raw
colour pickers (background, surface, primary, accent). REQ-CFG-007 added curated
presets on top, each preset locked to a fixed light or dark background.

Both had the same flaw: brightness was baked into the palette. A venue was light
or dark by its stored colours, so a person could not choose the mode that suits
them. A hand-composed mix could still be unreadable. The owner also carried a
design burden they did not want. A genuinely bespoke look (exact brand shades)
was never really self-serve anyway.

The owner asked for a cleaner split: the owner and the customer each pick light
or dark for themselves, while the venue's brand is a single decision handled by
us, with a truly custom design offered as a paid service.

## Decision

Two independent axes.

- **Brand accent (venue).** The venue's identity is one seed colour
  (`Branding.primaryColor`). `buildTheme(Branding, Brightness)` feeds it to
  `ColorScheme.fromSeed` for the requested brightness, so Material 3 derives a
  full, contrast-safe scheme. No raw colour overrides, so contrast holds in both
  modes by construction rather than by eye. The stored `backgroundColor`,
  `surfaceColor` and `accentColor` become legacy inputs the scheme now derives.
  They stay in the `Branding` model for now (config round-trip, no migration in
  this slice) but no longer drive the theme.
- **Light/dark (user).** A `themeModeProvider` holds a `ThemeMode`, a per-device
  choice like the language. It follows the system by default, persists to local
  storage and is flipped by an `AppBarToggles` control shown on every surface, so
  owner and customer each set their own look (REQ-CFG-008). `MaterialApp` supplies
  `theme`, `darkTheme` and `themeMode`.
- **Owner Settings.** The raw colour pickers and the preset picker are removed.
  The owner keeps the venue name and the loyalty program. Two notes explain where
  appearance lives (the top-bar toggle) and that a custom design is a paid service.

## Consequences

- The same venue reads correctly in light and dark. A test computes WCAG contrast
  for both modes rather than trusting the eye.
- The owner cannot compose an unreadable palette, because they no longer compose
  one at all. Setting the venue accent moves to the operator (a follow-up slice),
  and a bespoke look is a paid, operator-delivered design.
- `LanguageToggle` no longer hard-codes white text (it vanished on a light bar).
  It now takes the app-bar foreground colour, so both toggles read in either mode.
- Removing the preset picker deletes `venue_themes.dart` and `brand_palette.dart`
  and their contrast test. The accent-selection UI returns for the operator, not
  the owner, in the next slice.

# 0065 - Operator sets the venue palette from a predefined set

## Status

Accepted. Builds on ADR-0064 (accent plus per-user light/dark).

## Context

ADR-0064 made the theme derive from a single brand accent, with light and dark a
per-user choice. It left one question open: who sets the accent and how.

Owner self-serve colour editing was removed in ADR-0064, because an owner could
compose an unreadable mix and it was a support burden. The owner asked for the
palette to be an operator decision instead: we (the operator) set each venue's
look. A genuinely bespoke design is a paid service. ADR-0064 also flattened
every venue to a neutral Material 3 surface tinted by the accent, which lost the
moody per-venue backgrounds (Carbon charcoal, Espresso brown) that give a bar its
character.

## Decision

The operator picks a whole palette per venue from a predefined, contrast-checked
set.

- A `VenuePalette` is one brand accent plus a dark pair (background and surface)
  and a light pair. `buildTheme` picks the pair for the current mode and seeds the
  Material 3 scheme with the accent, so the venue keeps its own dark and light
  look while text stays readable for the mode's brightness. `Branding` grows a
  light pair (`lightBackgroundColor`, `lightSurfaceColor`). The existing
  background and surface become the dark pair. Both are optional in JSON, so an
  older saved config stays valid and falls back to a neutral light.
- The predefined set (`venue_palettes.dart`) is curated, not free-form. A test
  computes WCAG contrast for every palette in both modes, so a palette cannot ship
  unreadable. Free-form custom colours are a paid, operator-delivered design, not
  a self-serve field.
- The Admin (operator) screen gains a palette picker. Tapping a palette applies it
  to the active venue's branding, saves it through the `VenueConfigApi` and pushes
  it into the session-live override (ADR-0061), so the app re-themes at once.

## Boundary (this slice)

The backend `PUT /venues/:id/config` is owner-only (ADR-0060). The operator does
not yet have a backend write path, so the picker round-trips fully in the offline
demo (the in-memory mock) but a real deployment needs an operator-authorized
write. That write touches privilege boundaries (the operator would write a whole
venue document, including access codes), so it gets its own slice and ADR rather
than being widened in here. The Admin picker also sets the active venue only.
Choosing which venue to configure in a multi-venue operator view is a follow-up.

## Consequences

- The venue's brand is one operator decision from a safe menu, not a per-colour
  composition. An unreadable palette cannot be picked, because the set is
  contrast-checked.
- Each venue keeps a distinct dark and light identity, so the moody bar look is
  back without risking readability.
- Adding a palette is a data change in `venue_palettes.dart` plus its contrast
  test, no widget change.

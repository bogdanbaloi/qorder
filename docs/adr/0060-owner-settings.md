# 0060 - Owner Settings: venue config persisted server-side

## Status

Accepted

## Context

The venue config is data, read through `VenueConfigSource` (ADR-0050) and loaded
from a bundled asset (ADR-0052). Reading was the easy half. The owner had no way
to change their own venue: editing a colour or the venue name meant editing the
asset and shipping a new build.

This slice adds the write half, the owner Settings screen, for the first and
safest field set: the venue name and the four brand colours. The design map
(`docs/onboarding-and-config.md`) flagged the open question of how much the owner
edits self-serve. Branding is the answer for slice one: visible, low-risk and the
canonical "change a colour, no redeploy" case. Access codes, loyalty and table
policy come later, since a self-served owner-code change could lock the owner
out and needs more care.

## Decision

A thin vertical slice, from the screen to the database.

- `AppConfig.toJson` (with `Branding`, `TableNumberPolicy`, `LoyaltyProgram`,
  `RewardTier`) is the inverse of `fromJson`. Colours write as `0xAARRGGBB` hex,
  the human-editable form the factory already reads, so a config round-trips. A
  test asserts the round-trip. `backendBaseUrl` is a deployment overlay, not
  venue data, so it is left out of the document.
- A `VenueConfigStore` on the BFF holds one opaque JSON document per venue. The
  BFF never reads inside it, so the client owns the `AppConfig` shape. Postgres
  and in-memory implementations, the Postgres one behind `runInVenue` so RLS
  scopes it (ADR-0059).
- `GET /venues/:id/config` is open (the customer app will read it), returning 404
  when nothing is saved so the client keeps its bundled asset. `PUT` is
  owner-only, since it changes what every customer sees.
- On the client, a `VenueConfigApi` port (the write side of `VenueConfigSource`)
  with a remote implementation (owner-authenticated) and an in-memory mock, so
  the offline demo still round-trips. The `OwnerSettingsScreen` (View) forwards
  edits to an `OwnerSettingsController` (ViewModel) that seeds a draft from the
  active config, edits it and saves through the port, then re-fetches so the
  draft shows exactly what persisted. A live preview shows the colours applied.

## Boundary (this slice)

The customer-facing read path stays on the bundled asset. `VenueConfigSource`
is synchronous, so making the live customer app read the saved config from the
backend means an async config source resolved at bootstrap, which reshapes the
startup path. That propagation is a follow-up (REQ-CFG-005, done in ADR-0061 via
a bootstrap overlay). This slice proves the round-trip end to end (edit, save
server-side under RLS, re-read shows the persisted value), which is the
foundation that follow-up builds on.

## Consequences

- An owner edits the venue name and brand colours. They persist server-side, per
  venue, isolated by RLS. No app release for a branding change.
- The document is opaque to the BFF, so extending the editable field set is a
  client-only change (add a field to the screen and the ViewModel), no backend
  change.
- The write is owner-authenticated. A staff token is refused (a test proves it).
- Colour editing is a tap-a-swatch palette, not a hex field, since an owner does
  not know hex codes. The palette is a curated, dependency-free set (no external
  colour-picker package), so venues stay coherent and the analyzer stays clean.
  A full spectrum picker (any colour) is a later option if a venue needs its
  exact brand shade.

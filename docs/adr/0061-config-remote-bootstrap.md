# 0061 - Saved config reaches customers via a bootstrap overlay

## Status

Accepted

## Context

Owner Settings (ADR-0060) persists a venue's config server-side, but the
customer-facing app still read its branding from the bundled asset. So an owner
changed a colour and saved it, but customers kept seeing the old colour. ADR-0060
named this gap as REQ-CFG-005. This closes it.

The obstacle is the read API. `VenueConfigSource.configFor` is synchronous, and
`appConfigProvider` is a synchronous provider that the whole app watches. A
remote read is asynchronous. Making the source async would turn
`appConfigProvider` into a `FutureProvider` and ripple an `AsyncValue` through
every consumer, a large and risky change for a colour.

## Decision

Prefetch and overlay at bootstrap, keeping the read path synchronous.

- `loadVenueConfigSource` gains an optional `VenueConfigApi`. When a backend is
  configured, after parsing the asset catalogue it fetches each venue's saved
  config and overlays it on the asset, then builds the in-memory source from the
  merged list. `configFor` stays synchronous.
- Each fetch degrades open: a miss (nothing saved) or an error (a down backend)
  keeps the asset config for that venue, so startup never blocks on the server.
- The saved document omits `backendBaseUrl` (a deployment overlay), so the
  loader re-applies it, exactly as the asset path already does.
- `main.dart` passes a `RemoteVenueConfigApi` only when `QORDER_BFF_URL` is set.
  The read is public (no owner token), since it is the same config customers see.

## Consequences

- An owner edit reaches customers at their next app open, no release. For a QR
  ordering app, where each customer opens the app fresh from the sticker, this is
  effectively live for every new session.
- A customer with the app already open keeps the config from their open, until
  they reopen. Acceptable: sessions are short and per-visit.
- The read path stays synchronous, so no consumer changes. The cost is one round
  of fetches at startup, bounded by the number of venues and run in a
  degrade-open try, so a slow or down backend cannot brick the app.
- Live push of a config change to open sessions is a later option (the same
  channel that would replace order polling), not needed for this model.

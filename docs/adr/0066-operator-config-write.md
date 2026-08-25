# 0066 - The operator may write a venue's config

## Status

Accepted. Resolves the boundary left open by ADR-0065.

## Context

ADR-0065 put the venue-palette picker on the Admin (operator) screen, but the
backend `PUT /venues/:id/config` was owner-only (ADR-0060). So the picker
round-tripped in the offline demo (the in-memory mock takes no auth) yet failed
on a real backend with "Could not save. Check your owner access.", because the
Admin screen has no owner token. The Admin screen carries an operator token, but
it only unlocked cross-venue metrics, not a config write, so the two never
connected.

The palette is an operator action, so the operator needs to be able to write it.

## Decision

The platform operator is a superadmin over every venue, more privileged than a
single venue's owner, so the operator may write any venue's config.

- **Backend.** `PUT /venues/:id/config` now passes when the caller is the venue's
  owner (as before) OR the platform operator (the configured operator token).
  A wrong or missing token is still refused. The document stays stored opaque, so
  the route's shape does not change.
- **Client.** A separate `adminVenueConfigApiProvider` authenticates the write
  with the operator token (not the session token). The admin palette controller
  uses it. Offline it delegates to the same mock as the owner writer, so the demo
  still round-trips.
- **UX.** The operator enters the operator token on the Admin screen (the field
  that already unlocks metrics). With it set, applying a palette saves on the
  backend. So the operator token now authorizes every operator action, not only
  reads.

## Trade-off

The operator write accepts the whole config document, so in principle it could
change more than branding (for example the access codes). This is deliberate: the
operator is a superadmin. The client only ever sends back the venue's current
config with the palette swapped in, so nothing else changes in practice. A
field-level restriction (a branding-only operator route that reads and merges just
that key) is a later hardening if multi-tenant trust ever needs it. It is not
worth the opacity break and the partial-document handling now.

## Consequences

- Setting a venue's palette from the Admin screen works against the real backend,
  not only the offline demo. The picker's boundary from ADR-0065 is closed.
- The operator token is now the single credential for operator actions (metrics
  and config writes alike), which is easier to reason about than two auth paths.
- The write is still refused for a wrong token and for a staff token, so the
  surface stays closed to everyone but the owner and the operator.

# 0058 - Operator admin UI (cross-venue cockpit)

## Status

Accepted

## Context

REQ-OPS-001 shipped the operator evidence as a backend endpoint only
(`GET /platform/metrics`, behind an operator token). Reading it meant a curl
call. We want a screen so the operator can see cross-venue usage without a
terminal.

This is the operator plane, not the owner plane. The owner dashboard is one
venue's view, gated by a per-venue owner code. The operator view spans every
venue, gated by the platform operator token. They are different audiences and
different secrets, so they are different screens.

## Decision

Add an `AdminScreen` at `/admin`, outside the owner role guard.

- The screen holds an obscured token field. The operator pastes the token and
  loads. The token lives only in an `operatorTokenProvider` for the session. It
  is never persisted on the device.
- A `RemotePlatformMetricsSource` calls `GET /platform/metrics` with the token
  as a bearer header. Unlike the customer sources, it does NOT degrade open on
  error. A wrong token or an unreachable backend surfaces as an error message,
  so the operator learns the token is wrong instead of seeing a blank screen.
- The domain owns `PlatformMetrics` and `VenueUsage`, parsed from the same JSON
  the BFF already returns. The screen renders a venue count and a table of
  venue, orders, users.
- The source sits behind a `PlatformMetricsSource` port, wired in the
  composition root: the remote source when the app targets a real backend, a
  mock empty snapshot otherwise. The screen never names a concrete source.

## Consequences

- The operator gets a read-only cockpit with no new backend surface. The
  endpoint and its token gate already existed.
- The token is not stored, so a shared device does not leak it. The cost is
  re-entry each session, which fits a rare operator task.
- The route is unguarded because the token IS the gate. An empty token returns
  an empty snapshot, so a stray visit shows nothing.
- Access control stays coarse. Any holder of the operator token sees every
  venue. Per-operator scoping is a later decision if we ever have more than one
  operator.

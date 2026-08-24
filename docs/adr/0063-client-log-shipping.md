# 0063 - Client logs shipped to the backend and persisted

## Status

Accepted

## Context

The logging seam (ADR-0062) made failures visible, but client logs went only to
the browser console. A failure on a patron's phone never reached the operator,
who has no way to open that device's console. For a product moving toward
production, invisible client failures are a real blind spot.

## Decision

Ship the client's warnings and errors to the BFF and persist them.

- **Client:** a `RemoteLogger` (an `AppLogger`) posts warning and error records
  to `POST /logs`. Debug and info are dropped. Shipping is fire-and-forget, its
  own failure is swallowed. It never routes back through this logger, so a
  logging call cannot throw, block, or loop. A per-window cap (20 per minute)
  stops a runaway loop from flooding the network. A `CompositeLogger` fans each
  record to both the console and the remote sink, so nothing is lost locally.
  Each record carries the active `venueId`, so the operator sees where it broke.
- **BFF:** `POST /logs` is public (a signed-out client can still report) and
  bounded: at most 50 records per request, each message capped at 500 chars. It
  persists through a `LogStore` port (Postgres in production, in-memory for dev)
  and echoes each record to the live server log stream. `GET /logs` returns the
  most recent records behind the operator token, so the operator can read client
  diagnostics cross-venue.
- **Storage:** a global `client_logs` table (operator-plane diagnostics, not
  tenant data), so it is not under RLS. `venue_id` is a plain filter column.

## Boundary and hardening (follow-up)

`POST /logs` is unauthenticated, so a caller could still post bounded junk. The
size caps limit the blast radius. Per-IP rate limiting and retention pruning
followed in REQ-OBS-004. At pub scale, with
warning-and-error-only, throttled shipping, the volume is low. A dedicated log
aggregator (Sentry, Loki) is the scale-up path beyond a Postgres table.

## Consequences

- The operator now sees failures that happen on customer and staff devices, in
  the same place as server logs and durably in Postgres.
- Behaviour is unchanged for the user: shipping is best-effort and silent on
  failure, so a down backend never affects the app.
- The client log volume is bounded by level (warning and error only) and by the
  per-window cap, so the endpoint cannot be turned into a flood by the app.

# 0079 - Projections on the public reads

## Status

Accepted. Closes the two PII follow-ups left open by ADR-0070 (opaque order id)
and ADR-0071 (gated table view).

## Context

Two public reads returned more than the caller needs:

- `GET /orders/:id/status` returned the full order (`order.toJson()`): customer
  name, client id, table, line items and total. The id is opaque now (ADR-0070),
  so it cannot be enumerated, but whoever holds one still saw the whole order.
- `GET /venues/:id/tables/:t/orders` returned each patron's raw `clientId`. The
  view is gated to patrons on the table (ADR-0071), but they still saw each
  other's device ids, which they do not need.

The client reads only the `stage` from the status poll. It never uses the table
entry's `clientId` (it is parsed but unused). So both were leaking data no caller
consumes.

## Decision

Return a projection: only the fields the read needs.

- **Status.** `_status` returns `{serverOrderId, sequence, stage, stamps}`, the
  stage and timings a customer polls for, not the name, client id, line items or
  total. So a leaked id exposes only the status, not the order's PII.
- **Table view.** The entries drop `clientId`. `isMine` is computed by the backend
  from the caller's clientId, so the client still marks its own rows without any
  patron's raw id crossing the wire. `TableEntry` drops the unused field. Both the
  remote and the in-memory ledger stop setting it.

## Consequences

- The public reads carry no PII beyond what each needs: the status is just a
  status. The table shows names and items without device ids. A test asserts the
  status projection omits the PII and the table entries omit the clientId.
- The client is unaffected: it read only `stage` from the status. It never used
  the entry's clientId.
- These close the residual exposure the opaque-id and table-gate slices left. The
  scalable attacks (enumeration, outsider scrape) were already shut; this trims
  what a legitimate holder sees to the minimum.

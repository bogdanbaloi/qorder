# 0059 - Row-Level Security for tenant isolation

## Status

Accepted

## Context

The tenant boundary was enforced only in application code: every tenant-scoped
query filters on `venue_id`. The store ports mandate a `venueId`, so the filter
is hard to forget. But "hard to forget" is not "cannot forget". One
missing `WHERE venue_id` in a future query would leak a whole venue's rows to
another venue. For a product we sell to many pubs, one such slip is a breach.

The persistence ADRs (0053 onward) named Row-Level Security as the DB-level
guard that follows. This is that slice.

The obstacle: Postgres RLS is bypassed by a superuser and by the table owner.
Local Docker and the tests connect as `postgres`, which is both. Connecting the
app as a separate login role would bifurcate the connection string and the
migration bootstrap.

## Decision

Keep one connection, but drop privilege per transaction.

- A migration (`0005_rls.sql`) creates a login-less role `qorder_app`, grants it
  DML on the tables, enables RLS on the four tenant tables (`consent`, `orders`,
  `venue_order_counters`, `redemptions`) and adds one policy per table. The
  policy admits a row when its `venue_id` equals `current_setting('app.venue_id')`
  or when that GUC is the sentinel `'__all__'`. A missing GUC reads as NULL, so
  nothing matches: it fails closed.
- Every tenant transaction runs through a `runInVenue(pool, venueId, body)`
  helper that does `SET LOCAL ROLE qorder_app` (so RLS is no longer bypassed)
  and `set_config('app.venue_id', venueId, true)`, both reset at transaction
  end. The tenant stores route all their statements through it.
- Operations that are cross-venue by nature (the operator metrics snapshot) run
  under the `'__all__'` sentinel, the one path the policy opens to all venues.
- Identity tables stay GLOBAL and out of RLS: a person is the same at any venue.

## Boundary (this slice)

Enforcement covers the operations that carry a venue at their call site, which
is every listing and read where a forgotten filter would leak a tenant. The
operations addressed by `server_order_id` (accept, the stage stamps, relink) and
the public `status` poll do not carry a venue at their call site, so they run
under `'__all__'`. `status` is inherently venue-less (the customer polls with
only the order id). Threading the venue through the staff-authenticated
mutations (from the staff token's claims) is a follow-up (REQ-PERSIST-006), not
a hole in the listing surface this slice protects.

## Consequences

- A forgotten `WHERE venue_id` on a listing can no longer leak another venue's
  rows: the database refuses them. A test proves a bare `SELECT` with no filter
  returns only the scoped venue's rows.
- `FORCE ROW LEVEL SECURITY` is not used. The app never queries as the table
  owner (it drops to `qorder_app` first), so a plain `ENABLE` already applies.
- A managed admin that is not a superuser must be a member of `qorder_app` to
  `SET ROLE` to it. The migration grants that membership.
- The `SET LOCAL` pair costs two extra statements per transaction. Acceptable
  for the isolation guarantee.

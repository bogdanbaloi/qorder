# 0071 - Gate the shared-table view to patrons on the table

## Status

Accepted. Fourth item of the pre-production security review (SEC-4).

## Context

`GET /venues/:id/tables/:t/orders` powers the shared-table view: a patron sees who
else is at their table and what they ordered, with `isMine` marking their own. The
route was public, keyed by venue and table number (small integers). So anyone
could walk the table numbers of any venue and scrape every patron's name and order
lines, an enumeration of PII, not just the view for the people at the table.

There is no server-issued table session (an anonymous patron has no token), so a
plain token gate does not fit. The only signal that ties a device to a physical
table is that it placed an order there.

## Decision

You may see a table only if you are on it.

- `_tableOrders` returns the entries only when the caller's `clientId` (already
  passed, for `isMine`) has an order at that table. Otherwise it returns an empty
  view. So a patron who has ordered sees the shared table. An outsider sees
  nothing.
- The `clientId` is self-asserted, but a valid one for a given table is a random
  device id, not guessable, so an attacker cannot forge their way onto a table
  they never ordered at.
- An empty view is returned as a 200 (not a 403), because the client already
  treats a non-200 as empty and this is graceful for a patron who has not ordered
  yet.

## Consequences

- The shared-table view can no longer be enumerated by outsiders. A test proves a
  patron on the table sees the orders while a client with no order there sees an
  empty view.
- A patron who has not ordered yet sees an empty table until their first order.
  That is an acceptable trade for closing the scrape. It matches the flow
  (order, then watch the table fill).
- The response still carries each patron's `clientId` to the people on the table.
  Dropping it (the client computes `isMine` from the server's bool) is an optional
  hardening that also needs a client change, so it is deferred.

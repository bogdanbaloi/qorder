# 0070 - Opaque order id

## Status

Accepted. Third item of the pre-production security review (SEC-3).

## Context

`GET /orders/:id/status` is public, so a customer can poll their order without a
token (the app has no session for an anonymous order). The order id was
`BFF-<venue>-<sequence>` (and `BFF-<sequence>` in the in-memory store), a
per-venue counter starting at 1. So the id was guessable: anyone could walk
`BFF-demo-1`, `BFF-demo-2`, ... and read every order. And `order.toJson()` returns
the customer name, client id, table, line items and total. A public poll with a
guessable key is an enumeration of every order plus its PII.

## Decision

Keep the poll public, make the id unguessable.

- The order id gains a secure random suffix (`secure_id.dart`, `Random.secure()`,
  64 bits of hex): `BFF-<venue>-<sequence>-<random>`. Both stores (in-memory and
  Postgres) mint it the same way.
- The per-venue `sequence` is unchanged. It stays the readable display number the
  customer and staff see (`Order #5`), separate from the lookup id.
- So the status poll stays open (no token), but the id now works like a capability:
  only the customer who placed the order holds it. Walking the sequence returns
  404.

## Consequences

- The public status route can no longer be enumerated. A test proves the guessable
  sequence id returns 404 while the real opaque id resolves.
- The display number the customer sees does not change (it is the sequence).
- A leaked id still exposes that one order (it is a capability). Reducing the
  status response to a status-only projection (drop customer name, client id and
  line items from the poll) is a separate, optional hardening. This change stops
  the scalable attack, the enumeration.
- Order ids are not comparable or ordering-bearing any more (they were not relied
  on for order anyway, the sequence carries that).

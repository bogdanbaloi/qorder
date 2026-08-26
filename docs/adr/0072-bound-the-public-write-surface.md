# 0072 - Bound the public write surface

## Status

Accepted. Items SEC-9 and SEC-10 of the pre-production security review, done
together (both bound the same public write surface).

## Context

Two public routes take a body without a token: `POST /venues/:id/orders` (a
customer places an order) and `POST /venues/:id/tables/:t/requests` (a customer
calls the waiter). Neither was throttled, so orders and waiter calls could be
spammed. And no route had a body-size limit, so a huge payload could exhaust
memory on read. Only `POST /logs` was throttled.

## Decision

Bound both the size and the rate of what the public can send.

- **Body size.** A `_bodyLimit` middleware in the pipeline refuses any request
  whose declared `Content-Length` exceeds 64 KB with a 413, before the body is
  read. 64 KB is generous for the app's JSON (an order, a config, a bounded log
  batch are all a few KB). A chunked request with no declared length is not bounded
  here, a later hardening.
- **Write rate.** A `publicWriteLimiter` (per caller IP, 60 a minute) guards
  `_submit` and `_raiseRequest`, returning 429 over the budget. The two share one
  budget. It is loose, since a busy venue's patrons share one NAT IP, while it
  still bounds a single abuser.

## Consequences

- A huge body is rejected cheaply. The public write routes cannot be flooded.
  A test proves the 413 and the 429.
- The limits are per instance (in-memory buckets), the same caveat the log limiter
  carries: across replicas a shared limiter store is needed.
- The rate limit is by IP, so many patrons behind one NAT share a budget. 60 a
  minute leaves headroom for a busy venue while still slowing an abuser. A tighter
  per-device signal would need a trusted client id, which the anonymous order flow
  does not have.

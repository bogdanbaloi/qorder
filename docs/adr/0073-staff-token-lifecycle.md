# 0073 - Staff/owner token lifecycle

## Status

Accepted. Item SEC-5 of the pre-production security review.

## Context

Staff and owner sign-in issued a token that never expired and was stored in an
in-memory map with no revocation. So a leaked token was valid forever. The token
was also generated with `Random()`, not a secure source, so it was more
predictable than it looked.

## Decision

Give the token a lifetime and a secure source.

- **Secure generation.** `_randomToken` now draws from `Random.secure()`, so a
  token cannot be guessed from a weak PRNG.
- **Expiry.** Each issued token is stamped with an expiry (`issued + TTL`, 12h by
  default, long enough for a shift). `claims()` returns null past the expiry and
  evicts the token, so an expired token no longer authenticates. `authenticate`
  and `claims` take an optional `nowMs`, so the callers pass nothing (real time)
  and tests drive the clock deterministically.
- A null claims result is a 403 on the route, which the client already turns into
  a sign-out (REQ-IDENT-005), so an expired token cleanly sends the user back to
  the code gate.

## Consequences

- A leaked token stops working after its lifetime, not never. A test proves a
  token is valid within the TTL and rejected past it.
- Explicit revocation (a server-side logout that kills a token on demand) is a
  follow-up: it needs a logout endpoint and a client call. The TTL bounds the
  window in the meantime.
- The token store is still in memory, so tokens are also lost on a restart, and
  they are per instance. A persistent, shared store (and real per-venue staff
  provisioning) is the separate SEC-8 item.

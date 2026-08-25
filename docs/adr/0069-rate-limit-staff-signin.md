# 0069 - Rate limit staff/owner sign-in

## Status

Accepted. Second item of the pre-production security review (SEC-2).

## Context

Staff and owner sign in with a short per-venue access code (4 digits in the demo)
at `POST /venues/:id/staff/auth`, which returns a scoped token. The route had no
rate limit, so the code space was small enough to brute-force in minutes. Only the
public `POST /logs` was throttled.

## Decision

Bound sign-in attempts per caller IP, reusing the existing `RateLimiter`.

- A second `RateLimiter` (`staffAuthLimiter`) guards `_staffAuth`, with a tight
  budget (10 attempts per minute) separate from the looser log budget. A real
  staff member signs in rarely, so the budget leaves ample headroom while it slows
  an attacker to a crawl.
- The guard runs first, before the code is checked, so over the budget even a
  correct code is refused with 429. A refused burst is logged, so it is visible.
- The limiter is injectable, so a test drives it with a small budget.

## Consequences

- The short code can no longer be brute-forced from one IP: 10 tries a minute
  turns even the 4-digit space into hours. It composes with longer codes later.
- A distributed attack from many IPs is not fully stopped by a per-IP limit. A
  per-venue budget would help but would let one attacker lock out a venue's staff,
  so it is a later call if needed. Longer or rotatable codes (a separate item)
  raise the floor regardless.
- In-memory buckets are per instance. Across replicas a shared limiter store is
  needed, the same caveat the log limiter already carries.

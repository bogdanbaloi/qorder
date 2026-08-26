# 0075 - Configurable CORS origin and constant-time operator token

## Status

Accepted. Items SEC-11 and SEC-12 of the pre-production security review, done
together (both small hardenings of the same HTTP surface).

## Context

Two loose ends on the BFF's edge:

- The CORS response hard-coded `Access-Control-Allow-Origin: *`, so any origin
  could call the API from a browser. Bearer auth limits the impact (an attacker's
  page cannot read the victim's token), but a production deploy should still lock
  the origin.
- `_operatorOk` compared the bearer to the operator token with `==`, which short
  circuits on the first differing byte. The high-value operator token is then
  observable through response timing.

## Decision

- **CORS origin is configurable.** `OrderApi.allowedOrigin` (default `*`) sets the
  `Access-Control-Allow-Origin` header. `server.dart` reads `QORDER_ALLOWED_ORIGIN`,
  so dev and the demo stay on `*` while production locks it to the app's origin.
  The static method and header allowances are unchanged.
- **Constant-time token compare.** `_constantTimeEquals` compares every byte
  regardless of where a mismatch is, so verifying the operator token does not leak
  it through timing. The length check is not secret (the token length is fixed).

## Consequences

- A production deploy can restrict which origin the browser app is served from,
  without touching code. Dev and the demo are unaffected (default `*`).
- The operator token compare no longer short circuits. A test proves the compare
  stays correct: the exact token passes, while a wrong token or a prefix of it is
  refused.
- Both limits are edge hardenings. They do not replace the deeper items (TLS,
  secret management), which stay on the review list.

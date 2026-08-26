# 0076 - Error and log hygiene

## Status

Accepted. Items SEC-13 (log hygiene) and SEC-14 (error responses) of the
pre-production security review.

## Context

Two edges of what the server reveals:

- **Errors.** Nine handlers call `jsonDecode(await request.readAsString())` with no
  guard, so a malformed body throws. An uncaught error can surface as a 500 that
  carries the exception message, or a stack trace, to the client.
- **Logs.** A production log must not carry secrets or PII. An audit of the BFF
  logs found the existing lines already clean (they log a venue id, a role or a
  rate-limit event, not a token or a code). The one place that logged the OTP is
  demo-only and already gated (ADR-0068). The gap was that a new error path could
  log the request body while reporting a failure.

## Decision

One middleware closes both.

- `_catchErrors` wraps the pipeline. It catches any uncaught error, returns a
  generic `{"error":"internal error"}` 500 (no message, no stack trace). It logs
  the failure server-side by its exception type and the route only, never the
  request body. So an error leaks nothing to the client. The log line that records
  it carries no body content or PII.

## Consequences

- A malformed or hostile request that throws now gets a clean 500. The client
  learns nothing about the internals. A test asserts the body is the generic error
  with no `FormatException` and no stack frame.
- The error is still visible to the operator (type and route), enough to diagnose
  without echoing user data into the log.
- The existing logs were already free of secrets and PII (audited), so no other
  log line needed changing. The client-shipped log messages stay bounded (ADR-0063).

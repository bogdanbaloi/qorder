# 0068 - The OTP code is not exposed in production

## Status

Accepted. First item of the pre-production security review (SEC-1).

## Context

Customer sign-in uses a phone OTP. To run the demo without an SMS provider, two
shortcuts leaked the code: `POST /auth/otp/start` echoed it as `devCode` in the
response. The default `DevSmsSender` also printed it to stdout. Both are fine for a
local demo but a full OTP bypass in production. Worse, `exposeDevCode` defaulted to
`true` while `server.dart` never turned it off. So a naive deployment leaked every
OTP through the response and the logs.

## Decision

Fail closed. The code is a demo affordance a deployment opts into, never the
default.

- `OrderApi.exposeDevCode` now defaults to `false`. The `devCode` field is added
  to the response only when it is `true`.
- `server.dart` reads `QORDER_EXPOSE_DEV_CODE`. Only an explicit `true` turns the
  echo on and selects `DevSmsSender` (which logs the code). Anything else, the
  default, selects `SilentSmsSender`, which neither returns nor logs the code.
- `SilentSmsSender` also does not deliver, so OTP sign-in is inert in production
  until a real SMS adapter (Twilio / Infobip) replaces it. That is a deliberate
  fail-closed state, not a silent leak.

## Consequences

- A production deployment cannot leak the OTP through the response or the logs.
  The demo still works by setting `QORDER_EXPOSE_DEV_CODE=true`. A test covers both
  the default (no `devCode`) and the opt-in (a `devCode` is present).
- OTP delivery in production is not yet functional: wiring a real SMS provider
  behind the `SmsSender` port is the follow-up. Sign-in with a real code needs it.
- The client already reads `devCode` as nullable, so it tolerates a response
  without it.

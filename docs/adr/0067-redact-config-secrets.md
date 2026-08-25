# 0067 - Redact access codes from the public config response

## Status

Accepted. Hardens ADR-0060 and ADR-0061 (the venue config document and its open
read).

## Context

`GET /venues/:id/config` is public by design, so the customer app can read a
venue's branding, menu, table policy and loyalty without a token (ADR-0061). The
handler returned the stored document verbatim.

The stored document is the client's `AppConfig.toJson()`, which includes
`staffAccessCode` and `ownerAccessCode`. So the open endpoint returned the staff
and owner access codes to anyone. On the real backend those codes are the same
ones the staff auth store checks, so a reader could recover a code from the public
GET and sign in as staff or owner. This is a real exposure, present since the
config write landed (ADR-0060/0061), not introduced by the theming work.

## Decision

Redact the secret keys from the public response.

- `GET /venues/:id/config` returns a copy of the stored document with
  `staffAccessCode` and `ownerAccessCode` removed. The copy is redacted, so the
  stored document is untouched. The customer-facing fields are still served.
- The redacted keys are named in one place (`_secretConfigKeys`), so adding a
  future secret to the config shape is a one-line change here.

This closes the exposure at the point of exposure (the open read), so it protects
a document that already carries the codes, not only new writes.

## Alternatives considered

- **Drop the codes from `AppConfig.toJson`** (keep secrets out of the document
  entirely). Cleaner in principle, but it does not protect a config already stored
  with codes. It also ripples through the client's config round-trip. The codes the
  backend actually checks live in the staff auth store, not in this document, so a
  document already saved with codes is exactly the case that needs covering. GET
  redaction covers it.

## Trade-off

The BFF now knows two keys of an otherwise opaque document, a small, deliberate
break of the opacity from ADR-0060, scoped to redaction. The codes still travel on
the owner-authenticated `PUT` and sit in the stored document at rest. That is
behind auth, not the open read, so it is out of scope here. Keeping secrets out of
the config document entirely is a possible later change.

## Consequences

- The open config read no longer leaks the staff or owner access codes. A test
  proves a saved config's codes do not appear in the GET response while branding
  still does.
- The customer app is unaffected: it never needed the codes from the read (online
  sign-in is verified by the staff auth store). A missing code falls back to the
  default in `fromJson`.

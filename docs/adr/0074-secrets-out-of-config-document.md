# 0074 - Keep the access codes out of the config document

## Status

Accepted. Item SEC-6 of the pre-production security review. The defence-in-depth
follow-up to ADR-0067 (which redacted the codes from the read).

## Context

ADR-0067 stopped the open `GET /venues/:id/config` from returning the staff and
owner access codes, by redacting them from the response. But the codes still
travelled on the owner `PUT` and sat in the stored document at rest, so the
redaction was the only thing standing between a stored secret and a public read.

The codes are not customer-facing config. The backend verifies them against its
own staff auth store. The offline mock reads them from the bundled asset. So they
need not be in the document the client writes to the backend at all.

## Decision

Keep the secrets out of the wire document entirely.

- `AppConfig.toJson` no longer writes `staffAccessCode` or `ownerAccessCode`. So a
  `PUT` never carries them. A stored document never holds them. The open read
  then cannot leak what was never stored.
- `AppConfig.fromJson` still reads the codes when a document has them, so the
  bundled asset keeps the offline mock's staff and owner gate working. The codes
  are asset/local, not wire data.
- The GET redaction from ADR-0067 stays, as defence in depth for any document
  already stored with codes before this change.

## Consequences

- Secrets never travel on a config write and never persist in the config document,
  so the class of "config read leaks a code" bug is closed at the source, not only
  masked at the read. A test asserts the codes are absent from `toJson` and that
  `fromJson` still reads them when present.
- An owner-saved config no longer carries codes, so an online client's overlaid
  config falls back to the default codes. That is fine: the online client verifies
  staff/owner through the backend, not the config codes.
- Real per-venue code provisioning (out of the source, into a store or the POS
  directory) is still the separate SEC-8 item.

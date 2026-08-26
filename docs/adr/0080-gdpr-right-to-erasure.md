# 0080 - GDPR right to erasure

## Status

Accepted. First item of the data-protection track, distinct from the application
security hardening (SEC-1..14).

## Context

qorder handles consumer personal data in the EU: a phone number and a customer
identity, a name on orders, consent choices and a loyalty (redemption) history.
GDPR gives the data subject the right to erasure (Article 17). The app had no way
to erase a person's data. Consent capture existed already, but not deletion.

The data is spread across four stores: identity (global, keyed by customerId),
orders, redemptions and consent (venue-scoped, keyed by the customer's clientId).
A person's records span venues, the same shape `relink` already handles when an
anonymous device signs in.

## Decision

An erase operation on each store, coordinated behind one endpoint.

- Each store gains `eraseCustomer(customerId)`, alongside `relink`:
  - **Identity** deletes the customer and their tokens (global tables), so the
    phone no longer maps to them and their tokens stop authenticating.
  - **Orders** anonymize: null the customer name and the client id, keeping the
    sale record. The venue keeps the transaction (a legitimate business and
    accounting interest) without the PII.
  - **Redemptions** and **consent** are deleted across venues.
  - Postgres uses the cross-venue scope (`__all__`) for the venue-scoped tables,
    the same as `relink`; identity uses the global connection.
- `POST /customers/:id/erase` coordinates the four. It is authorized as the data
  subject (a token matching the customerId) or the platform operator (handling a
  request on their behalf). A wrong token is refused.
- Erasure is idempotent: each store deletes or nulls by key, so re-running it is
  safe. That covers a partial failure across the four stores (a retry completes
  it) without a cross-store transaction.

## Consequences

- A person's data can be erased on request, in the offline demo and on Postgres. A
  test proves the identity, consent and redemptions are gone and the order is kept
  but anonymized. A wrong token cannot erase another customer.
- The order stays as an anonymized record, so the venue's revenue history is
  intact while the PII is gone.
- What remains for the data-protection track: a client-facing "delete my data"
  flow (this is the backend), data retention (auto-pruning old data), plus the
  legal artifacts (privacy policy, processing agreement). Those are separate items.

# 0081 - "Delete my data" flow on the client

## Status

Accepted. The client-facing half of GDPR erasure (ADR-0080 is the backend).

## Context

The backend can erase a customer (ADR-0080), but a person had no way to ask for
it themselves. GDPR's right to erasure is exercised by the data subject, so the
app needs a "delete my data" action a signed-in customer can trigger. It must
clear the device too, not only the server.

## Decision

An `AccountEraser` port with a thin MVVM flow on the account screen.

- **Port.** `AccountEraser.erase(customerId)` in the domain. `RemoteAccountEraser`
  posts to `/customers/:id/erase` with the customer's token; `MockAccountEraser` is
  a no-op, since the offline demo has no server-side data and the local sign-out is
  the whole erasure. A provider picks by `useRemoteBackend`.
- **ViewModel.** `AccountEraseController.delete()` reads the signed-in customerId,
  erases on the backend, then signs the session out (dropping the identity and the
  loyal status) and clears the saved name. So the erase covers the server and the
  device. It returns whether it succeeded, so the View can report.
- **View.** A destructive "delete my data" button on the loyalty card (only when
  signed in) opens a confirm dialog, then calls the controller and shows the
  result. Erasure signs the customer out, so the card falls back to its signed-out
  state.

## Consequences

- A signed-in customer can delete their own data, end to end: the backend erases
  and the device is cleared. A test proves the ViewModel erases through the port,
  signs out and clears the name.
- A failed backend erase is reported and the session is kept, so the user can
  retry (the backend erase is idempotent, ADR-0080).
- What remains on the data-protection track: retention (auto-pruning), data export
  (Article 15) and the legal artifacts.

# ADR-0012: Resilience (durable outbox, idempotency, timeouts)

- Status: Accepted (Phase 0 subset implemented)
- Date: 2026-08-12

## Context (EN)
A submitted order must be neither lost nor duplicated, under bad signal, app
kill, phone reboot, slow/down backend, or stale menu.

## Decision (EN)
- **Durable outbox** behind a `LocalStore` port + `OutboxRepository` (Dependency
  Inversion). A failed submit is persisted, resent automatically on the next
  launch (`resumePending`), never silently dropped.
- **Idempotency**: every order carries a stable idempotency key used as the
  backend's external order id. A resend returns the same result instead of
  creating a second order. Never lost AND never duplicated.
- **Timeouts** on every network call, so the app never hangs.
- Phase 0 storage: `InMemoryLocalStore` (tests) + shared_preferences (device/web,
  durable). Phase 1 swaps in SQLite/Drift (transactions + schema migrations)
  behind the same port, plus an offline menu cache and non-GMS crash reporting.

## Alternatives rejected (EN)
- **In-memory-only outbox**: lost on app kill.
- **Naive non-atomic file write**: a crash mid-write corrupts the queue.
- **No idempotency**: a retry after a lost ack creates a duplicate order.
- **Infinite silent retry**: hides a real failure from the customer.

## Consequences (EN)
- Storage is another backend behind an interface, consistent with the rest.
- Persisted data is scoped by `venueId` (multi-tenant-safe).

---

## Context (RO)
O comandă trimisă nu trebuie nici pierdută, nici dublată, la semnal prost,
aplicație omorâtă, telefon repornit, backend lent sau picat, ori meniu vechi.

## Decizie (RO)
- **Outbox durabil** în spatele unui port `LocalStore` plus `OutboxRepository`
  (Dependency Inversion). Un submit eșuat e salvat, retrimis automat la
  următoarea pornire (`resumePending`), niciodată pierdut în tăcere.
- **Idempotență**: fiecare comandă poartă o cheie stabilă folosită ca id extern
  în backend. O retrimitere întoarce același rezultat, nu creează a doua comandă.
  Niciodată pierdută ȘI niciodată dublată.
- **Timeout** pe fiecare apel de rețea, ca aplicația să nu atârne.
- Stocare Faza 0: `InMemoryLocalStore` (teste) plus shared_preferences (device/web,
  durabil). Faza 1 bagă SQLite/Drift (tranzacții plus migrări de schemă) în
  spatele aceluiași port, plus cache de meniu offline și raportare de crash-uri
  non-GMS.

## Alternative respinse (RO)
- **Outbox doar în memorie**: pierdut la app omorât.
- **Scriere naivă ne-atomică în fișier**: un crash la mijloc corupe coada.
- **Fără idempotență**: o reîncercare după un ack pierdut creează o comandă dublă.
- **Reîncercare infinită în tăcere**: ascunde un eșec real de client.

## Consecințe (RO)
- Stocarea e încă un backend în spatele unei interfețe, consistent cu restul.
- Datele persistate sunt namespace-uite pe `venueId` (sigur pentru multi-tenant).

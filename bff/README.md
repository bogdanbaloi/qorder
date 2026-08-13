# qorder BFF

A thin backend-for-frontend (Dart + shelf). It holds orders and the waiter
acceptance flow, so the customer app and the waiter app share state across
devices (see ADR-0015). It is Ebriza-agnostic: the Ebriza POS adapter slots in
behind the `OrderStore` port later, without changing the apps.

## Run

```bash
cd bff
dart pub get
dart run bin/server.dart        # listens on 127.0.0.1:8080 (PORT to override)
```

## Endpoints

| Method | Path | Purpose |
|--------|------|---------|
| GET  | `/health` | liveness |
| POST | `/venues/<venueId>/orders` | submit an order (idempotent by `idempotencyKey`) |
| GET  | `/venues/<venueId>/orders/pending` | orders awaiting a waiter |
| POST | `/orders/<orderId>/accept` | a waiter accepts an order |
| GET  | `/orders/<orderId>/status` | current order stage |

An order submitted in waiter-confirm mode starts at `pendingAcceptance` and moves
to `received` when a waiter accepts it.

## Test

```bash
dart test
```

## Next

- Persistent `OrderStore` (SQLite/Postgres) behind the same port.
- Live status push (WebSocket/SSE) instead of polling.
- The Ebriza adapter: `Open bill` to inject to the POS, plus live menu/tables.

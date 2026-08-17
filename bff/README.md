# qorder BFF

A thin backend-for-frontend (Dart + shelf). It holds orders, the waiter
acceptance flow, table-to-waiter requests, owner metrics and loyalty
redemptions, so the customer / waiter / owner apps share state across devices
(see ADR-0015). It is Ebriza-agnostic: the Ebriza POS adapter slots in behind
the store ports later, without changing the apps. State is in-memory (a restart
wipes it); a persistent store drops in behind the same ports.

## Run

```bash
cd bff
dart pub get
dart run bin/server.dart        # listens on 127.0.0.1:8080 (PORT to override)
```

For a two-device demo (customer phone + waiter phone), the server must be
reachable on the LAN, so bind all interfaces and point the app at the laptop's
IP:

```bash
HOST=0.0.0.0 dart run bin/server.dart
# then run the app against it:
flutter run --dart-define=QORDER_BFF_URL=http://<laptop-lan-ip>:8080
```

## Endpoints

Orders:

| Method | Path | Purpose |
|--------|------|---------|
| GET  | `/health` | liveness |
| POST | `/venues/<venueId>/orders` | submit an order (idempotent by `idempotencyKey`) |
| GET  | `/venues/<venueId>/orders/pending` | orders awaiting a waiter |
| GET  | `/venues/<venueId>/orders/inprogress` | accepted, not yet delivered |
| GET  | `/venues/<venueId>/tables/<tableNumber>/orders` | a table's orders (shared view) |
| POST | `/orders/<orderId>/accept` | a waiter accepts an order |
| POST | `/orders/<orderId>/ready` | mark the drink ready |
| POST | `/orders/<orderId>/delivered` | mark delivered to the table |
| GET  | `/orders/<orderId>/status` | current order stage |

Table-to-waiter requests:

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/venues/<venueId>/tables/<tableNumber>/requests` | raise a call-waiter / bill request |
| GET  | `/venues/<venueId>/requests` | pending requests |
| POST | `/requests/<requestId>/resolve` | a waiter resolves one |

Owner metrics + loyalty:

| Method | Path | Purpose |
|--------|------|---------|
| GET  | `/venues/<venueId>/metrics` | revenue, averages, daily + hourly series, top products |
| GET  | `/venues/<venueId>/customers/<clientId>/orders` | a customer's order history |
| POST | `/venues/<venueId>/customers/<clientId>/redemptions` | spend points on a reward (returns a code) |
| GET  | `/venues/<venueId>/customers/<clientId>/redemptions` | a customer's redemptions |
| GET  | `/venues/<venueId>/redemptions/pending` | redemptions awaiting staff validation |
| POST | `/redemptions/<code>/consume` | a staff member validates a code |

Identity + consent:

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/auth/otp/start` | start phone sign-in; returns `challengeId` (+ `devCode` until SMS) |
| POST | `/auth/otp/verify` | verify the code; returns `customerId` + `token`; merges the `clientId`'s orders |
| POST | `/venues/<venueId>/customers/<clientId>/consent` | record per-purpose consent |
| GET  | `/venues/<venueId>/customers/<clientId>/consent` | read the customer's consent |

An order submitted in waiter-confirm mode starts at `pendingAcceptance` and moves
to `received` when a waiter accepts it. Stores sit behind ports (`OrderStore`,
`WaiterRequestStore`, `RedemptionStore`), so a persistent or Ebriza-backed
implementation swaps in without touching the routes.

## Test

```bash
dart test
```

## Next

- Persistent `OrderStore` (SQLite/Postgres) behind the same port.
- Live status push (WebSocket/SSE) instead of polling.
- The Ebriza adapter: `Open bill` to inject to the POS, plus live menu/tables.

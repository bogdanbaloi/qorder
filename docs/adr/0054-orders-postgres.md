# ADR-0054: Orders on Postgres with a per-venue sequence

- Status: Accepted
- Date: 2026-08-20

## Context (EN)
ADR-0053 set the pattern for multi-tenant Postgres persistence and migrated
consent first. Orders are the core data. Losing them on a restart is the worst
case, so they are the next store to migrate. Orders also carry decisions consent
did not: a display sequence, a lifecycle with mutable stages and idempotent
submit.

## Decision (EN)
- **`OrderStore` becomes async.** Every method returns a `Future`, so a
  Postgres-backed store fits behind the port. `PostgresOrderStore` implements it.
  The callers in `order_api.dart` and the in-memory tests gained `await`. This is
  a one-time contract change.
- **Per-venue sequence.** Each venue numbers its orders from 1. An atomic counter
  row (`venue_order_counters`, upserted with `last_seq + 1`) hands out the next
  number, so concurrent submits at one venue never collide.
- **Globally unique id.** `server_order_id` is `BFF-<venue>-<seq>`. The pair
  (venue, seq) is unique, so the id is globally unique even though the sequence
  restarts per venue.
- **Idempotency is per venue.** A unique index on (venue_id, idempotency_key)
  means the same client key at two venues is two orders. A resend at one venue
  returns the first order.
- **Lifecycle as updates.** `accept`, `markReady` and `markDelivered` update the
  row and stamp the event. A stamp uses `jsonb_build_object(event, now) || stamps`
  so an existing stamp is kept (putIfAbsent), because the right operand wins on a
  key clash.
- **Tenant-scoped, identity global.** Every order read filters on `venue_id`.
  `relink` re-keys a customer's orders by `client_id` across venues, which is
  correct because identity is global.

## Alternatives rejected (EN)
- **A global sequence for the id.** Simpler, but a venue wants to see its own
  order numbers from 1. A per-venue counter gives that without losing global
  uniqueness.
- **`MAX(sequence) + 1` per submit.** Races under concurrency. The counter row is
  atomic in the transaction.
- **Keep the store synchronous with a blocking driver.** Dart Postgres is async.
  The port change is the honest fit and matches every other store to come.

## Consequences (EN)
- Orders survive a restart and are tenant-isolated, proven by a cross-tenant test
  and a full lifecycle test. The in-memory store stays for dev and tests with no
  database.
- The remaining stores (redemptions, identity, waiter requests) migrate next on
  this pattern, then RLS lands as DB-level defence in depth.
- The client contract is unchanged. The app already talks to the BFF over async
  ports, so nothing on the UI side moves.

---

## Context (RO)
ADR-0053 a stabilit tiparul persistenței Postgres multi-tenant. A migrat întâi
consimțământul. Comenzile sunt datele de bază. Să le pierzi la restart e cel mai
rău caz, deci ele sunt următorul store de migrat. Comenzile poartă și decizii pe
care consimțământul nu le avea: o secvență de afișare, un ciclu de viață cu stări
mutabile, un submit idempotent.

## Decizie (RO)
- **`OrderStore` devine async.** Fiecare metodă întoarce un `Future`, deci un
  store pe Postgres intră în spatele portului. `PostgresOrderStore` îl
  implementează. Apelanții din `order_api.dart` plus testele in-memory au primit
  `await`. E o schimbare de contract făcută o singură dată.
- **Secvență per local.** Fiecare local își numără comenzile de la 1. Un rând de
  contor atomic (`venue_order_counters`, upsert cu `last_seq + 1`) dă numărul
  următor, deci submit-uri concurente la un local nu se ciocnesc.
- **Id unic global.** `server_order_id` e `BFF-<local>-<seq>`. Perechea (local,
  seq) e unică, deci id-ul e unic global chiar dacă secvența repornește pe local.
- **Idempotență per local.** Un index unic pe (venue_id, idempotency_key) face ca
  aceeași cheie de client la două localuri să fie două comenzi. Un resend la un
  local întoarce prima comandă.
- **Ciclu de viață ca update-uri.** `accept`, `markReady` plus `markDelivered`
  actualizează rândul și ștampilează evenimentul. O ștampilă folosește
  `jsonb_build_object(event, now) || stamps`, deci o ștampilă existentă e păstrată
  (putIfAbsent), fiindcă operandul din dreapta câștigă la o coliziune de cheie.
- **Scoped pe tenant, identitate globală.** Fiecare citire de comandă filtrează pe
  `venue_id`. `relink` re-cheiază comenzile unui client după `client_id` peste
  localuri, ceea ce e corect fiindcă identitatea e globală.

## Alternative respinse (RO)
- **O secvență globală pentru id.** Mai simplu, dar un local vrea să-și vadă
  numerele de comandă de la 1. Un contor per-local dă asta fără să piardă
  unicitatea globală.
- **`MAX(sequence) + 1` la fiecare submit.** Curse sub concurență. Rândul de
  contor e atomic în tranzacție.
- **Păstrarea store-ului sincron cu un driver blocant.** Postgres pe Dart e async.
  Schimbarea portului e potrivirea cinstită și se aliniază cu fiecare store viitor.

## Consecințe (RO)
- Comenzile supraviețuiesc unui restart și sunt izolate pe tenant, dovedit de un
  test cross-tenant plus un test de ciclu de viață complet. Store-ul in-memory
  rămâne pentru dev și teste fără bază de date.
- Store-urile rămase (revendicări, identitate, cereri de ospătar) migrează pe acest
  tipar. Apoi RLS aterizează ca apărare la nivel de DB.
- Contractul cu clientul e neschimbat. Aplicația vorbește deja cu BFF-ul prin
  porturi async, deci nimic pe partea de UI nu se mișcă.

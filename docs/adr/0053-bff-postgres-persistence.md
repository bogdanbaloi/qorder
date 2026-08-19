# ADR-0053: BFF persistence on multi-tenant Postgres (consent first)

- Status: Accepted
- Date: 2026-08-20

## Context (EN)
The BFF kept every store in memory, so a restart lost all data (orders, identity,
consent, redemptions). To run qorder as a multi-tenant product for many venues,
the data must be durable and tenant-scoped. The store ports already take `venueId`
on every tenant-scoped method, so multi-tenancy is a data-modelling concern, not a
new abstraction.

## Decision (EN)
- **Postgres, managed in production.** Chosen over SQLite for the many-venue
  ambition: real write concurrency, multiple BFF instances sharing one database,
  and Row-Level Security as a later DB-level tenant guard. Local dev and CI use a
  Docker Postgres (`bff/docker-compose.yml`); production uses a managed Postgres
  (Neon / Supabase) through the same `QORDER_DATABASE_URL`, so only the host
  changes.
- **Row-level tenancy.** Every tenant table carries `venue_id` and every query
  filters on it; the ports mandate `venueId`, so the filter cannot be forgotten.
  Identity (phone -> customer -> token) stays GLOBAL by design: a person is the
  same at any venue, and their per-venue data links by `customer_id + venue_id`.
- **Consent migrated first, as the pattern.** `ConsentStore` becomes async (so a
  DB-backed store fits behind it); `PostgresConsentStore` implements it, scoped by
  venue. `server.dart` uses it when `QORDER_DATABASE_URL` is set and falls back to
  the in-memory store otherwise (dev/tests with no DB). A migration runner applies
  the SQL files; the deployment BFF URL is unrelated and stays a `--dart-define`.
- **Tenant isolation is tested.** A cross-tenant test proves one venue never reads
  another's rows. CI runs a Postgres service so the test runs for real, not
  skipped.

## Alternatives rejected (EN)
- **SQLite.** Enough for pub-scale traffic, but single-machine / single-writer and
  no DB-level tenant isolation. The 100+ venue ambition and a possible multi-
  instance BFF argue for Postgres now, avoiding a later migration.
- **Schema-per-tenant or database-per-tenant.** Stronger isolation, but migrations
  and connection management per venue are operational overhead we do not need at
  this scale. Row-level tenancy fits many small venues.
- **Migrate every store to async at once.** A large, risky change. Each store
  migrates behind its own port independently; consent is the first, proving the
  pattern.
- **Row-Level Security in this slice.** Valuable defence in depth, but it needs a
  non-superuser role and per-transaction session settings. The store layer already
  enforces tenant scoping (and a test proves it); RLS is the next hardening slice.

## Consequences (EN)
- Consent now survives a restart and is tenant-isolated; the other stores (orders,
  redemptions, identity, staff-auth) migrate next on the same pattern, unlocking
  operator evidence (venues + users per venue) that needs durable data.
- CI gained a Postgres service for the BFF job.
- Follow-ups: RLS for DB-level isolation; migrate the remaining stores; a versioned
  migration ledger; the managed Postgres is provisioned by the owner (credentials
  via env, never in the repo).

---

## Context (RO)
BFF-ul ținea fiecare store în memorie, deci un restart pierdea toate datele
(comenzi, identitate, consimțământ, revendicări). Ca să rulăm qorder ca produs
multi-tenant pentru multe localuri, datele trebuie să fie durabile și scoped pe
tenant. Porturile de store primesc deja `venueId` la fiecare metodă de tenant,
deci multi-tenancy-ul e o chestiune de modelare a datelor, nu o abstracție nouă.

## Decizie (RO)
- **Postgres, managed în producție.** Ales în locul SQLite pentru ambiția de multe
  localuri: concurență reală la scriere, mai multe instanțe BFF pe aceeași bază, și
  Row-Level Security ca gardă de tenant la nivel de DB mai târziu. Dev-ul local și
  CI folosesc un Postgres în Docker (`bff/docker-compose.yml`); producția folosește
  un Postgres managed (Neon / Supabase) prin același `QORDER_DATABASE_URL`, deci se
  schimbă doar hostul.
- **Tenancy pe rând (row-level).** Fiecare tabel de tenant are `venue_id` și fiecare
  query filtrează pe el; porturile cer `venueId`, deci filtrul nu poate fi uitat.
  Identitatea (telefon -> client -> token) rămâne GLOBALĂ prin design: o persoană e
  aceeași la orice local, iar datele ei per-local se leagă prin
  `customer_id + venue_id`.
- **Consimțământul migrat primul, ca tipar.** `ConsentStore` devine async (ca un
  store cu DB să intre în spatele lui); `PostgresConsentStore` îl implementează,
  scoped pe local. `server.dart` îl folosește când `QORDER_DATABASE_URL` e setat și
  cade pe store-ul in-memory altfel (dev/teste fără DB). Un runner de migrări aplică
  fișierele SQL; URL-ul de BFF e nelegat și rămâne un `--dart-define`.
- **Izolarea de tenant e testată.** Un test cross-tenant dovedește că un local nu
  citește niciodată rândurile altuia. CI rulează un service Postgres, deci testul
  rulează real, nu skip.

## Alternative respinse (RO)
- **SQLite.** Destul pentru traficul de cârciumă, dar o singură mașină / un singur
  writer și fără izolare de tenant la nivel de DB. Ambiția de 100+ localuri și un
  posibil BFF multi-instanță argumentează Postgres acum, evitând o migrare.
- **Schemă-per-tenant sau bază-per-tenant.** Izolare mai tare, dar migrările și
  managementul conexiunilor per local sunt overhead de ops de care n-avem nevoie la
  scala asta. Tenancy-ul pe rând se potrivește la multe localuri mici.
- **Migrarea tuturor store-urilor la async deodată.** Schimbare mare și riscantă.
  Fiecare store migrează în spatele portului lui, independent; consimțământul e
  primul, ca dovadă a tiparului.
- **Row-Level Security în felia asta.** Apărare-în-adâncime valoroasă, dar cere un
  rol non-superuser și setări de sesiune per tranzacție. Stratul de store impune
  deja scoping-ul de tenant (și un test o dovedește); RLS e felia de hardening
  următoare.

## Consecințe (RO)
- Consimțământul supraviețuiește acum unui restart și e izolat pe tenant; celelalte
  store-uri (comenzi, revendicări, identitate, staff-auth) migrează pe același tipar,
  deblocând evidența de operator (localuri + utilizatori/local) care are nevoie de
  date durabile.
- CI a primit un service Postgres pentru job-ul BFF.
- De urmat: RLS pentru izolare la nivel de DB; migrarea store-urilor rămase; un
  ledger de migrări versionat; Postgres-ul managed e provizionat de owner
  (credențiale prin env, niciodată în repo).

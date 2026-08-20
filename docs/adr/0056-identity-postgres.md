# ADR-0056: Identity on Postgres (global, not tenant-scoped)

- Status: Accepted
- Date: 2026-08-20

## Context (EN)
Identity is the last store to move onto Postgres. It is different from the others:
it is GLOBAL, not tenant-scoped. A person is the same at any venue, so the phone
identifies the human, not the human-at-a-venue. The per-venue data (consent,
orders, redemptions) links to this global customer by customer_id.

## Decision (EN)
- **Global tables, no venue_id.** `customers` (one row per phone), `auth_tokens`
  (token to customer), `otp_challenges` (pending verifications), `otp_starts`
  (rate-limit record). None carries a venue_id, because identity is shared across
  venues.
- **`IdentityStore` becomes async.** `PostgresIdentityStore` implements it. The
  port change ripples to the `_authorized` guard, which awaits `isKnownCustomer`
  and `customerForToken`, so every customer-scoped handler now awaits it too.
- **Get-or-create the customer by phone.** Verify upserts the customer (customer_id
  is `cust:<phone>`) and issues a fresh token on each sign-in. The same phone
  always maps to the same customer.
- **Rate limiting is persisted.** A challenge is deleted on verify (single-use),
  so it cannot be the rate-limit record. `otp_starts` keeps one row per start, and
  the limiter counts recent starts per phone (5 per 10 minutes).
- **No cross-tenant test here.** Identity is intentionally shared, so there is
  nothing to isolate. The correctness tests are: same phone maps to the same
  customer, a token maps to its customer, wrong or expired or reused codes fail,
  and the rate limit holds.

## Alternatives rejected (EN)
- **Scope identity by venue.** Wrong: the same phone at two venues would become two
  accounts, forcing a re-registration per venue and fragmenting loyalty. A person
  is one identity everywhere.
- **Count otp_challenges for rate limiting.** A challenge is deleted on verify, so
  the count would undercount. A dedicated otp_starts table is the honest record.
- **Apply RLS to identity later.** Identity is global, so scoping it by venue would
  be wrong. RLS lands on the tenant tables only.

## Consequences (EN)
- Every store now persists to Postgres. Identity survives a restart. The merge
  (relinking anonymous orders and redemptions to the customer) works across venues
  because identity is global.
- The persistence track is complete. Next is RLS across the tenant tables, then
  operator evidence (venues plus users per venue), which now has durable data.
- Follow-up: tokens have no expiry yet (a TTL or rotation is a later slice).

---

## Context (RO)
Identitatea e ultimul store mutat pe Postgres. E diferit de celelalte: e GLOBAL,
nu scoped pe tenant. O persoană e aceeași la orice local, deci telefonul
identifică omul, nu omul-la-un-local. Datele per-local (consimțământ, comenzi,
revendicări) se leagă de acest client global prin customer_id.

## Decizie (RO)
- **Tabele globale, fără venue_id.** `customers` (un rând per telefon),
  `auth_tokens` (token spre client), `otp_challenges` (verificări în așteptare),
  `otp_starts` (înregistrarea pentru rate-limit). Niciunul nu poartă venue_id,
  fiindcă identitatea e comună între localuri.
- **`IdentityStore` devine async.** `PostgresIdentityStore` îl implementează.
  Schimbarea portului se propagă la guard-ul `_authorized`, care așteaptă
  `isKnownCustomer` plus `customerForToken`, deci fiecare handler cu scop de client
  îl așteaptă acum.
- **Get-or-create clientul după telefon.** Verify face upsert la client (customer_id
  e `cust:<telefon>`) și emite un token proaspăt la fiecare logare. Același telefon
  duce mereu la același client.
- **Rate-limiting persistat.** O provocare e ștearsă la verify (single-use), deci nu
  poate fi înregistrarea de rate-limit. `otp_starts` ține un rând per start, iar
  limitatorul numără starturile recente per telefon (5 la 10 minute).
- **Fără test cross-tenant aici.** Identitatea e intenționat comună, deci nu e nimic
  de izolat. Testele de corectitudine sunt: același telefon duce la același client,
  un token duce la clientul lui, coduri greșite ori expirate ori refolosite pică,
  iar rate-limitul ține.

## Alternative respinse (RO)
- **Scoparea identității pe local.** Greșit: același telefon la două localuri ar
  deveni două conturi, forțând o reînregistrare per local și fragmentând
  loialitatea. O persoană e o singură identitate peste tot.
- **Numărarea otp_challenges pentru rate-limit.** O provocare e ștearsă la verify,
  deci numărul ar fi prea mic. Un tabel dedicat otp_starts e înregistrarea cinstită.
- **Aplicarea RLS pe identitate mai târziu.** Identitatea e globală, deci scoparea ei
  pe local ar fi greșită. RLS aterizează doar pe tabelele de tenant.

## Consecințe (RO)
- Fiecare store persistă acum în Postgres. Identitatea supraviețuiește unui restart,
  iar merge-ul (re-cheierea comenzilor și revendicărilor anonime spre client)
  funcționează peste localuri, fiindcă identitatea e globală.
- Track-ul de persistență e complet. Urmează RLS peste tabelele de tenant, apoi
  evidența de operator (localuri plus utilizatori per local), care are acum date
  durabile.
- De urmat: token-urile nu au încă expirare (un TTL sau rotație e o felie viitoare).

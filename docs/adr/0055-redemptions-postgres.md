# ADR-0055: Redemptions on Postgres

- Status: Accepted
- Date: 2026-08-20

## Context (EN)
Redemptions are the third store to move onto the multi-tenant Postgres pattern
from ADR-0053. Spending loyalty points is not an order. It never touches the POS.
The store carries a customer code the staff validate.

## Decision (EN)
- **`RedemptionStore` becomes async.** `PostgresRedemptionStore` implements it,
  scoped by venue_id. The callers gained `await`.
- **The id is a random uuid.** A redemption id is internal. Only the short human
  code is shown, so a per-venue sequence is not needed for the id.
- **A `seq` column gives stable order.** A `bigserial` orders newest-first and
  oldest-first reliably, so two redemptions in the same millisecond never reorder.
- **Consume looks up the code globally.** The staff type a code without a venue.
  Consume validates exactly one pending redemption with that code, the oldest.
- **Tenant-scoped, identity global.** Every read filters on venue_id. `relink`
  re-keys by client_id across venues, which is correct because identity is global.

## Alternatives rejected (EN)
- **A per-venue sequence for the id, as orders use.** Orders show their number to
  the customer. A redemption id is never shown, so a uuid is simpler.
- **Order by `created_at_ms`.** Two redemptions can share a millisecond, so the
  order would be unstable. The `seq` column is monotonic.

## Consequences (EN)
- Redemptions survive a restart and are tenant-isolated, proven by a cross-tenant
  test. The in-memory store stays for dev with no database.
- Identity is the last store to migrate, then RLS lands across every tenant table.

---

## Context (RO)
Revendicările sunt al treilea store mutat pe tiparul Postgres multi-tenant din
ADR-0053. Cheltuirea punctelor de loialitate nu e o comandă. Nu atinge niciodată
POS-ul. Store-ul poartă un cod de client pe care personalul îl validează.

## Decizie (RO)
- **`RedemptionStore` devine async.** `PostgresRedemptionStore` îl implementează,
  scoped pe venue_id. Apelanții au primit `await`.
- **Id-ul e un uuid aleator.** Id-ul unei revendicări e intern. Doar codul scurt e
  arătat, deci nu e nevoie de o secvență per local pentru id.
- **O coloană `seq` dă ordine stabilă.** Un `bigserial` ordonează cel-mai-nou și
  cel-mai-vechi sigur, deci două revendicări din aceeași milisecundă nu se
  reordonează.
- **Consume caută codul global.** Personalul tastează un cod fără local. Consume
  validează exact o revendicare în așteptare cu acel cod, cea mai veche.
- **Scoped pe tenant, identitate globală.** Fiecare citire filtrează pe venue_id.
  `relink` re-cheiază după client_id peste localuri, ceea ce e corect fiindcă
  identitatea e globală.

## Alternative respinse (RO)
- **O secvență per local pentru id, ca la comenzi.** Comenzile își arată numărul
  clientului. Un id de revendicare nu e arătat niciodată, deci un uuid e mai
  simplu.
- **Ordonare după `created_at_ms`.** Două revendicări pot împărți o milisecundă,
  deci ordinea ar fi instabilă. Coloana `seq` e monotonă.

## Consecințe (RO)
- Revendicările supraviețuiesc unui restart și sunt izolate pe tenant, dovedit de
  un test cross-tenant. Store-ul in-memory rămâne pentru dev fără bază de date.
- Identitatea e ultimul store de migrat. Apoi RLS aterizează peste fiecare tabel de
  tenant.

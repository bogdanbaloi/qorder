# ADR-0048: Per-tenant staff/owner authorization (server-issued token)

- Status: Accepted
- Date: 2026-08-18

## Context (EN)
The staff and owner surfaces were gated only on the client: `RoleGuard` compared
the entered code to `AppConfig`'s code and flipped the session role. The BFF never
checked, so anyone could call the staff/owner endpoints (accept, ready, delivered,
pending, requests, resolve, redemptions/pending, consume, metrics) directly with a
venueId. This moves the gate onto the same server-issued token seam as the
customer identity, keeping it POS-agnostic.

## Decision (EN)
- **Server issues a scoped token.** `POST /venues/:id/staff/auth {role, code}`
  verifies the venue's code for the role (a `StaffAuthStore` holds per-venue
  codes) and returns a token scoped to (venue, role). Wrong code -> 401.
- **Staff/owner routes require a matching token.** A `_staffOk` guard reads the
  bearer token's claims: venue-scoped routes (pending, inprogress, requests,
  redemptions/pending) require a staff-or-owner token for that venue; metrics
  requires the **owner** role; id-based mutations (accept, ready, delivered,
  resolve, consume) require a valid staff/owner token. Per-tenant: a staff at one
  venue cannot read another's board.
- **Client on the same seam.** A `StaffAuthService` port: `RemoteStaffAuthService`
  (BFF) vs `MockStaffAuthService` (checks the config code locally, no backend).
  The gate exchanges the code for a token and stores it on the `Session`
  (`staffToken`). `Session.token` unifies the customer and staff token; the remote
  sources (`RemoteBackend`, `RemoteMetricsSource`, redemption board) send it,
  wired from `sessionTokenProvider`.

## Alternatives rejected (EN)
- **Keep client-only code checking.** No real protection: the BFF was open.
- **Per-entity venue match on every mutation.** Stronger, but needs venue lookups
  on three stores; the read routes are venue-scoped and enforced, so a staff can
  only discover their own venue's ids -> a valid-staff-token check on mutations is
  enough for this slice (per-entity match noted as a follow-up).
- **A separate staff token vs the customer token field.** A session is one role at
  a time, so one `Session.token` getter covers both and keeps the wiring simple.

## Consequences (EN)
- The staff/owner surfaces are now enforced server-side and per-tenant; the mock
  keeps the local code check so the in-app demo and tests are unchanged.
- The BFF holds per-venue codes (demo mirrors `AppConfig`); a real deploy loads
  them per venue or from the POS user directory (Ebriza users) behind the same
  `StaffAuthStore`.
- Follow-ups: per-entity venue match on mutations, and replacing codes with a real
  staff directory.

---

## Context (RO)
Suprafețele de staff și patron erau gated doar pe client: `RoleGuard` compara codul
introdus cu cel din `AppConfig` și schimba rolul sesiunii. BFF-ul nu verifica
nimic, deci oricine putea apela direct rutele de staff/patron (accept, ready,
delivered, pending, requests, resolve, redemptions/pending, metrics) cu un venueId.
Asta mută poarta pe același seam de token emis de server ca identitatea clientului,
rămânând POS-agnostic.

## Decizie (RO)
- **Serverul emite un token scoped.** `POST /venues/:id/staff/auth {role, code}`
  verifică codul venue-ului pentru rol (un `StaffAuthStore` ține codurile
  per-venue) și întoarce un token scoped pe (venue, rol). Cod greșit -> 401.
- **Rutele de staff/patron cer un token care se potrivește.** Un guard `_staffOk`
  citește claim-urile token-ului: rutele venue-scoped (pending, inprogress,
  requests, redemptions/pending) cer un token staff-sau-owner pentru acel venue;
  metrics cere rolul **owner**; mutațiile pe id (accept, ready, delivered, resolve,
  consume) cer un token staff/owner valid. Per-tenant: un staff de la un local nu
  poate citi board-ul altuia.
- **Client pe același seam.** Un port `StaffAuthService`: `RemoteStaffAuthService`
  (BFF) vs `MockStaffAuthService` (verifică codul din config local, fără backend).
  Poarta schimbă codul pe token și îl ține pe `Session` (`staffToken`).
  `Session.token` unifică token-ul de client și de staff; sursele remote
  (`RemoteBackend`, `RemoteMetricsSource`, board-ul de revendicări) îl trimit,
  cablat din `sessionTokenProvider`.

## Alternative respinse (RO)
- **Păstrarea verificării doar pe client.** Fără protecție reală: BFF-ul era
  deschis.
- **Potrivire de venue per-entitate la fiecare mutație.** Mai tare, dar cere
  căutări de venue pe trei store-uri; rutele de citire sunt venue-scoped și impuse,
  deci un staff poate descoperi doar id-urile venue-ului lui -> un check de
  token-staff-valid pe mutații ajunge pentru felia asta (potrivirea per-entitate
  notată ca follow-up).
- **Un câmp de token de staff separat de cel de client.** O sesiune e un singur rol
  la un moment dat, deci un getter `Session.token` acoperă ambele și ține cablajul
  simplu.

## Consecințe (RO)
- Suprafețele de staff/patron sunt acum impuse pe server și per-tenant; mockul
  păstrează verificarea locală a codului, deci demo-ul in-app și testele-s
  neschimbate.
- BFF-ul ține coduri per-venue (demo-ul oglindește `AppConfig`); un deploy real le
  încarcă per venue sau din directorul de useri al POS-ului (useri Ebriza) în
  spatele aceluiași `StaffAuthStore`.
- De urmat: potrivire de venue per-entitate pe mutații, și înlocuirea codurilor cu
  un director real de staff.

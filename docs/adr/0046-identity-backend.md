# ADR-0046: Customer identity backend — OTP, token, cross-device merge (slice 2)

- Status: Accepted
- Date: 2026-08-17

## Context (EN)
ADR-0045 built the client identity seam on a mock. Slice 2 makes it real on the
BFF, still POS-agnostic and without a real SMS provider or Ebriza (both external,
not yet available). The point that must actually work now is portability: a
customer who ordered anonymously, then signs in, keeps their orders and points.

## Decision (EN)
- **OTP on the BFF, dev sender.** An `IdentityStore` port issues a challenge for a
  phone (five-minute, single-use code) and verifies it. With no SMS yet, the code
  is returned in the `POST /auth/otp/start` response as `devCode` (a dev shortcut,
  clearly flagged; a real SMS adapter omits it and texts the code). `verify`
  returns a `customerId` (created once per phone, reused) and a `token`.
- **Cross-device merge.** `verify` accepts the caller's anonymous `clientId`; the
  BFF `relink`s that client's orders and redemptions to the `customerId`, so
  pre-sign-in data follows the customer. Orders/redemptions gained a mutable
  `clientId` and a `relink` on their stores.
- **Consent persisted per venue.** A `ConsentStore` port keeps each customer's
  per-purpose consent per venue (the venue is the data controller). Routes:
  `POST`/`GET /venues/:id/customers/:cid/consent`.
- **Client adapters behind the same ports.** `RemoteIdentityService` and
  `RemoteConsentSource` implement the existing ports; the composition root selects
  mock vs remote by `useRemoteBackend`. `startSignIn` now returns a
  `SignInChallenge` (challengeId + optional `devHint`), so the sign-in screen shows
  the dev code per environment instead of a hard-coded hint.
- **POS-agnostic.** qorder owns identity end to end. A POS (Ebriza) adapter would
  map a verified phone to its own client behind the same `IdentityStore`/service
  seam; it never becomes a dependency.

## Alternatives rejected (EN)
- **JWT tokens now.** An opaque server-stored token is enough for the in-memory
  BFF and simpler; JWT can replace it behind `customerForToken` without client
  change.
- **Merge by keeping a clientId→customerId alias table.** Rewriting the records'
  `clientId` is simpler to reason about and makes `forCustomer(customerId)` work
  with no alias lookups.
- **Return no code / require reading server logs for the OTP.** Unusable for a
  cross-device demo; the flagged `devCode` is the honest dev shortcut until SMS.
- **Enforce tokens on every request now.** That is slice 3 (authorization); slice
  2 issues and stores tokens so slice 3 can enforce.

## Consequences (EN)
- Sign-in, merge and consent now work against the real BFF; the mock still drives
  tests and the SMS-less local demo.
- The `devCode` in the start response is a dev-only shortcut and must be removed
  when a real SMS adapter lands (documented).
- Per-request authorization and real SMS are slice 3; the Ebriza adapter is a
  separate, later slice gated on API access.

---

## Context (RO)
ADR-0045 a construit seam-ul de identitate pe client, pe mock. Felia 2 îl face real
pe BFF, tot POS-agnostic și fără un provider SMS real sau Ebriza (ambele externe,
încă indisponibile). Ce trebuie să meargă efectiv acum e portabilitatea: un client
care a comandat anonim, apoi se autentifică, își păstrează comenzile și punctele.

## Decizie (RO)
- **OTP pe BFF, dev sender.** Un port `IdentityStore` emite un challenge pentru un
  telefon (cod de 5 minute, unică folosință) și îl verifică. Fără SMS încă, codul
  vine în răspunsul `POST /auth/otp/start` ca `devCode` (scurtătură de dev, marcată
  clar; un adaptor SMS real îl omite și trimite codul prin SMS). `verify` întoarce
  un `customerId` (creat o dată per telefon, reutilizat) și un `token`.
- **Merge cross-device.** `verify` acceptă `clientId`-ul anonim al apelantului;
  BFF-ul face `relink` la comenzile și revendicările acelui client către
  `customerId`, deci datele de dinainte de sign-in urmează clientul.
  Comenzile/revendicările au primit un `clientId` mutabil și un `relink` pe store.
- **Consimțământ persistat per local.** Un port `ConsentStore` ține consimțământul
  per scop, per local (localul e data controller). Rute:
  `POST`/`GET /venues/:id/customers/:cid/consent`.
- **Adaptoare client în spatele acelorași porturi.** `RemoteIdentityService` și
  `RemoteConsentSource` implementează porturile existente; rădăcina de compoziție
  alege mock vs remote după `useRemoteBackend`. `startSignIn` întoarce acum un
  `SignInChallenge` (challengeId + `devHint` opțional), deci ecranul arată codul de
  dev pe mediu, nu un hint hardcodat.
- **POS-agnostic.** qorder deține identitatea cap-coadă. Un adaptor de POS (Ebriza)
  ar mapa un telefon dovedit la clientul lui în spatele aceluiași seam; nu devine
  niciodată o dependență.

## Alternative respinse (RO)
- **Token-uri JWT acum.** Un token opac stocat pe server e destul pentru BFF-ul
  in-memory și mai simplu; JWT îl poate înlocui în spatele `customerForToken` fără
  schimbare pe client.
- **Merge prin tabel de alias clientId→customerId.** Rescrierea `clientId`-ului pe
  înregistrări e mai ușor de urmărit și face `forCustomer(customerId)` să meargă
  fără căutări de alias.
- **Fără cod în răspuns / citit din log-uri.** Inutilizabil pentru un demo
  cross-device; `devCode` marcat e scurtătura onestă până la SMS.
- **Enforcement pe fiecare cerere acum.** E felia 3 (autorizare); felia 2 emite și
  stochează token-uri ca felia 3 să poată impune.

## Consecințe (RO)
- Sign-in-ul, merge-ul și consimțământul merg acum pe BFF-ul real; mockul mișcă
  testele și demo-ul local fără SMS.
- `devCode` din răspuns e o scurtătură de dev și trebuie scoasă când intră un
  adaptor SMS real (documentat).
- Autorizarea pe fiecare cerere și SMS-ul real sunt felia 3; adaptorul Ebriza e o
  felie separată, ulterioară, condiționată de access la API.

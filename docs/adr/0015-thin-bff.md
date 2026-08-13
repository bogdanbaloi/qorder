# ADR-0015: The thin BFF, Ebriza-agnostic first

- Status: Accepted (walking skeleton in `bff/`)
- Date: 2026-08-13

## Context (EN)
The waiter-confirmation flow needs the customer app and the waiter app to share
state across DEVICES (a customer phone, a waiter phone). The Phase-0 mock is
in-memory per app instance, so it only syncs within one browser (a localStorage
stopgap). Two real phones need a shared server. Ebriza access is not available
yet, but the shared-state need is separable: only POS injection and the live
menu/tables come from Ebriza, not the order flow itself.

## Decision (EN)
Build a **thin BFF** (our own small server) that holds orders and the acceptance
flow, **Ebriza-agnostic first**. The apps talk to it over a JSON REST contract
via `RemoteOrderingService` / `RemoteOrderAcceptanceService` implementing the
existing interfaces, so switching from the mock is a one-line change in the
composition root. The BFF keeps orders behind an `OrderStore` port (in-memory
now, persistent later). The **Ebriza adapter** (`Open bill` to inject to the POS,
plus live menu/tables) slots in behind the store later, without changing the
apps. Tech: **Dart + shelf**, so the stack is one language and the JSON contract
is shared, with no extra runtime.

## Alternatives rejected (EN)
- **Firebase / Supabase as the shared store**: ADR-0005 rejected Firebase (GMS,
  Huawei). A managed backend-as-a-service also owns data we want in Ebriza.
- **Wait for Ebriza before any backend**: blocks the real two-device flow on an
  external dependency that is not ready. The shared-state need is separable.
- **Node / .NET BFF**: viable (Ebriza ships client libraries for them), but Dart
  reuses the domain shapes and keeps one language. We call Ebriza's REST API
  directly from Dart later, no client library needed.

## Consequences (EN)
- The two-device flow works WITHOUT Ebriza. Ebriza becomes an `OrderStore`
  implementation (or an adapter the store calls), added when access lands.
- One more small component to host, consistent with ADR-0009 (secrets live in
  the BFF, never in the app).
- The localStorage cross-tab stopgap is retired once the app points at the BFF.

---

## Context (RO)
Fluxul de confirmare la ospăptar cere ca aplicația clientului și cea a
ospăptarului să împartă starea între DISPOZITIVE (telefon client, telefon
ospăptar). Mock-ul din Faza 0 e în memorie per instanță, deci se sincronizează
doar într-un singur browser (un stopgap pe localStorage). Două telefoane reale
au nevoie de un server partajat. Accesul la Ebriza nu e încă disponibil, dar
nevoia de stare partajată e separabilă: doar injectarea în POS și meniul/mesele
live vin din Ebriza, nu fluxul comenzii în sine.

## Decizie (RO)
Construim un **BFF subțire** (serverul nostru mic) care ține comenzile și fluxul
de acceptare, **fără Ebriza la început**. Aplicațiile vorbesc cu el printr-un
contract REST JSON, prin `RemoteOrderingService` / `RemoteOrderAcceptanceService`
care implementează interfețele existente, deci trecerea de la mock e o schimbare
de o linie în rădăcina de compoziție. BFF-ul ține comenzile în spatele unui port
`OrderStore` (în memorie acum, persistent mai târziu). **Adaptorul Ebriza**
(`Open bill` ca să injecteze în POS, plus meniu/mese live) intră în spatele
store-ului mai târziu, fără să schimbe aplicațiile. Tehnologie: **Dart + shelf**,
deci stack-ul e un singur limbaj și contractul JSON e comun, fără runtime în
plus.

## Alternative respinse (RO)
- **Firebase / Supabase ca store partajat**: ADR-0005 a respins Firebase (GMS,
  Huawei). Un backend-as-a-service gestionat deține și date pe care le vrem în
  Ebriza.
- **Așteptăm Ebriza înainte de orice backend**: blochează fluxul real pe două
  dispozitive de o dependență externă care nu e gata. Nevoia de stare partajată
  e separabilă.
- **BFF în Node / .NET**: viabil (Ebriza are librării client pentru ele), dar
  Dart refolosește formele de domeniu și ține un singur limbaj. Chemăm API-ul
  REST Ebriza direct din Dart mai târziu, fără librărie client.

## Consecințe (RO)
- Fluxul pe două dispozitive merge FĂRĂ Ebriza. Ebriza devine o implementare de
  `OrderStore` (sau un adaptor pe care store-ul îl cheamă), adăugată când vine
  accesul.
- Încă o componentă mică de găzduit, consistent cu ADR-0009 (secretele stau în
  BFF, niciodată în aplicație).
- Stopgap-ul cross-tab pe localStorage se retrage odată ce aplicația arată spre
  BFF.

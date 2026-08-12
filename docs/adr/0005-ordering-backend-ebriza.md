# ADR-0005: Ordering backend = Ebriza POS via a thin BFF

- Status: Accepted
- Date: 2026-08-12

## Context (EN)
The venue already runs the **Ebriza** POS on an iPad (tables, orders, payment).
Ebriza exposes a public REST API: `Open bill` (place an order on a table),
`List items` (menu), `List tables` (validate table), `BillStatusEntry` +
WebHooks (status), and `Push notifications to POS`. Payment is order-only for now.

## Decision (EN)
The app talks to `OrderingService` / `MenuRepository` interfaces. The real
implementation is an **Ebriza adapter** reached through **our own thin backend
(BFF)** (see ADR-0009). Ebriza is the single source of truth for menu, tables,
orders, and payment. Phase 0 uses a mock; Phase 1 drops in the adapter.

## Alternatives rejected (EN)
- **Our own primary backend (e.g. Supabase) storing orders**: duplicates what
  Ebriza already does (orders, payment, bar view). A thin cache/proxy is enough.
- **Firebase**: Google-only, drags in GMS, fights the Huawei constraint.
- **App talks to Ebriza directly**: would leak the API secret into the client.

## Consequences (EN)
- Requires an app registered in Ebriza Marketplace + the venue authorizing it
  for its location (`ebriza-clientid`). This is a Phase 1 onboarding step.
- Confirm that an API-injected order surfaces on the Ebriza iPad like a Glovo order.

---

## Context (RO)
Localul rulează deja POS-ul **Ebriza** pe un iPad (mese, comenzi, plată). Ebriza
are un API REST public: `Open bill` (pune o comandă pe masă), `List items`
(meniu), `List tables` (validează masa), `BillStatusEntry` + WebHooks (status),
și `Push notifications to POS`. Plata e doar "order-only" deocamdată.

## Decizie (RO)
Aplicația vorbește cu interfețele `OrderingService` / `MenuRepository`.
Implementarea reală e un **adaptor Ebriza** ajuns prin **serverul nostru subțire
(BFF)** (vezi ADR-0009). Ebriza e sursa unică de adevăr pentru meniu, mese,
comenzi, și plată. Faza 0 e pe mock; Faza 1 bagă adaptorul.

## Alternative respinse (RO)
- **Backend propriu principal (ex. Supabase) care stochează comenzi**: dublează
  ce face deja Ebriza. Un cache/proxy subțire e de ajuns.
- **Firebase**: doar Google, trage GMS, strică Huawei.
- **Aplicația vorbește direct cu Ebriza**: ar expune cheia secretă în client.

## Consecințe (RO)
- Cere o app înregistrată în Ebriza Marketplace + autorizarea din contul localului
  (`ebriza-clientid`). E un pas de onboarding în Faza 1.
- De confirmat că o comandă băgată prin API iese pe iPad-ul Ebriza ca una de Glovo.

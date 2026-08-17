# ADR-0045: Customer cross-device identity — phone-OTP seam (mock first)

- Status: Accepted
- Date: 2026-08-17

## Context (EN)
Loyalty (points, history, redemptions) was keyed by the anonymous per-device
`clientId`, so it did not follow the customer to a new phone. For a horizontal
hospitality product (pubs, patisseries, restaurants; many tenants) the customer
needs a stable identity they can prove on any device. This slice lays the seam
and the flow, mock-first (no SMS, no backend change), exactly as the backend
started.

## Decision (EN)
- **Phone + OTP** (one-time password by SMS) is the method: universal across web,
  Android, iOS and Huawei (no Google Play Services dependency), and the norm for
  loyalty. `IdentityService` is the port; `MockIdentityService` (fixed demo code
  `000000`, no SMS) drives the demo and tests. The SMS/BFF adapter drops in behind
  the same port later.
- **Identity subsumes the loyal flag.** `Session` drops `CustomerKind` and carries
  a `CustomerIdentity?` (customerId + phone + token). `isLoyalCustomer` becomes
  "signed in as a customer". Enrolling becomes signing in.
- **Shared identity, per-venue loyalty.** The `customerId` is platform-level (one
  per phone). Loyalty / history / redemptions key on the **effective loyalty key**
  (`loyaltyKeyProvider`): the `customerId` when signed in, else the anonymous
  `clientId`. So an anonymous customer still accrues locally-visible data, and it
  merges to the identity on sign-in (the merge itself lands with the real backend).
- **Consent is a recorded fact, captured at sign-in.** `Consent` (per
  `ConsentPurpose`: loyalty vs marketing) is set through a `ConsentSource` port,
  per venue (each venue is the data controller for its own customers). Loyalty
  consent is required to sign in; marketing is optional and unticked.
- **Honest deferral.** Server-side enforcement (a token on requests, per-tenant
  authorization) and the real SMS adapter land in the next slices; this slice is
  the keying + flow + recorded consent, mock-backed.

## Alternatives rejected (EN)
- **Google / Apple sign-in as the base.** Dies on Huawei (no Play Services) and is
  clunky in the web-first QR flow; keep it as an optional native shortcut later,
  not the base.
- **Email magic-link.** Slower at the table and weaker recovery than a phone.
- **Cross-venue (coalition) loyalty now.** A platform move (shared economy, one
  controller); the `(customerId, venueId)` key leaves the door open without
  committing to it.
- **Keeping `CustomerKind` alongside identity.** Two overlapping concepts; the
  identified customer IS the loyal one, so one seam is cleaner.

## Consequences (EN)
- Loyalty is now keyed to follow the customer; on the mock it still reads empty
  (no history), consistent with the rest of loyalty.
- The staff/owner access-code gate is unchanged; only the customer gained a real
  sign-in.
- Enforcement and SMS are explicitly a later slice; the client-side flow is honest
  scaffolding, not a security claim.

---

## Context (RO)
Fidelitatea (puncte, istoric, revendicări) era cheiată pe `clientId`-ul anonim
per-dispozitiv, deci nu urma clientul pe un telefon nou. Pentru un produs orizontal
de hospitality (puburi, cofetării, restaurante; mulți tenanți) clientul are nevoie
de o identitate stabilă pe care s-o dovedească pe orice dispozitiv. Felia asta pune
seam-ul și fluxul, mock întâi (fără SMS, fără schimbare de backend), exact cum a
pornit backendul.

## Decizie (RO)
- **Telefon + OTP** (parolă de unică folosință prin SMS) e metoda: universală pe
  web, Android, iOS și Huawei (fără dependență de Google Play Services), și
  standardul de loialitate. `IdentityService` e portul; `MockIdentityService` (cod
  demo fix `000000`, fără SMS) mișcă demo-ul și testele. Adaptorul SMS/BFF intră în
  spatele aceluiași port mai târziu.
- **Identitatea o subsumează pe „fidel".** `Session` renunță la `CustomerKind` și
  poartă un `CustomerIdentity?` (customerId + telefon + token). `isLoyalCustomer`
  devine „autentificat ca și client". Înscrierea devine autentificare.
- **Identitate partajată, loialitate per-local.** `customerId` e la nivel de
  platformă (unul per telefon). Loialitatea / istoricul / revendicările se cheie pe
  **cheia efectivă** (`loyaltyKeyProvider`): `customerId` când ești logat, altfel
  `clientId`-ul anonim. Deci un client anonim tot adună date, iar la sign-in se
  face merge (merge-ul propriu-zis vine cu backendul real).
- **Consimțământul e un fapt înregistrat, captat la sign-in.** `Consent` (per
  `ConsentPurpose`: fidelitate vs marketing) se setează printr-un port
  `ConsentSource`, per local (fiecare local e data controller pe clienții lui).
  Consimțământul de fidelitate e obligatoriu la sign-in; marketingul e opțional și
  nebifat.
- **Amânare onestă.** Enforcement-ul pe server (token pe cereri, autorizare
  per-tenant) și adaptorul SMS real vin în feliile următoare; felia asta e keying +
  flux + consimțământ înregistrat, pe mock.

## Alternative respinse (RO)
- **Google / Apple ca bază.** Pică pe Huawei (fără Play Services) și e greoi în
  fluxul web-first prin QR; îl păstrăm ca scurtătură opțională pe nativ, nu ca bază.
- **Email magic-link.** Mai lent la masă și recuperare mai slabă decât telefonul.
- **Loialitate cross-local (coaliție) acum.** E o mișcare de platformă (economie
  comună, un singur controller); cheia `(customerId, venueId)` lasă ușa deschisă
  fără s-o forțeze.
- **Păstrarea `CustomerKind` lângă identitate.** Două concepte care se suprapun;
  clientul identificat E cel fidel, deci un singur seam e mai curat.

## Consecințe (RO)
- Fidelitatea e acum cheiată să urmeze clientul; pe mock tot citește gol (fără
  istoric), consistent cu restul fidelității.
- Poarta cu cod de acces pentru staff/patron e neschimbată; doar clientul a primit
  un sign-in real.
- Enforcement-ul și SMS-ul sunt explicit o felie ulterioară; fluxul pe client e
  schelă onestă, nu o pretenție de securitate.

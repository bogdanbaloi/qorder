# ADR-0003: Deep links = Universal/App Links + self-hosted landing page

- Status: Accepted (design, implemented in Phase 2)
- Date: 2026-08-12

## Context (EN)
Each table's QR encodes a URL like `https://order.<venue>.app/t/12`. If the app
is installed it must open directly to that table's menu. If not, the same URL
must route to the correct store. Firebase Dynamic Links is deprecated.

## Decision (EN)
Use **iOS Universal Links** (AASA file) and **Android App Links** (assetlinks.json,
`autoVerify`) so an installed app opens directly. For the not-installed case, a
**self-hosted landing page** at the domain detects the OS and routes to App Store
/ Play / AppGallery. The table number is carried in the URL for the happy path.
**Manual entry is the guaranteed fallback** because a deferred install can lose
the parameter. Android App Links also work on Huawei (AOSP).

## Alternatives rejected (EN)
- **Firebase Dynamic Links**: deprecated.
- **Branch / AppsFlyer** (deferred deep-link SDKs): extra dependency + tracking,
  kept only as a future option if deferred linking becomes a hard requirement.

## Consequences (EN)
- The venue ALREADY has per-table QR stickers on its own domain (demopub.example),
  labelled per table (e.g. table 101), currently opening a web menu ("Smart Menu").
  We reuse that domain and, if the URL carries the table number, the existing
  stickers too (no new domain, no reprint). To confirm at implementation: the
  exact URL shape and who can host files under `/.well-known/`.
- Still needs Apple Developer membership and the associated-domains entitlement.
- The not-installed case degrades to the existing web menu plus an "install app" CTA.
- The `/t/:table` route already exists in the app as the seam.

---

## Context (RO)
QR-ul fiecărei mese conține un URL de forma `https://order.<venue>.app/t/12`.
Dacă aplicația e instalată, trebuie să deschidă direct meniul mesei. Dacă nu,
același URL trebuie să ducă la magazinul corect. Firebase Dynamic Links e depreciat.

## Decizie (RO)
Folosim **Universal Links pe iOS** (fișier AASA) și **App Links pe Android**
(assetlinks.json, `autoVerify`), ca aplicația instalată să se deschidă direct.
Pentru cazul "neinstalat", o **pagină de aterizare self-hosted** pe domeniu
detectează sistemul de operare și rutează spre App Store / Play / AppGallery.
Numărul mesei e purtat în URL pentru calea fericită. **Introducerea manuală e
rezerva garantată**, fiindcă un install amânat poate pierde parametrul. App Links
merg și pe Huawei (AOSP).

## Alternative respinse (RO)
- **Firebase Dynamic Links**: depreciat.
- **Branch / AppsFlyer** (SDK-uri de deferred deep-link): dependență în plus +
  tracking, păstrate doar ca opțiune viitoare dacă chiar e nevoie.

## Consecințe (RO)
- Cere un domeniu propriu, cont Apple Developer, și entitlement-ul de domenii asociate.
- Ruta `/t/:table` există deja în aplicație ca sămânță.

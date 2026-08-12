# ADR-0009: Secrets live in a thin BFF, never in the app

- Status: Accepted (design, implemented in Phase 1)
- Date: 2026-08-12

## Context (EN)
The Ebriza API needs an app secret key. Anything shipped inside a mobile app can
be extracted from the package.

## Decision (EN)
Put a **thin backend (BFF, "backend for frontend")** between the app and Ebriza.
The app calls our BFF. The BFF holds the Ebriza credentials and calls Ebriza. The
BFF also gives us a place for a menu cache and decouples the app from the POS.

## Alternatives rejected (EN)
- **App calls Ebriza directly**: leaks the secret key into the client.
- **Embed the secret with obfuscation**: still extractable, false security.

## Consequences (EN)
- One more small component to host (Phase 1). Language is free (Node/Go/.NET).
  Ebriza ships .NET and JS client libraries for the BFF, not the app.

---

## Context (RO)
API-ul Ebriza cere o cheie secretă de app. Orice pui în aplicația de pe telefon
poate fi scos din pachet.

## Decizie (RO)
Punem un **server subțire (BFF, "backend for frontend")** între aplicație și
Ebriza. Aplicația cheamă BFF-ul. BFF-ul ține credențialele Ebriza și cheamă
Ebriza. BFF-ul ne dă și un loc pentru cache de meniu și decuplează aplicația de POS.

## Alternative respinse (RO)
- **Aplicația cheamă Ebriza direct**: expune cheia secretă în client.
- **Secret ascuns prin ofuscare**: tot poate fi scos, securitate falsă.

## Consecințe (RO)
- Încă o componentă mică de găzduit (Faza 1). Limbajul e liber (Node/Go/.NET).
  Ebriza are librării client .NET și JS pentru BFF, nu pentru aplicație.

# ADR-0007: Multi-tenant via a venueId seam

- Status: Accepted
- Date: 2026-08-12

## Context (EN)
The first customer is one pub (Demo), but the product must be extensible to
other venues without a rewrite.

## Decision (EN)
Build for a single venue now, but carry a **`venueId`** in the model, the config
(`AppConfig`), and the URL scheme (`/v/<venue>/t/<table>` is parseable alongside
`/t/<table>`). Branding is data (`Branding`), not code. A second venue = a new
config + its own Ebriza account, not new code.

## Alternatives rejected (EN)
- **Hard-code the single pub**: cheap now, expensive at the second venue.
- **Full multi-tenant infrastructure now**: over-engineering before demand.

## Consequences (EN)
- Menu, cart, and order all already carry `venueId`.

---

## Context (RO)
Primul client e un singur pub (Demo), dar produsul trebuie să fie extensibil
la alte localuri fără rescriere.

## Decizie (RO)
Construim pentru un singur local acum, dar purtăm un **`venueId`** în model, în
config (`AppConfig`), și în schema de URL (`/v/<venue>/t/<table>` se parsează
alături de `/t/<table>`). Brand-ul e date (`Branding`), nu cod. Al doilea local =
un config nou + contul lui de Ebriza, nu cod nou.

## Alternative respinse (RO)
- **Hardcodarea unui singur pub**: ieftin acum, scump la al doilea local.
- **Infrastructură multi-tenant completă acum**: over-engineering înainte de cerere.

## Consecințe (RO)
- Meniul, coșul, și comanda poartă deja `venueId`.

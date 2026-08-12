# ADR-0004: Menu = structured model, money in minor units

- Status: Accepted
- Date: 2026-08-12

## Context (EN)
An existing HTML menu is the source of content, but must not be rendered in a
webview. The menu has variant pricing (0.4/0.5L, glass/bottle), combos, and
time-windowed availability (Morning Deal Mon-Fri 09:00-16:00).

## Decision (EN)
Extract the HTML into a structured model: `Menu > Category > MenuItem` with
`OptionGroup/OptionChoice` for variants and a `TimeWindow` for availability.
Money is stored as **integer minor units** (bani), never floating point. Phase 0
seeds from a bundled JSON. Phase 1 fetches the same shape live from Ebriza.

## Alternatives rejected (EN)
- **Render the HTML in a webview**: no native cart, no offline, poor testability.
- **Floating-point money**: rounding bugs on a bill.

## Consequences (EN)
- Cart lines snapshot name + price, so a later menu edit cannot change a placed order.

---

## Context (RO)
Un meniu HTML existent e sursa de conținut, dar nu trebuie randat în webview.
Meniul are prețuri pe variante (0.4/0.5L, pahar/sticlă), combo-uri, și
disponibilitate pe interval orar (Morning Deal luni-vineri 09:00-16:00).

## Decizie (RO)
Extragem HTML-ul într-un model structurat: `Menu > Category > MenuItem`, cu
`OptionGroup/OptionChoice` pentru variante și `TimeWindow` pentru disponibilitate.
Banii se țin ca **unități minore întregi** (bani), niciodată virgulă mobilă. Faza 0
pornește dintr-un JSON împachetat. Faza 1 ia aceeași formă live din Ebriza.

## Alternative respinse (RO)
- **Randarea HTML-ului în webview**: fără coș nativ, fără offline, greu de testat.
- **Bani în virgulă mobilă**: erori de rotunjire pe notă.

## Consecințe (RO)
- Liniile de coș fac snapshot la nume + preț, deci o editare ulterioară a meniului
  nu poate schimba o comandă deja plasată.

# ADR-0037: Localize the staff and owner surfaces too

- Status: Accepted
- Date: 2026-08-16

## Context (EN)
RO/EN localization (ADR-0027) covered only the customer surfaces (menu, cart). The
owner wants every surface localizable: the waiter surface, the owner dashboard,
and the access gate, so staff and the owner can work in their language.

## Decision (EN)
- **Extend the same string table.** The staff, owner and gate strings are added to
  the existing `AppStrings` interface with `StringsRo` / `StringsEn`
  implementations. No new mechanism, no widget holds a literal. Titles reuse the
  existing `tableAt` / `orderNumber` strings (DRY).
- **A shared toggle.** The inline menu toggle became a `LanguageToggle` widget,
  now on every surface's app bar (customer, waiter, owner, gate), so each entry
  point can switch language independently. The language is app-wide and persisted.
- **The gate localizes too**, titled per role ("Acces staff" / "Acces patron").

## Alternatives rejected (EN)
- **Keep staff / owner Romanian-only.** The owner asked for all surfaces; an
  English-speaking barman or owner is a real case.
- **A second string table for staff.** One table with one toggle keeps a single
  source of truth; a new language is still one implementation.

## Consequences (EN)
- Every surface switches RO/EN from its own app bar.
- Menu CONTENT still stays as the venue supplies it (only the chrome is
  translated).
- Follow-up: a third language is still just a new `AppStrings` implementation.

---

## Context (RO)
Localizarea RO/EN (ADR-0027) acoperea doar suprafețele de client (meniu, coș).
Patronul vrea fiecare suprafață localizabilă: suprafața ospătarului, dashboard-ul
patronului și poarta de acces, ca personalul și patronul să lucreze în limba lor.

## Decizie (RO)
- **Extindem același tabel de string-uri.** String-urile de staff, patron și
  poartă se adaugă la interfața `AppStrings` existentă cu implementările
  `StringsRo` / `StringsEn`. Fără mecanism nou, niciun widget nu ține un literal.
  Titlurile refolosesc string-urile `tableAt` / `orderNumber` (DRY).
- **Un toggle comun.** Toggle-ul inline din meniu a devenit un widget
  `LanguageToggle`, acum pe bara fiecărei suprafețe (client, ospătar, patron,
  poartă), ca fiecare punct de intrare să comute limba independent. Limba e la
  nivel de app și persistată.
- **Poarta se localizează și ea**, cu titlu pe rol („Acces staff" / „Acces
  patron").

## Alternative respinse (RO)
- **Păstrarea staff / patron doar în română.** Patronul a cerut toate suprafețele;
  un barman sau patron vorbitor de engleză e un caz real.
- **Un al doilea tabel de string-uri pentru staff.** Un tabel cu un toggle ține o
  sursă unică; o limbă nouă e tot o implementare.

## Consecințe (RO)
- Fiecare suprafață comută RO/EN din propria bară.
- CONȚINUTUL meniului rămâne cum îl dă localul (doar interfața se traduce).
- De urmat: o a treia limbă e tot doar o implementare `AppStrings` nouă.

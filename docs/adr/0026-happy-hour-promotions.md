# ADR-0026: Happy-hour promotions (time-boxed pricing)

- Status: Accepted
- Date: 2026-08-16

## Context (EN)
The venue wants happy hours: at certain times some items cost less. This must be
generic (any venue, any window, any scope), and the price the menu shows must be
the price the cart charges.

## Decision (EN)
A pricing engine in the Domain, all pure:
- `Discount` (sealed): `PercentageDiscount` and `FixedAmountDiscount`, each
  `apply(Money) -> Money`. Sealed, so a new kind is a new subtype, not an edit to
  callers (Open/Closed).
- `Promotion`: a `TimeWindow`, a `Discount` and a scope (`categoryIds`, `tags`,
  empty = any). It depends only on primitives (`covers(categoryId, tags)`), NOT
  on `MenuItem`, so it does not import the menu model (no cycle).
- `priceItem(item, promotions, now) -> PricedItem`: picks the active applicable
  promotion that gives the lowest price. `now` is passed in, so it is unit-tested
  with explicit times.
- Promotions are DATA on the `Menu` (parsed from JSON `promotions`), so a venue
  turns a happy hour on without a rebuild.

The View shows the base struck through with the reduced price and the promo name.
The cart calls the SAME `priceItem` at add time and snapshots the effective price
(`CartController` reads `menuProvider`), so the total matches the menu. To avoid
an import cycle `TimeWindow` moved to its own file, re-exported from `menu.dart`.

## Alternatives rejected (EN)
- **Discount computed in the widget.** The menu and the cart could then disagree.
  One pure function shared by both is the single source of truth.
- **Promotions in code / AppConfig.** They belong with the menu payload (Ebriza
  will supply them), and JSON keeps them data, not code.
- **Re-price the cart continuously.** The price is snapshotted at add time, like a
  POS. A follow-up can re-price at submit if a venue wants that.

## Consequences (EN)
- Any venue defines happy hours as data. The menu and total always agree.
- Follow-up: inject a clock for full testability of the cart path, a submit-time
  re-price option, and a happy-hour banner on the menu.

---

## Context (RO)
Localul vrea happy hours: la anumite ore unele produse costă mai puțin. Trebuie să
fie generic (orice local, orice fereastră, orice scope), iar prețul afișat în
meniu trebuie să fie prețul pe care îl încasează coșul.

## Decizie (RO)
Un motor de preț în Domain, totul pur:
- `Discount` (sealed): `PercentageDiscount` și `FixedAmountDiscount`, fiecare
  `apply(Money) -> Money`. Sealed, deci un tip nou e un subtip nou, nu o
  modificare la apelanți (Open/Closed).
- `Promotion`: un `TimeWindow`, un `Discount` și un scope (`categoryIds`, `tags`,
  gol = oricare). Depinde doar de primitive (`covers(categoryId, tags)`), NU de
  `MenuItem`, deci nu importă modelul de meniu (fără ciclu).
- `priceItem(item, promotions, now) -> PricedItem`: alege promoția activă
  aplicabilă cu cel mai mic preț. `now` e pasat, deci e testat cu ore explicite.
- Promoțiile sunt DATE pe `Menu` (parsate din JSON `promotions`), deci un local
  pornește un happy hour fără rebuild.

View-ul arată prețul de bază tăiat cu prețul redus și numele promoției. Coșul
cheamă ACEEAȘI funcție `priceItem` la adăugare și snapshot-uiește prețul efectiv
(`CartController` citește `menuProvider`), deci totalul se potrivește cu meniul.
Ca să evităm un ciclu de import, `TimeWindow` a fost mutat în fișier propriu,
re-exportat din `menu.dart`.

## Alternative respinse (RO)
- **Reducerea calculată în widget.** Atunci meniul și coșul s-ar putea contrazice.
  O singură funcție pură folosită de amândouă e sursa unică de adevăr.
- **Promoții în cod / AppConfig.** Ele stau cu payload-ul meniului (Ebriza le va
  furniza), iar JSON le ține date, nu cod.
- **Recalcularea continuă a coșului.** Prețul e snapshot la adăugare, ca la un POS.
  Un follow-up poate recalcula la trimitere dacă un local vrea asta.

## Consecințe (RO)
- Orice local definește happy hours ca date. Meniul și totalul se potrivesc mereu.
- De urmat: injectarea unui ceas pentru testabilitate completă a căii de coș, o
  opțiune de recalculare la trimitere și un banner de happy hour pe meniu.

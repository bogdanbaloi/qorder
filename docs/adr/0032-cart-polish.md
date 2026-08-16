# ADR-0032: Cart polish (persisted name, happy-hour savings, empty state)

- Status: Accepted
- Date: 2026-08-16

## Context (EN)
Three small frictions in the cart: the name was re-typed every visit, a happy-hour
discount was applied but never shown as a saving, and the empty cart was a bare
line of text.

## Decision (EN)
- **Persist the name.** `CustomerNameController` now restores the name from the
  `LocalStore` port on launch and saves it on change, the same seam as the
  language. A returning customer keeps their name.
- **Show the saving.** A cart line carries `discountPerUnit` (0 when no promotion),
  set at add time from the pure `priceItem` (base minus effective). `Cart.savings`
  sums it, and the order form shows "Ai economisit X" in the accent colour when it
  is positive. Money math stays in integer minor units.
- **Friendlier empty state.** The empty cart shows a cart icon above the text.

## Alternatives rejected (EN)
- **Recomputing the saving in the widget.** The cart line already snapshots the
  effective price, so it carries the per-unit discount too. One number, computed
  once by the domain, keeps the menu and the cart consistent.
- **A full account for the name.** Persisting the string through the existing port
  is enough for a returning anonymous customer; real accounts are the loyal-
  customer / user-management phase.

## Consequences (EN)
- The name survives a restart, the happy-hour saving is visible, the empty cart
  reads better.
- The cart line's JSON gained `discountMinor` (defaults to 0, back-compatible).
- Follow-up: a per-line "saved X" note, and the same persistence for the table.

---

## Context (RO)
Trei fricțiuni mici în coș: numele se re-scria la fiecare vizită, reducerea de
happy hour se aplica dar nu se arăta ca economie, iar coșul gol era o linie seacă
de text.

## Decizie (RO)
- **Reținem numele.** `CustomerNameController` restaurează acum numele din portul
  `LocalStore` la pornire și îl salvează la schimbare, același seam ca la limbă. Un
  client care revine își păstrează numele.
- **Arătăm economia.** O linie de coș poartă `discountPerUnit` (0 fără promoție),
  setat la adăugare din `priceItem` pur (bază minus efectiv). `Cart.savings` îl
  însumează, iar formularul de comandă arată „Ai economisit X" în culoarea de
  accent când e pozitiv. Banii rămân în unități minore întregi.
- **Stare goală mai prietenoasă.** Coșul gol arată o iconiță de coș peste text.

## Alternative respinse (RO)
- **Recalcularea economiei în widget.** Linia de coș snapshot-uiește deja prețul
  efectiv, deci poartă și reducerea pe unitate. Un număr, calculat o dată de
  domain, ține meniul și coșul consistente.
- **Un cont complet pentru nume.** Persistarea string-ului prin portul existent e
  destul pentru un client anonim care revine; conturile reale sunt faza de
  client-fidel / user-management.

## Consecințe (RO)
- Numele supraviețuiește unei reporniri, economia de happy hour e vizibilă, coșul
  gol se citește mai bine.
- JSON-ul liniei de coș a primit `discountMinor` (implicit 0, compatibil înapoi).
- De urmat: o notă „economisit X" pe linie și aceeași persistență pentru masă.

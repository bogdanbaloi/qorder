# ADR-0031: Faster adding (quantity, quick-add, haptic)

- Status: Accepted
- Date: 2026-08-16

## Context (EN)
Adding was one item per tap through the detail sheet. To order three of something
you tapped three times or fixed it later in the cart. The most common gesture was
the slowest.

## Decision (EN)
- **Quantity in the sheet.** The detail sheet is now stateful with a quantity
  stepper, and adds that many at once. The sheet is wrapped in a
  `SingleChildScrollView` so it never overflows on a small screen.
- **Quick-add on the row.** A "+" button in each row adds one straight to the cart
  without opening the sheet. Tapping the row still opens the sheet for detail.
- **Haptic + confirmation.** A single `_addWithFeedback` helper is the one add
  path for both the row and the sheet: a light haptic tap, the cart add (with the
  item's default required options, the domain rule), and a brief snackbar.

## Alternatives rejected (EN)
- **Only the sheet.** Too slow for the common case of a quick single add.
- **Two separate add code paths.** The row and the sheet would drift. One helper
  keeps the feedback and the option rule identical.
- **A fixed-height sheet.** It overflowed once the quantity row was added. Making
  it scrollable is robust across screen sizes.

## Consequences (EN)
- One tap adds a drink, and several of one item is a quantity, not repeated taps.
- The add feedback (haptic + snackbar) is consistent everywhere.
- Follow-up: an options sheet (size, extras) when items carry real option groups.

---

## Context (RO)
Adăugarea era un produs pe tap, prin fișa de detaliu. Ca să comanzi trei dintr-un
produs dădeai de trei ori sau reglai în coș. Cel mai frecvent gest era cel mai
lent.

## Decizie (RO)
- **Cantitate în fișă.** Fișa de detaliu e acum cu stare, cu un selector de
  cantitate, și adaugă atâtea deodată. Fișa e învelită într-un
  `SingleChildScrollView` ca să nu depășească pe ecran mic.
- **Adăugare rapidă pe rând.** Un buton „+" pe fiecare rând adaugă unul direct în
  coș, fără să deschidă fișa. Tap pe rând tot deschide fișa pentru detaliu.
- **Haptic + confirmare.** Un singur helper `_addWithFeedback` e calea unică de
  adăugare pentru rând și fișă: o vibrație ușoară, adăugarea în coș (cu opțiunile
  obligatorii implicite ale produsului, regula din domain) și un snackbar scurt.

## Alternative respinse (RO)
- **Doar fișa.** Prea lent pentru cazul frecvent al unei adăugări rapide.
- **Două căi separate de adăugare.** Rândul și fișa ar diverge. Un helper ține
  feedback-ul și regula de opțiuni identice.
- **O fișă cu înălțime fixă.** Depășea odată ce s-a adăugat rândul de cantitate.
  Scrollabilă e robustă pe orice ecran.

## Consecințe (RO)
- Un tap adaugă o băutură, iar mai multe dintr-un produs e o cantitate, nu tap-uri
  repetate.
- Feedback-ul de adăugare (haptic + snackbar) e consistent peste tot.
- De urmat: o fișă de opțiuni (mărime, extra) când produsele au grupuri reale de
  opțiuni.

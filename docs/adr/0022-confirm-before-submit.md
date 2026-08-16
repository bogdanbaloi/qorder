# ADR-0022: Review dialog before submitting an order

- Status: Accepted
- Date: 2026-08-16

## Context (EN)
Submitting was a single tap that fired the order straight to the bar. A mis-tap,
a wrong table or a forgotten item reached the bar with no chance to catch it. A
short review builds confidence and prevents mistakes.

## Decision (EN)
Tapping "Trimite comanda" now opens a review dialog first: the table, the name,
the items with quantities and the total, then "Înapoi" or "Trimite". The order
is submitted only on confirm. The submit gate (`canSubmitProvider`) is unchanged,
this adds a confirm step on top of it, not a new rule.

## Alternatives rejected (EN)
- **Submit on the first tap**: fast but error-prone, exactly the friction we are
  removing across the app.
- **A separate review screen**: heavier navigation for a short check. A dialog is
  enough and keeps the customer in place.
- **An undo snackbar after submit**: the order may already be at the bar by the
  time the customer reacts. Confirming before is safer than undoing after.

## Consequences (EN)
- The customer sees exactly what goes to the bar (table + items + total) before
  it is sent, so wrong-table or accidental orders are caught.
- One extra tap on the happy path, a fair trade for correctness.
- Follow-up: a note field on the dialog (allergies, "no ice").

---

## Context (RO)
Trimiterea era o singură apăsare care lansa comanda direct la bar. O apăsare
greșită, o masă greșită sau un produs uitat ajungeau la bar fără șansă de a le
prinde. O verificare scurtă dă încredere și previne greșelile.

## Decizie (RO)
Apăsarea pe „Trimite comanda" deschide acum întâi un dialog de verificare: masa,
numele, produsele cu cantități și totalul, apoi „Înapoi" sau „Trimite". Comanda
se trimite doar la confirmare. Poarta de trimitere (`canSubmitProvider`) rămâne
neschimbată, asta adaugă un pas de confirmare peste ea, nu o regulă nouă.

## Alternative respinse (RO)
- **Trimitere din prima apăsare**: rapid dar predispus la greșeli, fix frecarea
  pe care o eliminăm din aplicație.
- **Un ecran separat de verificare**: navigare mai grea pentru o verificare
  scurtă. Un dialog ajunge și ține clientul pe loc.
- **Un snackbar de anulare după trimitere**: comanda poate fi deja la bar când
  reacționează clientul. Confirmarea înainte e mai sigură decât anularea după.

## Consecințe (RO)
- Clientul vede exact ce pleacă la bar (masă + produse + total) înainte să fie
  trimis, deci comenzile pe masă greșită sau accidentale sunt prinse.
- O apăsare în plus pe drumul fericit, un schimb corect pentru corectitudine.
- De urmat: un câmp de observații în dialog (alergii, „fără gheață").

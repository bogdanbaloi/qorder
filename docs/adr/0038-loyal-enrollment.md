# ADR-0038: Loyal-customer enrollment and the loyal-gated table pick

- Status: Accepted
- Date: 2026-08-17

## Context (EN)
The `CustomerKind` seam (normal / loyal) existed but nothing set it. The normal
customer gets their table from the QR link; the loyal customer opens the installed
app cold, with no table in a URL, so they need to pick their table. That table
pick must be loyal-only (decided when the strip was first built and reverted).

## Decision (EN)
- **Enrollment.** A loyalty action in the menu app bar opens a sheet: a normal
  customer enters a name and taps enrol, becoming loyal; a loyal one sees their
  status and can leave. `SessionController.enrollLoyal` / `leaveLoyal` flip the
  `CustomerKind`, and the session now persists the kind (not only the role)
  through the `LocalStore` port, so a returning loyal customer stays loyal.
- **The table strip, gated.** The manual "Alege masa" strip returns, shown only
  when the session is a loyal customer and no valid table is set. A normal
  customer never sees it (their table is in the QR link).

## Alternatives rejected (EN)
- **Show the table pick to any customer.** Decided against earlier: the normal
  customer's table comes from the QR, so the pick is a loyal-only need.
- **A full account with a password now.** A name-only enrollment is enough to be
  loyal; real accounts / phone verification are a later step.

## Consequences (EN)
- A customer can become loyal, and only then gets the in-app table pick.
- Loyalty persists on the device.
- Follow-up: the in-app QR table scanner (camera) as the fast path, plus order
  history, points and offers for loyal customers.

---

## Context (RO)
Seam-ul `CustomerKind` (normal / fidel) exista, dar nimic nu-l seta. Clientul
normal își ia masa din linkul QR; clientul fidel deschide app-ul instalat „la
rece", fără masă în URL, deci trebuie să-și aleagă masa. Alegerea aia de masă
trebuie să fie doar pentru fideli (decis când stripul a fost construit prima oară
și dat înapoi).

## Decizie (RO)
- **Înrolare.** O acțiune de fidelitate în bara de meniu deschide o fișă: un
  client normal scrie un nume și apasă înscrie-te, devenind fidel; unul fidel își
  vede statusul și poate renunța. `SessionController.enrollLoyal` / `leaveLoyal`
  schimbă `CustomerKind`, iar sesiunea persistă acum și tipul (nu doar rolul) prin
  portul `LocalStore`, deci un client fidel care revine rămâne fidel.
- **Stripul de masă, gated.** Stripul manual „Alege masa" revine, arătat doar când
  sesiunea e client fidel și nu e masă validă. Un client normal nu-l vede
  niciodată (masa lui e în linkul QR).

## Alternative respinse (RO)
- **Alegerea mesei pentru orice client.** Respinsă mai devreme: masa clientului
  normal vine din QR, deci alegerea e o nevoie doar de fidel.
- **Un cont complet cu parolă acum.** O înrolare doar cu nume e destul pentru a fi
  fidel; conturile reale / verificarea telefonului sunt un pas ulterior.

## Consecințe (RO)
- Un client poate deveni fidel și abia atunci primește alegerea mesei în app.
- Fidelitatea persistă pe dispozitiv.
- De urmat: scannerul QR de masă în app (cameră) ca drum rapid, plus istoric
  comenzi, puncte și oferte pentru clienții fideli.

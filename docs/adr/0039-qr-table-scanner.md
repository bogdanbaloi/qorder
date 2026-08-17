# ADR-0039: In-app QR table scanner, and moving loyal enrollment off the menu

- Status: Accepted
- Date: 2026-08-17

## Context (EN)
A loyal customer opens the installed app cold, with no table in a URL, so they
need to set their table. A camera scan of the table sticker is the fast path. And
the loyalty enrollment button, put in the customer menu app bar, confused normal
customers: they order via a QR link and should not be nagged to "become loyal",
and enrolling changed nothing visible (its perks are not built).

## Decision (EN)
- **QR scanner.** A `QrScanScreen` (via `mobile_scanner`) reads the table QR and
  pops with the parsed table. A pure `tableFromScan` parses the number from our
  table link (".../t/7"), a "?table=" query, or a bare number, unit-tested without
  a camera. The loyal table strip offers "Scanează" next to "Alege masa". Camera
  permissions added for Android / iOS.
- **Declutter.** The loyalty enrollment button and sheet are removed from the menu
  app bar. The `CustomerKind` seam, the loyal-gated table strip and the scanner
  stay in code, ready for a dedicated "my account / loyalty" screen (with a real
  payoff: history, offers) rather than a nag in the ordering flow.

## Alternatives rejected (EN)
- **Keep the enrol button in the menu.** It confused the normal QR customer and
  had no visible payoff. Loyalty belongs in the installed-app / profile context.
- **A JS QR library by hand.** `mobile_scanner` is the maintained cross-platform
  option; the parser is ours and tested.

## Consequences (EN)
- The scanner and the loyal table pick are code-ready; they light up once a
  profile screen enrols a loyal customer. The camera needs a secure context
  (HTTPS or a native build), so it does not run on the plain-http LAN demo.
- Follow-up: a "my account / loyalty" screen (enrol, status, history, offers) as
  the proper home for the loyal features.

---

## Context (RO)
Un client fidel deschide app-ul instalat „la rece", fără masă în URL, deci trebuie
să-și seteze masa. Un scan al stickerului de masă e drumul rapid. Iar butonul de
înrolare, pus în bara de meniu a clientului, îi deruta pe clienții normali: ei
comandă prin link QR și nu trebuie „bătuți la cap" să devină fideli, iar înrolarea
nu schimba nimic vizibil (beneficiile nu-s construite).

## Decizie (RO)
- **Scanner QR.** Un `QrScanScreen` (prin `mobile_scanner`) citește QR-ul mesei și
  întoarce masa parsată. Un `tableFromScan` pur extrage numărul din linkul nostru
  de masă (".../t/7"), un query "?table=" sau un număr simplu, testat unitar fără
  cameră. Stripul de masă al fidelului oferă „Scanează" lângă „Alege masa".
  Permisiuni de cameră adăugate pentru Android / iOS.
- **Declutter.** Butonul și fișa de înrolare se scot din bara de meniu. Seam-ul
  `CustomerKind`, stripul gated pe fidel și scannerul rămân în cod, gata pentru un
  ecran dedicat „contul meu / fidelitate" (cu payoff real: istoric, oferte), nu ca
  nag în fluxul de comandă.

## Alternative respinse (RO)
- **Păstrarea butonului de înrolare în meniu.** Deruta clientul normal prin QR și
  n-avea payoff vizibil. Fidelitatea ține de contextul app instalat / profil.
- **O librărie JS de QR scrisă de mână.** `mobile_scanner` e opțiunea
  cross-platform întreținută; parserul e al nostru și testat.

## Consecințe (RO)
- Scannerul și alegerea mesei pentru fidel sunt code-ready; se aprind când un ecran
  de profil înrolează un client fidel. Camera cere context securizat (HTTPS sau
  build nativ), deci nu merge pe demo-ul http din LAN.
- De urmat: un ecran „contul meu / fidelitate" (înrolare, status, istoric, oferte)
  ca acasă propriu pentru feature-urile de fidel.

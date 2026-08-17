# ADR-0043: Making the loyal experience intuitive (points chip, greeting, enrol confirmation)

- Status: Accepted
- Date: 2026-08-17

## Context (EN)
The loyalty payoff (points, rewards, history) all lived in the account screen. A
loyal customer ordering on the menu saw nothing of their standing, so the reward
loop was invisible in the flow where it matters. Enrolling also gave no
acknowledgement, and returning to the account felt anonymous. This is the cheap,
no-backend intuitiveness batch (the redemption flow is a separate, larger step).

## Decision (EN)
- **Points chip in the menu app bar** (`LoyaltyChip`), shown only to a loyal
  customer while a program is active, showing their current points; tap opens the
  account. A normal customer sees nothing (no nag, consistent with ADR-0039).
- **Greeting on the account screen**: "Bună, {name} 👋" when a loyal customer has
  set their name, so returning feels recognised.
- **Enrolment confirmation**: a welcome SnackBar when the customer enrols, so the
  action is acknowledged (the rewards card already appears on enrol).
- All View-layer, reusing the existing `loyaltyStatusProvider` (which derives from
  the `HistorySource` port). No domain change, no backend, no new endpoint.

## Alternatives rejected (EN)
- **A points banner in the ordering list.** Too heavy and repetitive; a small
  app-bar chip is glanceable and out of the way.
- **Showing the chip to everyone.** Points are the enrolment payoff; a normal
  customer would find a zero-points chip confusing, like the old enrol nag.
- **A separate motivational nudge widget.** The rewards card already shows
  "X points to {reward}"; duplicating it in the flow would be noise.

## Consequences (EN)
- The reward loop is now visible while ordering (the highest-leverage cheap win),
  and enrolment / return feel acknowledged.
- The chip shows zero on the in-app mock (no history), consistent with the rest of
  loyalty; it fills in against the real backend.
- Redemption (claiming an unlocked reward) is still the missing piece and is a
  separate feature with its own backend record.

---

## Context (RO)
Payoff-ul de fidelitate (puncte, recompense, istoric) trăia tot în ecranul de
cont. Un client fidel care comanda din meniu nu vedea nimic din statusul lui, deci
bucla de recompensă era invizibilă exact în fluxul care contează. Înscrierea nu
dădea nicio confirmare, iar revenirea în cont părea anonimă. Ăsta e lotul ieftin
de intuitivitate, fără backend (revendicarea recompensei e un pas separat, mai
mare).

## Decizie (RO)
- **Chip de puncte în bara de meniu** (`LoyaltyChip`), afișat doar clientului
  fidel cât timp un program e activ, arătând punctele curente; tap deschide
  contul. Clientul normal nu vede nimic (fără nag, consistent cu ADR-0039).
- **Salut pe ecranul de cont**: „Bună, {nume} 👋" când clientul fidel și-a setat
  numele, ca revenirea să se simtă recunoscută.
- **Confirmare la înscriere**: un SnackBar de bun-venit când clientul se înscrie,
  ca acțiunea să fie confirmată (cardul de recompense apare oricum la înscriere).
- Totul în stratul View, refolosind `loyaltyStatusProvider` (care se derivă din
  portul `HistorySource`). Fără schimbare de domeniu, fără backend, fără endpoint
  nou.

## Alternative respinse (RO)
- **Un banner de puncte în lista de comandă.** Prea greu și repetitiv; un chip mic
  în bara de sus e vizibil dintr-o privire și nu incomodează.
- **Chipul afișat tuturor.** Punctele sunt payoff-ul înscrierii; un client normal
  ar fi derutat de un chip cu zero puncte, ca vechiul nag de înscriere.
- **Un widget separat de nudge motivațional.** Cardul de recompense arată deja
  „încă X puncte pentru {recompensă}"; dublarea lui în flux ar fi zgomot.

## Consecințe (RO)
- Bucla de recompensă e acum vizibilă în timpul comenzii (câștigul ieftin cu cel
  mai mare efect), iar înscrierea / revenirea se simt confirmate.
- Chipul arată zero pe mockul in-app (fără istoric), consistent cu restul
  fidelității; se completează pe backendul real.
- Revendicarea (folosirea unei recompense deblocate) rămâne piesa lipsă și e un
  feature separat cu propria înregistrare pe backend.

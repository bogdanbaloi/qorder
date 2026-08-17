# ADR-0044: Reward redemption — spending points, with staff validation

- Status: Accepted
- Date: 2026-08-17

## Context (EN)
ADR-0041 gave a loyal customer points and a reward ladder, but reaching a tier
only showed "unlocked" with no way to actually claim the reward. Loyalty was a
promise with no payout. Claiming a reward is inherently a two-party action: the
customer spends points, and the staff hand over the beer, so there must be a way
for the staff to validate the claim without a shared identity system yet.

## Decision (EN)
- **Threshold = cost (a points economy).** Redeeming a reward spends its
  threshold in points. `computeLoyalty` now subtracts `redeemedPoints` (the cost
  of rewards already claimed) from the earned points, so the returned points are
  what is still spendable and a tier "unlocks" only when affordable now. Earn
  again to claim again.
- **Redemption recorded on the backend.** A `RedemptionStore` (port) holds each
  redemption with a short, human-readable `code`. The BFF gains create / list-for-
  customer / list-pending / consume routes. The store is separate from orders (a
  redemption is not an order, never touches the POS).
- **Two segregated client ports (Interface Segregation).** `RewardRedeemer`
  (customer: redeem + read own) and `RedemptionBoard` (staff: list pending +
  consume) are separate interfaces, one remote adapter implementing both, so
  neither role sees the other's operations.
- **The flow.** The customer taps "Folosește" on an affordable tier, gets a code,
  and shows it; the staff surface lists pending redemptions and validates the code
  (consume), which fires the same staff alert as a new order.
- **Honesty about enforcement.** The affordability check is on the client
  (`LoyaltyProgram` lives there); the BFF records what it is told. Real
  server-side enforcement waits for a customer identity/auth. Documented, not
  hidden.

## Alternatives rejected (EN)
- **Milestone rewards (unlock once, forever).** Simpler but a weaker loop and
  still needs a "claimed" record; the points economy is the standard pub model
  ("100 points = a beer") and reuses the same record.
- **A separate points ledger on the backend.** Earned points stay derived from
  orders (ADR-0041); only the spend (redemptions) is stored, so there is one
  record, not two that can disagree.
- **Auto-applying the reward to the next order.** Couples loyalty to the order
  pipeline and the POS; a code the staff validate is decoupled and works today.
- **One combined redemption interface.** Would expose staff operations to the
  customer surface and vice versa; segregation keeps each role's seam minimal.

## Consequences (EN)
- The loyalty loop is closed: earn → unlock → redeem → staff validate. The chip,
  ladder and history all read the spendable points consistently.
- Redemptions are real on the remote backend and empty on the in-app mock (which
  keeps no history), so the button never appears there.
- Client-side affordability is a demo-honest shortcut; server enforcement is a
  follow-up gated on customer identity (the same work that makes points follow a
  customer across devices).

---

## Context (RO)
ADR-0041 i-a dat clientului fidel puncte și o scară de recompense, dar atingerea
unei trepte arăta doar „deblocat", fără vreun mod de a lua efectiv recompensa.
Fidelitatea era o promisiune fără plată. Revendicarea e inerent o acțiune în doi:
clientul cheltuie puncte, iar staff-ul dă berea, deci trebuie un mod prin care
staff-ul validează revendicarea, chiar fără un sistem de identitate comun încă.

## Decizie (RO)
- **Prag = cost (o economie de puncte).** Revendicarea unei recompense cheltuie
  pragul ei în puncte. `computeLoyalty` scade acum `redeemedPoints` (costul
  recompenselor deja luate) din punctele câștigate, deci punctele întoarse sunt
  cele încă cheltuibile, iar o treaptă „se deblochează" doar când e accesibilă
  acum. Câștigi din nou ca să iei din nou.
- **Revendicare înregistrată pe backend.** Un `RedemptionStore` (port) ține
  fiecare revendicare cu un `code` scurt, ușor de citit. BFF-ul primește rute
  create / listă-client / listă-de-validat / consume. Store-ul e separat de
  comenzi (o revendicare nu e o comandă, nu atinge POS-ul).
- **Două porturi client segregate (Segregarea Interfeței).** `RewardRedeemer`
  (client: revendică + citește ale sale) și `RedemptionBoard` (staff: listă +
  consume) sunt interfețe separate, un singur adaptor remote le implementează pe
  ambele, deci niciun rol nu vede operațiile celuilalt.
- **Fluxul.** Clientul apasă „Folosește" pe o treaptă accesibilă, primește un cod
  și îl arată; ecranul de staff listează revendicările de validat și validează
  codul (consume), ceea ce declanșează aceeași alertă ca o comandă nouă.
- **Onestitate despre enforcement.** Verificarea accesibilității e pe client
  (`LoyaltyProgram` e acolo); BFF-ul înregistrează ce i se spune. Enforcement-ul
  real pe server așteaptă o identitate/autentificare de client. Documentat, nu
  ascuns.

## Alternative respinse (RO)
- **Recompense-milestone (deblocate o dată, permanent).** Mai simplu, dar buclă
  mai slabă și tot cere o înregistrare „luat"; economia de puncte e modelul
  standard de pub („100 puncte = o bere") și refolosește aceeași înregistrare.
- **Un registru de puncte separat pe backend.** Punctele câștigate rămân derivate
  din comenzi (ADR-0041); doar cheltuiala (revendicările) se stochează, deci e o
  singură înregistrare, nu două care se pot contrazice.
- **Aplicarea automată a recompensei la comanda următoare.** Cuplează fidelitatea
  de pipeline-ul de comandă și de POS; un cod validat de staff e decuplat și merge
  azi.
- **O interfață de revendicare combinată.** Ar expune operațiile de staff către
  ecranul clientului și invers; segregarea ține seam-ul fiecărui rol minimal.

## Consecințe (RO)
- Bucla de fidelitate e închisă: câștigi → deblochezi → revendici → staff
  validează. Chipul, scara și istoricul citesc consistent punctele cheltuibile.
- Revendicările sunt reale pe backendul remote și goale pe mockul in-app (care nu
  ține istoric), deci butonul nu apare acolo.
- Accesibilitatea pe client e o scurtătură onestă pentru demo; enforcement-ul pe
  server e un follow-up condiționat de identitatea clientului (aceeași muncă ce
  face punctele să urmeze clientul între dispozitive).

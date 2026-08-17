# ADR-0041: Loyalty points and reward ladder, derived from order history

- Status: Accepted
- Date: 2026-08-17

## Context (EN)
ADR-0040 gave the loyal customer an account screen with their order history, but
loyalty still had no forward pull: nothing rewarded coming back. The venue wants
points and rewards ("spend more, unlock perks"). The risk is a separate points
ledger that drifts out of sync with the real orders.

## Decision (EN)
- **Points are derived, not stored.** A pure `computeLoyalty(history, program)`
  turns the order history (which the backend already keeps) into a
  `LoyaltyStatus`: points earned (1 per whole leu spent, floored), which reward
  tiers are unlocked, the next tier, points remaining and progress toward it.
  No points table to drift; the standing is always exactly the orders.
- **The program is venue DATA.** `LoyaltyProgram` (earning rate + a `RewardTier`
  ladder) lives in `AppConfig`, like branding and access codes. Empty ladder =
  no loyalty scheme (the card hides). Reward text is venue CONTENT (like a menu
  item name), so the RO/EN toggle leaves it as the venue wrote it.
- **Same screen, same port.** The account screen's `loyaltyStatusProvider`
  derives from the existing `orderHistoryProvider` (`HistorySource` port); no new
  endpoint. A `_RewardsCard` shows points, a progress bar to the next reward and
  the ladder with locked / unlocked rows.

## Alternatives rejected (EN)
- **A points ledger on the backend.** More moving parts and a new source of
  truth that can disagree with the orders. Derivation is honest and simpler.
- **Reward labels in `AppStrings`.** They are venue content, not UI chrome; a new
  venue changes its rewards without touching the app's translations.
- **Points for non-loyal customers.** Loyalty is the enrolment payoff; points are
  shown only to a loyal customer, in their account.

## Consequences (EN)
- Points and rewards are real data on the remote backend and empty on the in-app
  mock (which keeps no history), consistent with the history tile.
- The earning rule and ladder are one config change per venue. A future
  POS-backed rule (Ebriza points) slots in behind the same `LoyaltyProgram` +
  policy, and offers/promotions can extend the same card.

---

## Context (RO)
ADR-0040 i-a dat clientului fidel un ecran de cont cu istoricul comenzilor, dar
fidelitatea tot n-avea o tracțiune înainte: nimic nu răsplătea revenirea. Localul
vrea puncte și recompense („cheltuiește mai mult, deblochezi beneficii"). Riscul e
un registru de puncte separat care se desincronizează de comenzile reale.

## Decizie (RO)
- **Punctele se derivă, nu se stochează.** O funcție pură
  `computeLoyalty(history, program)` transformă istoricul de comenzi (pe care
  backendul deja îl ține) într-un `LoyaltyStatus`: puncte (1 per leu întreg
  cheltuit, trunchiat), ce trepte sunt deblocate, treapta următoare, punctele
  rămase și progresul. Niciun tabel de puncte care să dériveze; starea e mereu
  exact comenzile.
- **Programul e DATĂ de local.** `LoyaltyProgram` (rata + o scară de
  `RewardTier`) stă în `AppConfig`, ca brandingul și codurile de acces. Scară
  goală = fără schemă de fidelitate (cardul se ascunde). Textul recompensei e
  CONȚINUT de local (ca numele unui produs), deci toggle-ul RO/EN îl lasă cum
  l-a scris localul.
- **Același ecran, același port.** `loyaltyStatusProvider` din ecranul de cont se
  derivă din `orderHistoryProvider` (portul `HistorySource`) existent; niciun
  endpoint nou. Un `_RewardsCard` arată punctele, o bară de progres spre
  recompensa următoare și scara cu rânduri blocate / deblocate.

## Alternative respinse (RO)
- **Un registru de puncte pe backend.** Mai multe piese și o nouă sursă de
  adevăr care poate contrazice comenzile. Derivarea e onestă și mai simplă.
- **Etichete de recompensă în `AppStrings`.** Sunt conținut de local, nu chrome
  de UI; un local nou își schimbă recompensele fără să atingă traducerile.
- **Puncte pentru clienții nefideli.** Fidelitatea e payoff-ul înrolării;
  punctele se arată doar clientului fidel, în contul lui.

## Consecințe (RO)
- Punctele și recompensele sunt dată reală pe backendul remote și goale pe mockul
  in-app (care nu ține istoric), consistent cu tile-ul de istoric.
- Regula de câștig și scara sunt o schimbare de config per local. O regulă
  viitoare din POS (puncte Ebriza) se adaugă în spatele aceluiași `LoyaltyProgram`
  + policy, iar ofertele/promoțiile pot extinde același card.

# ADR-0014: Order acceptance policy (waiter confirmation gate)

- Status: Accepted (waiter surface lands in a follow-up)
- Date: 2026-08-13

## Context (EN)
Some venues want a waiter to confirm an order before it reaches the bar, rather
than injecting it straight into the POS. It gives the staff a check against
mistaken or abusive orders and fits pubs where the waiter owns the table. Other
venues want the opposite: zero friction, straight through. This must be a
per-venue choice, not a fork in the code.

## Decision (EN)
Model acceptance as a config-driven **policy**. `AppConfig.acceptanceMode`
(`auto` / `waiterConfirm`) selects an `OrderAcceptancePolicy` strategy, so a new
mode is a new class, not an `if` scattered through the backend (Open/Closed).
Acceptance is a **bar-side** concern, so it is modeled as a new initial
processing stage `OrderStage.pendingAcceptance`: in waiterConfirm mode a
submitted order sits there until a waiter releases it, then runs
received -> preparing -> done as usual. The waiter capability lives behind a
**segregated** `OrderAcceptanceService` interface (`pending` + `accept`), kept
apart from the customer-side `OrderingService` (Interface Segregation), so the
customer app never depends on `accept`. Phase 0 has one in-memory backend that
implements both interfaces and shares state.

## Alternatives rejected (EN)
- **A client-side gate**: wrong layer. Acceptance is a bar decision, not the
  customer's phone.
- **A boolean flag on `OrderingService`**: bloats the customer interface with a
  waiter concern (breaks Interface Segregation).
- **A separate order state-machine field**: the status timeline already models
  progress, so an extra initial stage is enough. No new state field.

## Consequences (EN)
- The waiter surface (a `/waiter` screen) is a thin consumer of
  `OrderAcceptanceService`, added next.
- Phase 1 backs `accept` with the BFF/Ebriza. The customer app does not change.
- Default stays `auto`, so venues that want zero friction are untouched.

---

## Context (RO)
Unele localuri vor ca un ospăptar să confirme comanda înainte să ajungă la bar,
în loc să o injecteze direct în POS. Le dă personalului un control împotriva
comenzilor greșite sau abuzive și se potrivește puburilor unde ospăptarul deține
masa. Alte localuri vor exact opusul: zero fricțiune, direct. Trebuie să fie o
alegere per local, nu o ramură în cod.

## Decizie (RO)
Modelăm acceptarea ca **policy** din config. `AppConfig.acceptanceMode`
(`auto` / `waiterConfirm`) alege o strategie `OrderAcceptancePolicy`, deci un mod
nou e o clasă nouă, nu un `if` împrăștiat prin backend (Open/Closed). Acceptarea
e o treabă **de bar**, deci o modelăm ca o etapă inițială nouă
`OrderStage.pendingAcceptance`: în modul waiterConfirm o comandă trimisă stă
acolo până o eliberează un ospăptar, apoi merge received -> preparing -> done ca
de obicei. Capabilitatea de ospăptar stă în spatele unei interfețe **segregate**
`OrderAcceptanceService` (`pending` + `accept`), separată de `OrderingService`
al clientului (Interface Segregation), deci aplicația clientului nu depinde
niciodată de `accept`. Faza 0 are un singur backend în memorie care implementează
ambele interfețe și partajează starea.

## Alternative respinse (RO)
- **O poartă pe client**: strat greșit. Acceptarea e o decizie de bar, nu de
  telefonul clientului.
- **Un boolean pe `OrderingService`**: umflă interfața clientului cu o treabă de
  ospăptar (strică Interface Segregation).
- **Un câmp separat de mașină de stări**: timeline-ul de status modelează deja
  progresul, deci o etapă inițială în plus e de ajuns. Fără câmp nou de stare.

## Consecințe (RO)
- Suprafața de ospăptar (un ecran `/waiter`) e un consumator subțire al
  `OrderAcceptanceService`, adăugat imediat după.
- Faza 1 pune `accept` pe BFF/Ebriza. Aplicația clientului nu se schimbă.
- Default rămâne `auto`, deci localurile care vor zero fricțiune nu sunt atinse.

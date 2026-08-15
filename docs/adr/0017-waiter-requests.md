# ADR-0017: Table-to-waiter requests (call waiter / bring the bill)

- Status: Accepted
- Date: 2026-08-14

## Context (EN)
A table needs a way to ping the waiter without ordering: "come over" or "bring
the bill". This is a Standard-tier feature (no POS needed), so it must work on
the mock, on the BFF, and stay completely independent of Ebriza. It is not an
order and not an order-acceptance, so it should not be bolted onto those seams.

## Decision (EN)
Model a `WaiterRequest` (kind = callWaiter | bill) behind TWO segregated
interfaces, mirroring the existing `OrderingService` (customer) vs
`OrderAcceptanceService` (waiter) split:
- `WaiterCaller` (customer side): `raise(...)`.
- `WaiterRequestBoard` (waiter side): `requests(venueId)` + `resolve(id)`.
A customer widget depends only on `WaiterCaller`, the waiter surface only on
`WaiterRequestBoard` (Interface Segregation). The mock and `RemoteBackend`
implement both, selected by the same config seam as ordering (Dependency
Inversion, Open/Closed). A request is idempotent per (venue, table, kind), so a
second tap while one is still pending refreshes it instead of piling up. A new
kind (water, cutlery) is a new enum value, not a scattered `if` (Open/Closed).
On the server the requests live in their own `WaiterRequestStore` port, separate
from `OrderStore`, since a ping is neither an order nor a POS concern.

## Alternatives rejected (EN)
- **One `WaiterCallService` with call + list + resolve**: the first draft. The
  per-feature SOLID review flagged an ISP smell (a customer widget would depend
  on the waiter's read/clear ops). Split into two interfaces.
- **Reuse the order/acceptance path**: a request is not an order, it never
  touches the POS. Overloading `submitOrder` would blur the seam.
- **Model it as a notification only**: the waiter must see and CLEAR it, so it
  needs a small stored state, not a fire-and-forget event.

## Consequences (EN)
- Customer menu shows a "call waiter / bring the bill" action; the waiter surface
  lists requests and resolves them, on the same 2s poll as pending orders.
- Independent of the POS, so it ships in the Standard tier before Ebriza.
- Staff alert included: the waiter surface buzzes and plays the system sound
  (`AlertSignal` behind a provider, `DeviceAlertSignal` impl) when the count of
  things needing the waiter grows, so staff are not tied to the screen. The
  trigger is a derived count provider plus a `ref.listen`, kept out of the
  widget tree so it is testable with a fake signal. Follow-up: a richer web-
  audio signal that survives the browser's autoplay gate.

---

## Context (RO)
O masă are nevoie să cheme ospătarul fără să comande: "vino la masă" sau "adu
nota". E o funcție de nivel Standard (fără POS), deci trebuie să meargă pe mock,
pe BFF și să rămână complet independentă de Ebriza. Nu e o comandă și nu e o
acceptare de comandă, deci nu se lipește pe cusăturile alea.

## Decizie (RO)
Modelăm un `WaiterRequest` (kind = callWaiter | bill) în spatele a DOUĂ interfețe
segregate, oglindind split-ul existent `OrderingService` (client) vs
`OrderAcceptanceService` (ospătar):
- `WaiterCaller` (client): `raise(...)`.
- `WaiterRequestBoard` (ospătar): `requests(venueId)` + `resolve(id)`.
Un widget de client depinde doar de `WaiterCaller`, suprafața de ospătar doar de
`WaiterRequestBoard` (Interface Segregation). Mock-ul și `RemoteBackend` le
implementează pe ambele, alese de aceeași cusătură de config ca ordering
(Dependency Inversion, Open/Closed). O cerere e idempotentă per (venue, masă,
kind), deci a doua apăsare cât una e încă în așteptare o reîmprospătează, nu o
adună. Un tip nou (apă, tacâmuri) e o valoare nouă în enum, nu un `if` împrăștiat
(Open/Closed). Pe server, cererile stau în propriul port `WaiterRequestStore`,
separat de `OrderStore`, fiindcă un ping nu e nici comandă, nici treabă de POS.

## Alternative respinse (RO)
- **O singură `WaiterCallService` cu call + list + resolve**: prima variantă.
  Review-ul SOLID de feature a semnalat un miros de ISP (un widget de client ar
  depinde de operațiile de citire/curățare ale ospătarului). Am despărțit-o în
  două interfețe.
- **Refolosirea drumului de comandă/acceptare**: o cerere nu e o comandă, nu
  atinge POS-ul. Suprapunerea peste `submitOrder` ar încețoșa cusătura.
- **Doar o notificare**: ospătarul trebuie s-o vadă și s-o ȘTEARGĂ, deci are
  nevoie de o stare mică stocată, nu de un eveniment trimis și uitat.

## Consecințe (RO)
- Meniul clientului are o acțiune "cheamă ospătarul / adu nota"; suprafața de
  ospătar listează cererile și le rezolvă, pe același poll de 2s ca la comenzi.
- Independent de POS, deci intră în nivelul Standard înainte de Ebriza.
- Alertă pentru personal inclusă: suprafața de ospătar vibrează și redă sunetul
  de sistem (`AlertSignal` în spatele unui provider, impl `DeviceAlertSignal`)
  când crește numărul de lucruri de rezolvat, ca personalul să nu stea cu ochii
  pe ecran. Declanșarea e un provider derivat de numărare plus un `ref.listen`,
  ținut în afara arborelui de widget-uri, deci testabil cu un semnal fals. De
  urmat: un semnal web-audio mai bun, care trece de blocajul de autoplay.

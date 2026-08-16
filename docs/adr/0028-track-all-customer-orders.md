# ADR-0028: Track the live status of every order, not only the last

- Status: Accepted
- Date: 2026-08-16

## Context (EN)
The customer only saw the status of their most recent order: the submit
controller watched one order's status stream and the cart showed a single
stepper, reset by "new order". A guest who orders a round, then another, could
not tell where each stood.

## Decision (EN)
An `OrderTracker` (a `Notifier<List<TrackedOrder>>`) keeps the customer's placed
orders and watches EACH one's status stream (`OrderingService.watchOrder`),
updating that order's stage as the backend reports it. On a confirmed submit the
order controller calls `track(serverOrderId, sequence)` instead of watching a
single order. `track` is idempotent per order id, so a resend cannot duplicate.
The cart shows a "my orders" section: one row per order with its number and a
status stepper, live. The single-order stage was removed from the submit
controller.

The status still comes from the backend (single source of truth); the tracker
only fans the existing per-order stream out to many orders. The tracker depends
on the `OrderingService` interface, so it is unit-tested with a fake that emits
stages on demand.

## Alternatives rejected (EN)
- **Keep only the last order's status.** The original limitation, unintuitive
  once a table places more than one order.
- **A new backend "orders on this table with status" query.** Cleaner for
  cross-device and restart survival, but a bigger change (service method plus BFF
  plus mock plus remote). Deferred: the client-side fan-out reuses the existing
  `watchOrder` with no backend change and is a strict improvement.
- **Show the list on the menu too.** Kept it on the cart for now, where order
  status already lived.

## Consequences (EN)
- Every order the customer placed shows its own live status.
- In-session like before (a restart forgets them). Follow-up: a backend query for
  the customer's orders on the table, for restart and cross-device survival, and a
  single poll instead of one stream per order on the remote backend.

---

## Context (RO)
Clientul vedea doar statusul ultimei comenzi: controllerul de trimitere urmărea
stream-ul de status al unei singure comenzi, iar coșul arăta un singur steper,
resetat de „comandă nouă". Un client care comandă un rând, apoi altul, nu putea
spune unde e fiecare.

## Decizie (RO)
Un `OrderTracker` (un `Notifier<List<TrackedOrder>>`) ține comenzile plasate de
client și urmărește stream-ul de status al FIECĂREIA
(`OrderingService.watchOrder`), actualizând stage-ul pe măsură ce raportează
backend-ul. La o trimitere confirmată, controllerul de comandă cheamă
`track(serverOrderId, sequence)` în loc să urmărească o singură comandă. `track`
e idempotent pe id de comandă, deci un resend nu poate duplica. Coșul arată o
secțiune „Comenzile mele": un rând per comandă cu numărul ei și un steper de
status, live. Stage-ul pentru o singură comandă a fost scos din controllerul de
trimitere.

Statusul vine tot din backend (sursă unică de adevăr); tracker-ul doar
multiplică stream-ul existent per-comandă la mai multe comenzi. Tracker-ul
depinde de interfața `OrderingService`, deci e testat unitar cu un fake care
emite stage-uri la cerere.

## Alternative respinse (RO)
- **Păstrarea doar a statusului ultimei comenzi.** Limitarea originală,
  neintuitivă odată ce o masă plasează mai mult de o comandă.
- **Un query nou de backend „comenzile de pe masă cu status".** Mai curat pentru
  cross-device și supraviețuire la repornire, dar o schimbare mai mare (metodă de
  serviciu plus BFF plus mock plus remote). Amânat: fan-out-ul pe client
  refolosește `watchOrder` fără schimbare de backend și e o îmbunătățire clară.
- **Afișarea listei și pe meniu.** Ținută pe coș deocamdată, unde statusul
  comenzii stătea deja.

## Consecințe (RO)
- Fiecare comandă plasată de client își arată statusul live.
- În sesiune ca înainte (o repornire le uită). De urmat: un query de backend
  pentru comenzile clientului pe masă, pentru supraviețuire la repornire și
  cross-device, plus un singur poll în loc de un stream per comandă pe remote.

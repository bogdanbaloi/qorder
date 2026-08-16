# ADR-0023: Waiter surface clarity (counts + waiting time)

- Status: Accepted
- Date: 2026-08-16

## Context (EN)
When it is busy the waiter needs to gauge load and urgency in a glance: how many
things wait, and how long each has waited. A flat list of tiles hides both.

## Decision (EN)
Each section header shows its count ("Cereri (2)", "Comenzi noi (3)", "În lucru
(1)"). Each item shows how long it has waited ("de 12s"). This needed a
`createdAtMs` on `AwaitingOrder` (0 when unknown), populated by the mock at
submit and by the BFF from the order's 'submitted' stamp. Requests already
carried `createdAtMs`. The waiting-time formatting reuses the same helper as the
timings feature.

## Alternatives rejected (EN)
- **No counts / no times**: the waiter cannot tell a light moment from a slammed
  one, nor which order has been ignored longest.
- **A separate analytics dashboard**: that is the owner's Pro panel, not the live
  waiter surface. Here it must be at-a-glance, inline.

## Consequences (EN)
- The waiter sees the load per section and the oldest-waiting items at a glance.
- Follow-up: a "nou" highlight for just-arrived items, colour by how long it has
  waited (green to red).

---

## Context (RO)
Când e aglomerat, ospătarul trebuie să prindă dintr-o privire încărcarea și
urgența: câte lucruri așteaptă și de cât timp fiecare. O listă plată de rânduri
le ascunde pe amândouă.

## Decizie (RO)
Fiecare antet de secțiune arată numărul ("Cereri (2)", "Comenzi noi (3)", "În
lucru (1)"). Fiecare rând arată de cât timp așteaptă ("de 12s"). Asta a cerut un
`createdAtMs` pe `AwaitingOrder` (0 când e necunoscut), pus de mock la trimitere
și de BFF din ștampila 'submitted' a comenzii. Cererile aveau deja `createdAtMs`.
Formatarea timpului refolosește același helper ca la feature-ul de timpi.

## Alternative respinse (RO)
- **Fără numere / fără timpi**: ospătarul nu distinge un moment lejer de unul
  sufocat, nici care comandă a fost ignorată cel mai mult.
- **Un panou separat de statistici**: ăla e panoul Pro al patronului, nu
  suprafața live a ospătarului. Aici trebuie să fie dintr-o privire, inline.

## Consecințe (RO)
- Ospătarul vede încărcarea pe secțiune și rândurile care așteaptă de cel mai
  mult, dintr-o privire.
- De urmat: o evidențiere „nou" pentru rândurile abia sosite, culoare după cât de
  mult a așteptat (verde spre roșu).

# ADR-0018: Order timings (acceptance + delivery gap)

- Status: Accepted
- Date: 2026-08-14

## Context (EN)
The owner wants two service metrics: how fast the waiter picks an order up
(acceptance), and how long a ready drink waits before it reaches the table
(delivery). His sharp point: a naive "delivery time" from submit conflates the
bar's prep time with the waiter's availability. The metric that matters is the
gap from READY to at-the-table, isolated. This is POS-independent, we own the
events.

## Decision (EN)
Record operational timestamps on the order server-side, keyed by event:
'submitted', 'accepted', 'ready', 'delivered'. A pure `OrderTimings` value
object computes the durations (acceptance = accepted - submitted, delivery =
delivered - ready), so the math is unit-tested with fixed inputs. Two new waiter
events, "Gata" (ready) and "Livrat" (delivered), stamp the last two, behind an
`OrderProgress` interface (in-progress list + markReady + markDelivered),
segregated from `OrderAcceptanceService` (Interface Segregation). The waiter
surface gains an "În lucru" section that shows the acceptance time and, once
ready, how long the drink has been waiting, then the Gata / Livrat actions. The
mock, `RemoteBackend` and the BFF all fulfil the interface.

## Alternatives rejected (EN)
- **Measure submit to delivered as one number**: conflates bar slowness with
  waiter slowness. The owner explicitly wants the ready-to-table gap isolated.
- **Add stages to the `OrderStage` enum**: the timestamps are a side-channel for
  metrics, not customer-facing states. Extending the enum would ripple through
  every switch for no user benefit. Stamps stay separate.
- **Auto-advance timers (Phase 0 demo)**: those are simulated, not real events.
  A real gap needs an explicit ready and delivered tap.

## Consequences (EN)
- The waiter drives Gata then Livrat; acceptance and time-since-ready are visible
  live. The delivery gap is captured for the future owner analytics panel (Pro).
- In the no-POS tier, "ready" and "delivered" are manual taps. With a bar / POS
  integration later, "ready" can arrive automatically. Without the taps, the
  delivery duration is simply null (honest, no guessed data).
- A differentiator: nobody else measures the ready-to-table gap.

---

## Context (RO)
Patronul vrea două metrici de serviciu: cât de repede ia ospătarul o comandă
(acceptare) și cât stă o băutură gata până ajunge la masă (livrare). Observația
lui fină: un „timp de livrare" naiv, de la trimitere, amestecă timpul de
preparare al barului cu disponibilitatea ospătarului. Ce contează e golul de la
GATA până la masă, izolat. E independent de POS, evenimentele sunt ale noastre.

## Decizie (RO)
Ștampilăm timpi operaționali pe comandă, pe server, pe eveniment: 'submitted',
'accepted', 'ready', 'delivered'. Un obiect-valoare pur `OrderTimings` calculează
duratele (acceptare = accepted - submitted, livrare = delivered - ready), deci
calculul e testat unitar cu intrări fixe. Două evenimente noi de ospătar, „Gata"
și „Livrat", ștampilează ultimele două, în spatele unei interfețe `OrderProgress`
(lista în-lucru + markReady + markDelivered), segregată de
`OrderAcceptanceService` (Interface Segregation). Suprafața de ospătar capătă o
secțiune „În lucru" care arată timpul de acceptare și, odată gata, de cât timp
așteaptă băutura, plus acțiunile Gata / Livrat. Mock-ul, `RemoteBackend` și
BFF-ul îndeplinesc toate interfața.

## Alternative respinse (RO)
- **Un singur număr de la trimitere la livrat**: amestecă lentoarea barului cu a
  ospătarului. Patronul vrea explicit golul gata-la-masă izolat.
- **Stadii noi în enum-ul `OrderStage`**: ștampilele sunt un canal lateral pentru
  metrici, nu stări pentru client. Extinderea enum-ului s-ar propaga în fiecare
  switch fără vreun beneficiu pentru utilizator. Ștampilele rămân separate.
- **Timere de avans automat (demo Faza 0)**: alea sunt simulate, nu evenimente
  reale. Un gol real cere o apăsare explicită de gata și livrat.

## Consecințe (RO)
- Ospătarul apasă Gata apoi Livrat; acceptarea și de-cât-timp-e-gata se văd live.
  Golul de livrare e captat pentru viitorul panou de statistici al patronului
  (Pro).
- În nivelul fără POS, „gata" și „livrat" sunt apăsări manuale. Cu o integrare
  bar / POS mai târziu, „gata" poate veni automat. Fără apăsări, durata de
  livrare e pur și simplu null (onest, fără date ghicite).
- Un diferențiator: nimeni altcineva nu măsoară golul gata-la-masă.

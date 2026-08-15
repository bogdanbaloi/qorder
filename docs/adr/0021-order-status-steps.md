# ADR-0021: Order status as visual steps

- Status: Accepted
- Date: 2026-08-16

## Context (EN)
After submitting, the customer saw one line of status text. It is easy to miss
and hard to read at a glance in a loud pub. People understand a progress track
faster than a sentence.

## Decision (EN)
Render the order lifecycle as a compact horizontal stepper: finished steps show
a check, the current step is highlighted, future steps are greyed. The ORDERED
list of stages and the current-step lookup live in the domain
(`orderStepStages` + `orderStepIndex`), a pure function unit-tested without the
UI. The widget maps each stage to a short label and icon and draws the row.

## Alternatives rejected (EN)
- **Keep the single status line**: less scannable, easy to miss the change.
- **Flutter's `Stepper` widget**: vertical and heavy, wrong shape for a compact
  status strip at the bottom of the cart.
- **Put the ordering + index logic in the widget**: not unit-testable. The
  sequence is domain knowledge, so it lives on the model.

## Consequences (EN)
- The customer sees where the order is at a glance: Așteaptă, Preluată, În
  pregătire, Gata.
- Auto-mode orders (no waiter step) simply start further along the same track.
- Follow-up: a subtle animation on the step change, an ETA hint.

---

## Context (RO)
După ce trimitea, clientul vedea un singur rând de text cu statusul. E ușor de
ratat și greu de citit dintr-o privire într-un pub gălăgios. Oamenii înțeleg o
bară de progres mai repede decât o propoziție.

## Decizie (RO)
Randăm ciclul de viață al comenzii ca un stepper orizontal compact: pașii
terminați au o bifă, pasul curent e evidențiat, cei viitori sunt estompați.
Lista ORDONATĂ de stadii și găsirea pasului curent stau în domeniu
(`orderStepStages` + `orderStepIndex`), o funcție pură testată unitar fără UI.
Widget-ul mapează fiecare stadiu la o etichetă scurtă și o iconiță și desenează
rândul.

## Alternative respinse (RO)
- **Păstrarea rândului unic de status**: mai greu de scanat, ușor de ratat
  schimbarea.
- **Widget-ul `Stepper` din Flutter**: vertical și greoi, formă greșită pentru o
  bandă compactă de status jos în coș.
- **Logica de ordine + index în widget**: netestabilă unitar. Secvența e
  cunoaștere de domeniu, deci stă pe model.

## Consecințe (RO)
- Clientul vede dintr-o privire unde e comanda: Așteaptă, Preluată, În pregătire,
  Gata.
- Comenzile pe mod auto (fără pas de ospătar) pornesc pur și simplu mai departe
  pe aceeași bandă.
- De urmat: o animație subtilă la schimbarea pasului, o estimare de timp.

# ADR-0010: Order lifecycle + server-owned status

- Status: Accepted
- Date: 2026-08-12

## Context (EN)
Processing takes real time and the customer must see honest progress. State must
survive the app closing and reopening.

## Decision (EN)
Order state machine: `draft -> submitting -> submitted(confirmed) | failed`, plus
processing stages `received -> preparing -> done`. Status is **owned by the server**
and pushed back from Ebriza (`BillStatusEntry` + WebHooks). The app re-syncs on
reopen. The UI never assumes "instant done".

## Alternatives rejected (EN)
- **Optimistic silent success**: shows "done" before the bar confirms.
- **Client-owned status**: lost when the app closes.

## Consequences (EN)
- The mock streams the stages with delays so the progress UI exists from Phase 0.

---

## Context (RO)
Procesarea durează timp real și clientul trebuie să vadă un progres onest. Starea
trebuie să supraviețuiască închiderii și redeschiderii aplicației.

## Decizie (RO)
Mașina de stări: `draft -> submitting -> submitted(confirmat) | failed`, plus
etapele de procesare `received -> preparing -> done`. Statusul e **deținut de
server** și împins înapoi de Ebriza (`BillStatusEntry` + WebHooks). Aplicația se
resincronizează la redeschidere. UI-ul nu presupune niciodată "gata instant".

## Alternative respinse (RO)
- **Succes optimist tăcut**: arată "gata" înainte ca barul să confirme.
- **Status deținut de client**: se pierde când se închide aplicația.

## Consecințe (RO)
- Mock-ul emite etapele cu întârzieri, deci UI-ul de progres există din Faza 0.

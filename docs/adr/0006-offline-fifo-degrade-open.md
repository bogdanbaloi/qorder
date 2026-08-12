# ADR-0006: Offline outbox, FIFO, degrade-open

- Status: Accepted (design; mock demonstrates it in Phase 0)
- Date: 2026-08-12

## Context (EN)
A submitted order must never be silently dropped. Bad signal in the pub is real.
Orders should be processed first-in-first-out.

## Decision (EN)
- **Degrade-open**: a failed submit enters a client **outbox** and retries
  automatically (bounded); if it still fails it is marked clearly failed, never a
  false success. Menu load failure serves the last cache with a "may be outdated"
  banner.
- **FIFO**: the authoritative order is a **monotonic sequence assigned at a single
  serialization point** (our BFF). The client outbox is a FIFO queue.
- **No global head-of-line blocking**: a single stuck order does not freeze other
  customers; it retries and lands later. Order is strict within one customer.

## Alternatives rejected (EN)
- **Fire-and-forget submit**: can silently drop an order.
- **Strict global FIFO with head-of-line blocking**: one bad-signal table would
  freeze the whole bar.
- **Full offline-first sync engine**: over-engineering for this app.

## Consequences (EN)
- The mock assigns a monotonic sequence and streams timed status so the outbox
  and progress UI are exercised from Phase 0.

---

## Context (RO)
O comandă trimisă nu trebuie pierdută niciodată în tăcere. Semnalul prost în pub
e real. Comenzile se procesează în ordinea sosirii (FIFO).

## Decizie (RO)
- **Degrade-open**: un submit eșuat intră într-un **outbox** pe client și se
  reia automat (mărginit); dacă tot nu merge, e marcat clar eșuat, niciodată un
  fals succes. Eșecul de meniu servește ultimul cache cu un banner "poate fi vechi".
- **FIFO**: ordinea autoritară e o **secvență monotonă atribuită într-un singur
  punct de serializare** (BFF-ul nostru). Outbox-ul clientului e o coadă FIFO.
- **Fără blocaj global (head-of-line)**: o comandă blocată nu îngheață ceilalți
  clienți; se reia și intră mai târziu. Ordinea e strictă în cadrul unui client.

## Alternative respinse (RO)
- **Submit "trimite și uită"**: poate pierde o comandă în tăcere.
- **FIFO global strict cu head-of-line blocking**: o masă cu semnal prost ar
  îngheța tot barul.
- **Motor complet offline-first**: over-engineering pentru aplicația asta.

## Consecințe (RO)
- Mock-ul atribuie o secvență monotonă și emite status în timp, deci outbox-ul și
  UI-ul de progres sunt exersate din Faza 0.

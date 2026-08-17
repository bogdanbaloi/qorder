# ADR-0036: Real owner metrics (revenue + daily history) from the BFF

- Status: Accepted
- Date: 2026-08-16

## Context (EN)
The owner dashboard showed a live snapshot derived client-side. The owner also
wants real numbers: revenue, orders today, and a daily history. That needs the
backend, which already keeps every order (it does not drop delivered ones).

## Decision (EN)
- **The BFF computes it.** The client already sends `totalMinor` at submit, so
  the BFF now stores it on the order. A pure `computeMetrics(orders, nowMs)`
  aggregates: today's order count and revenue, the average acceptance and
  delivery times from the stamps, and a per-day series bucketed by the submitted
  day. A `GET /venues/:id/metrics` endpoint returns it.
- **A `MetricsSource` port.** The app reads it through an interface: a
  `RemoteMetricsSource` over the BFF endpoint (degrading to empty on any error),
  and a `MockMetricsSource` that returns empty since the in-app mock keeps no
  history. `metricsSourceProvider` picks one from config, like the other backends.
- **Dashboard.** An "Azi" section (orders, revenue, average times) and a
  hand-drawn daily revenue bar chart, above the live "Acum" snapshot.

## Alternatives rejected (EN)
- **Parse the line snapshots on the BFF for revenue.** The client already knows
  the total, so sending it is simpler and keeps the BFF from depending on the line
  shape.
- **A chart library.** A few bars need no dependency; a `Row` of `Container`
  heights is enough and stays theme-aware.
- **Compute revenue client-side.** The client only sees its own table, not the
  venue's history. The backend is the only honest source.

## Consequences (EN)
- The owner sees real revenue and a daily trend, from the backend that keeps the
  orders.
- The in-app mock reports empty metrics (no persisted history); the demo runs
  against the BFF.
- Follow-up: average order value and day-over-day comparison, sales by hour, and
  top products (line-level aggregation), then real Ebriza-backed data.

---

## Context (RO)
Dashboard-ul patronului arăta un snapshot live derivat pe client. Patronul vrea și
cifre reale: încasări, comenzi azi și un istoric zilnic. Asta cere backend-ul,
care oricum păstrează fiecare comandă (nu le aruncă pe cele livrate).

## Decizie (RO)
- **BFF-ul le calculează.** Clientul trimite deja `totalMinor` la submit, deci
  BFF-ul îl stochează acum pe comandă. Un `computeMetrics(orders, nowMs)` pur
  agregă: numărul și încasările de azi, timpii medii de preluare și livrare din
  ștampile și o serie pe zi grupată după ziua de submit. Un endpoint
  `GET /venues/:id/metrics` le întoarce.
- **Un port `MetricsSource`.** Aplicația le citește printr-o interfață: un
  `RemoteMetricsSource` peste endpoint-ul BFF (degradează la gol la orice eroare)
  și un `MockMetricsSource` care întoarce gol, fiindcă mock-ul din app nu ține
  istoric. `metricsSourceProvider` alege unul din config, ca la celelalte backend-uri.
- **Dashboard.** O secțiune „Azi" (comenzi, încasări, timpi medii) și un grafic cu
  bare de încasări zilnice desenat de mână, peste snapshot-ul live „Acum".

## Alternative respinse (RO)
- **Parsarea liniilor pe BFF pentru încasări.** Clientul știe deja totalul, deci
  trimiterea lui e mai simplă și ține BFF-ul independent de forma liniilor.
- **O librărie de grafice.** Câteva bare nu cer dependență; un `Row` de
  `Container`-e cu înălțimi e destul și rămâne pe temă.
- **Calculul încasărilor pe client.** Clientul vede doar masa lui, nu istoricul
  localului. Backend-ul e singura sursă onestă.

## Consecințe (RO)
- Patronul vede încasări reale și un trend zilnic, din backend-ul care ține
  comenzile.
- Mock-ul din app raportează metrici goale (fără istoric persistat); demo-ul rulează
  pe BFF.
- De urmat: valoarea medie a comenzii și comparația zi-cu-zi, vânzări pe oră și
  top produse (agregare pe linii), apoi date reale via Ebriza.

# ADR-0042: Richer owner dashboard (average value, day-over-day, hourly, top products)

- Status: Accepted
- Date: 2026-08-17

## Context (EN)
The owner dashboard (ADR-0035, ADR-0036) showed today's orders + revenue, the
average acceptance / delivery times and a daily revenue chart. The owner asked
for sharper trading insight: the average order value, how today moves against the
day before, when in the day sales happen, and which products sell. Some of this
is already implied by the data on hand; some needs a new aggregation.

## Decision (EN)
- **Derived on the client where the data already exists.** `averageOrderValue`
  (revenue / orders, integer bani) and `dayOverDay` (the latest recorded day vs
  the previous one: orders + revenue delta, and a percent when the previous day
  had revenue) are pure functions over the existing `SalesMetrics`. No backend
  change, no new source of truth.
- **Aggregated on the backend where it does not.** `computeMetrics` gains
  `hourly` (today's orders bucketed by the hour of the 'submitted' stamp, active
  hours only) and `topProducts` (units sold per product name across all orders,
  ranked, top five). Both are pure and unit-tested on the BFF.
- **Top products rank by UNITS, not revenue.** The submitted line snapshot is
  `{name, qty}` with no per-line price, so ranking by revenue would be invented.
  Units sold is the honest ranking from the data we actually keep.
- **One bar-chart widget, reused.** The daily chart is generalised to a
  `_BarChart` over `(label, value)` bars, so the new hourly chart reuses it
  instead of a second hand-drawn chart (DRY).

## Alternatives rejected (EN)
- **Compute the averages / deltas on the backend too.** They are exact functions
  of numbers the client already has; deriving them keeps the endpoint lean and
  the logic unit-tested without a server.
- **Rank top products by revenue.** Not derivable from the line snapshot; it
  would require carrying per-line prices the client does not send today.
- **A charting package.** The hand-drawn bars are tiny, dependency-free and
  already proven for the daily chart.

## Consequences (EN)
- Hourly and top-products data are real on the remote backend and empty on the
  in-app mock (which keeps no history), so the dashboard degrades cleanly.
- If revenue-ranked top products are wanted later, the client must send per-line
  prices and the BFF sum them; the field shape stays the same.
- The reused `_BarChart` makes a third breakdown (e.g. by weekday) a one-line
  add.

---

## Context (RO)
Dashboardul patronului (ADR-0035, ADR-0036) arăta comenzile + încasările de azi,
timpii medii de acceptare / livrare și un grafic zilnic de încasări. Patronul a
cerut o perspectivă mai fină: valoarea medie a comenzii, cum se mișcă ziua de azi
față de cea precedentă, când în zi se comandă și ce produse se vând. O parte e
deja implicată de datele existente; o parte cere o agregare nouă.

## Decizie (RO)
- **Derivat pe client acolo unde datele există deja.** `averageOrderValue`
  (încasări / comenzi, bani întregi) și `dayOverDay` (ultima zi înregistrată vs
  cea precedentă: delta comenzi + încasări, și un procent când ziua precedentă a
  avut încasări) sunt funcții pure peste `SalesMetrics`-ul existent. Fără
  schimbare de backend, fără o nouă sursă de adevăr.
- **Agregat pe backend acolo unde nu există.** `computeMetrics` primește
  `hourly` (comenzile de azi grupate pe ora stampilei 'submitted', doar orele
  active) și `topProducts` (bucăți vândute per nume de produs peste toate
  comenzile, clasate, primele cinci). Ambele pure și testate unitar pe BFF.
- **Top produse clasate după BUCĂȚI, nu încasări.** Snapshotul liniei trimise e
  `{name, qty}`, fără preț pe linie, deci clasarea după încasări ar fi inventată.
  Bucățile vândute sunt clasarea onestă din datele pe care le ținem.
- **Un singur widget de grafic, reutilizat.** Graficul zilnic e generalizat într-un
  `_BarChart` peste bare `(label, value)`, deci graficul orar îl refolosește în
  loc de un al doilea grafic desenat de mână (DRY).

## Alternative respinse (RO)
- **Calculul mediilor / deltelor tot pe backend.** Sunt funcții exacte de numere
  pe care clientul le are deja; derivarea ține endpointul suplu și logica testată
  fără server.
- **Clasarea top produse după încasări.** Nederivabilă din snapshotul liniei; ar
  cere prețuri pe linie pe care clientul nu le trimite azi.
- **Un pachet de charting.** Barele desenate de mână sunt mici, fără dependințe și
  deja dovedite pe graficul zilnic.

## Consecințe (RO)
- Datele orare și top-produse sunt reale pe backendul remote și goale pe mockul
  in-app (care nu ține istoric), deci dashboardul degradează curat.
- Dacă se vor top produse clasate după încasări mai târziu, clientul trebuie să
  trimită prețuri pe linie și BFF-ul să le sumeze; forma câmpului rămâne aceeași.
- `_BarChart` reutilizat face o a treia defalcare (ex. pe zi a săptămânii) un adaos
  de o linie.

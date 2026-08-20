# ADR-0057: Operator metrics (cross-venue evidence)

- Status: Accepted
- Date: 2026-08-21

## Context (EN)
With every store on durable Postgres, we can finally answer the operator question:
how many venues are active and how much usage each has. This is the OPERATOR
plane (our own evidence), distinct from the per-venue owner dashboard. It is a
query, not AI agents.

## Decision (EN)
- **A `PlatformMetricsStore` port.** One method, `snapshot()`, returning venues
  and their usage across the whole platform. Postgres aggregates from the orders
  table (order count and distinct client ids per venue). An empty implementation
  is used with no database, since operator evidence needs durable cross-venue data.
- **A single operator endpoint.** `GET /platform/metrics`, gated by an operator
  bearer token from `QORDER_OPERATOR_TOKEN`. With no token configured the route is
  off (403), so the surface is opt-in. It is platform-level, not per-venue like the
  staff and owner tokens.
- **No UI yet.** The endpoint returns JSON. An admin page comes later. This ships
  the evidence first, per the onboarding note (a report or CLI is enough to start).
- **Active venues, from data.** venueCount is the venues that have order activity.
  Configured-but-inactive venues would come from the venue registry later.

## Alternatives rejected (EN)
- **AI agents for the counts.** Counting venues and users is a `GROUP BY`. AI adds
  cost and nondeterminism for something a query does.
- **Reuse the per-venue staff/owner token.** Those are scoped to one venue. The
  operator view is cross-venue, so it needs its own platform-level gate.
- **Build the admin UI now.** The value is the evidence. Shipping the endpoint
  first lets the UI follow when it is worth it.

## Consequences (EN)
- The operator can read venues plus usage over the durable data. This closes the
  loop the persistence track opened.
- Follow-ups: a true signed-in user count (join customers), configured-but-inactive
  venues from the registry, an operator identity or RBAC beyond one token, plus an
  admin UI.

---

## Context (RO)
Cu fiecare store pe Postgres durabil, putem în sfârșit răspunde la întrebarea de
operator: câte localuri sunt active și cât de mult folosite. E planul OPERATOR
(evidența noastră), distinct de dashboard-ul de patron per-local. E o interogare,
nu agenți AI.

## Decizie (RO)
- **Un port `PlatformMetricsStore`.** O metodă, `snapshot()`, care întoarce
  localurile și folosirea lor pe toată platforma. Postgres agregă din tabelul de
  comenzi (număr de comenzi și client id-uri distincte per local). O implementare
  goală se folosește fără bază de date, fiindcă evidența de operator are nevoie de
  date durabile cross-venue.
- **Un singur endpoint de operator.** `GET /platform/metrics`, gated cu un token de
  operator din `QORDER_OPERATOR_TOKEN`. Fără token configurat, ruta e oprită (403),
  deci suprafața e opt-in. E la nivel de platformă, nu per-local ca token-urile de
  staff și patron.
- **Fără UI încă.** Endpoint-ul întoarce JSON. O pagină de admin vine mai târziu.
  Asta livrează evidența întâi, conform notei de onboarding (un raport sau CLI
  ajunge la început).
- **Localuri active, din date.** venueCount sunt localurile cu activitate de
  comenzi. Localurile configurate-dar-inactive ar veni din registrul de localuri.

## Alternative respinse (RO)
- **Agenți AI pentru numărători.** Numărarea localurilor și utilizatorilor e un
  `GROUP BY`. AI adaugă cost și nedeterminism pentru ceva ce o interogare face.
- **Refolosirea token-ului de staff/patron per-local.** Acelea-s scoped pe un
  local. Vederea de operator e cross-venue, deci cere gate-ul ei la nivel de
  platformă.
- **Construirea UI-ului de admin acum.** Valoarea e evidența. Livrarea endpoint-ului
  întâi lasă UI-ul să urmeze când merită.

## Consecințe (RO)
- Operatorul poate citi localuri plus folosire peste datele durabile. Asta închide
  bucla deschisă de track-ul de persistență.
- De urmat: o numărătoare reală de utilizatori logați (join la customers),
  localurile configurate-dar-inactive din registru, o identitate sau RBAC de
  operator dincolo de un token, plus un UI de admin.

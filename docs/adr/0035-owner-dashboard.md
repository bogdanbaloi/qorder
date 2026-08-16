# ADR-0035: Owner dashboard (live snapshot) and a generalized role guard

- Status: Accepted
- Date: 2026-08-16

## Context (EN)
With the identity seam in place, the owner needs a surface of their own: a view
of how the venue is running, especially the delivery time (ready-to-table), the
metric they cared about. And the staff guard should generalize, since the owner
surface needs the same gate with a different code.

## Decision (EN)
- **Live snapshot, no new backend.** A pure `VenueMetrics` +
  `computeVenueMetrics` derives the numbers from the data the waiter surface
  already exposes: pending count, in-progress count, open requests, and the
  average acceptance and delivery times from the in-progress orders' stamps.
  `venueMetricsProvider` composes the existing waiter providers, so the dashboard
  is a read-only view with no new endpoint. Revenue and daily history come later,
  when the backend persists past orders.
- **Owner dashboard.** An `/owner` surface with metric cards, polling like the
  waiter surface, plus a logout.
- **Generalized guard.** The `StaffGuard` became a `RoleGuard(role:)`: it gates
  any surface behind a role, reading the matching config code (staff or owner).
  Adding a role-gated surface is now just a route.

## Alternatives rejected (EN)
- **A backend metrics endpoint now.** Cleaner for revenue and history, but a
  bigger change (BFF + mock + remote). The derived live snapshot is honest and
  useful today; the endpoint is the follow-up for history.
- **A separate owner guard.** It would duplicate the staff gate. One `RoleGuard`
  parameterised by role keeps it DRY and scales to more roles.
- **Showing a fake revenue number.** Better to omit what we cannot compute than to
  invent it.

## Consequences (EN)
- The owner sees the live load and the acceptance / delivery averages, behind
  their own code.
- Any future role-gated surface reuses `RoleGuard`.
- Follow-up: a backend metrics endpoint for revenue and daily / historical charts,
  and real owner auth (Ebriza).

---

## Context (RO)
Cu seam-ul de identitate pus, patronul are nevoie de o suprafață a lui: o vedere a
cum merge localul, mai ales timpul de livrare (gata-la-masă), metrica de care îi
păsa. Iar guard-ul de staff ar trebui generalizat, fiindcă suprafața patronului
cere aceeași poartă cu alt cod.

## Decizie (RO)
- **Snapshot live, fără backend nou.** Un `VenueMetrics` pur +
  `computeVenueMetrics` derivă cifrele din datele pe care suprafața ospătarului le
  expune deja: câte așteaptă, câte-s în lucru, cereri deschise și timpii medii de
  preluare și livrare din ștampilele comenzilor în lucru. `venueMetricsProvider`
  compune providerii de ospătar existenți, deci dashboard-ul e o vedere read-only
  fără endpoint nou. Încasările și istoricul zilnic vin mai târziu, când backend-ul
  persistă comenzile trecute.
- **Dashboard patron.** O suprafață `/owner` cu carduri de metrici, poll ca la
  ospătar, plus logout.
- **Guard generalizat.** `StaffGuard` a devenit `RoleGuard(role:)`: gate-uiește
  orice suprafață după un rol, citind codul din config potrivit (staff sau
  patron). Adăugarea unei suprafețe gate-uite pe rol e acum doar o rută.

## Alternative respinse (RO)
- **Un endpoint de metrici pe backend acum.** Mai curat pentru încasări și
  istoric, dar o schimbare mai mare (BFF + mock + remote). Snapshot-ul live derivat
  e onest și util azi; endpoint-ul e follow-up pentru istoric.
- **Un guard separat de patron.** Ar dubla poarta de staff. Un `RoleGuard`
  parametrizat pe rol îl ține DRY și scalează la mai multe roluri.
- **Afișarea unei încasări false.** Mai bine omitem ce nu putem calcula decât să
  inventăm.

## Consecințe (RO)
- Patronul vede încărcarea live și mediile de preluare / livrare, în spatele
  codului lui.
- Orice viitoare suprafață gate-uită pe rol refolosește `RoleGuard`.
- De urmat: un endpoint de metrici pentru încasări și grafice zilnice / istorice
  și auth real de patron (Ebriza).

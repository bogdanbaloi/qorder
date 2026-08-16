# ADR-0034: Identity/role seam and a staff access guard

- Status: Accepted
- Date: 2026-08-16

## Context (EN)
The app had one implicit actor, the customer. The owner wants accounts: an owner,
staff (the waiter and barman share one account, as agreed), and customers (normal
vs loyal). And the `/waiter` surface was an OPEN route, so anyone with the URL
could see and accept orders. This is the foundation of the user-management phase.

## Decision (EN)
- **Identity seam.** A pure `Session` (an `AppRole` of customer / staff / owner
  plus a `CustomerKind` of normal / loyal), read across the surfaces as the single
  source of truth. Customer is the default; `loyal` is the seam for the installed-
  app features, not wired yet.
- **Session controller.** `sessionProvider` holds it. The role is persisted
  through the `LocalStore` port, so a dedicated waiter tablet stays signed in.
- **Staff guard.** The `/waiter` route is wrapped in a `StaffGuard`: until the
  session is staff it shows a code gate, and the correct `AppConfig.staffAccessCode`
  (config-driven per venue) signs in as staff. A logout action on the surface
  signs back out. Staff-facing text stays Romanian, like the surface.

Real staff/owner auth (ideally the Ebriza users) replaces the access code in a
later step. The code is a minimal, honest guard for now, not a security system.

## Alternatives rejected (EN)
- **Leave `/waiter` open.** Anyone with the link could accept orders. Even a
  simple code is a real improvement before production.
- **A full login now.** Real accounts belong with the Ebriza integration; a
  config code unblocks the guard without that dependency.
- **A separate flag per surface.** One `Session` with a role scales to the owner
  dashboard and the loyal customer without a new flag each time.

## Consequences (EN)
- The staff surface is gated, and the identity seam is ready for owner + loyal.
- The access code is plaintext in config, adequate for a minimal gate; real auth
  is the follow-up.
- Follow-up: Ebriza-backed staff/owner login, the owner dashboard, wiring
  `CustomerKind.loyal` (enrollment + in-app QR table scan), and a wrong-code
  lockout.

---

## Context (RO)
Aplicația avea un singur actor implicit, clientul. Patronul vrea conturi: un
patron, staff (ospătarul și barmanul împart un cont, cum s-a stabilit) și clienți
(normal vs fidel). Iar suprafața `/waiter` era o rută DESCHISĂ, deci oricine cu
URL-ul vedea și accepta comenzi. Asta e fundația fazei de user-management.

## Decizie (RO)
- **Seam de identitate.** Un `Session` pur (un `AppRole` client / staff / patron
  plus un `CustomerKind` normal / fidel), citit peste suprafețe ca sursă unică de
  adevăr. Clientul e implicit; `loyal` e seam-ul pentru feature-urile din app
  instalat, încă necablat.
- **Controller de sesiune.** `sessionProvider` îl ține. Rolul e persistat prin
  portul `LocalStore`, ca o tabletă de ospătar să rămână logată.
- **Guard de staff.** Ruta `/waiter` e învelită într-un `StaffGuard`: până când
  sesiunea e staff arată o poartă cu cod, iar `AppConfig.staffAccessCode` corect
  (din config, per local) loghează ca staff. O acțiune de ieșire pe suprafață
  deloghează. Textul pentru staff rămâne în română, ca suprafața.

Autentificarea reală staff/patron (ideal utilizatorii Ebriza) înlocuiește codul
într-un pas ulterior. Codul e un guard minim și onest acum, nu un sistem de
securitate.

## Alternative respinse (RO)
- **Lăsarea lui `/waiter` deschis.** Oricine cu linkul putea accepta comenzi.
  Chiar și un cod simplu e o îmbunătățire reală înainte de producție.
- **Un login complet acum.** Conturile reale stau cu integrarea Ebriza; un cod din
  config deblochează guard-ul fără acea dependență.
- **Un flag separat per suprafață.** Un singur `Session` cu rol scalează la
  dashboard-ul patronului și la clientul fidel fără un flag nou de fiecare dată.

## Consecințe (RO)
- Suprafața de staff e gated, iar seam-ul de identitate e gata pentru patron +
  fidel.
- Codul de acces e text simplu în config, destul pentru un guard minim; auth-ul
  real e follow-up.
- De urmat: login staff/patron via Ebriza, dashboard patron, cablarea lui
  `CustomerKind.loyal` (înrolare + scan QR de masă în app) și un lockout la cod
  greșit.

# ADR-0008: Bar view = the existing Ebriza iPad (no push)

- Status: Accepted
- Date: 2026-08-12

## Context (EN)
The bar needs to see incoming orders in real time. The venue already runs Ebriza
on an iPad, always on, at the bar.

## Decision (EN)
The **bar view is Ebriza itself**. An order injected via the API surfaces on the
Ebriza iPad like a Glovo/Bolt order. We build **no bar dashboard** in v1. Real-time
"new order" alerting is Ebriza's in-app notification on an always-on tablet (kiosk
mode), i.e. a live connection while the screen is open, **not an OS push**.

## Alternatives rejected (EN)
- **Build our own bar dashboard**: duplicates Ebriza; unnecessary for v1.
- **FCM push notifications**: a Google (GMS) dependency that breaks Huawei and is
  pointless for an always-on tablet.

## Consequences (EN)
- The "no GMS dependency" constraint (ADR-0001) stays intact.
- If a future need arises to wake a *closed* app (e.g. a manager's phone), it goes
  behind a `NotificationService` seam with per-platform impls (FCM/APNs/HMS).

---

## Context (RO)
Barul trebuie să vadă comenzile în timp real. Localul rulează deja Ebriza pe un
iPad, mereu pornit, la bar.

## Decizie (RO)
**Partea de bar e chiar Ebriza.** O comandă băgată prin API apare pe iPad-ul
Ebriza ca una de Glovo/Bolt. Nu construim **niciun dashboard de bar** în v1.
Alerta "comandă nouă" e notificarea in-app a Ebriza pe o tabletă mereu pornită
(mod kiosk), adică o conexiune live cât timp ecranul e deschis, **nu un push de
sistem**.

## Alternative respinse (RO)
- **Dashboard de bar propriu**: dublează Ebriza; inutil în v1.
- **Notificări push prin FCM**: dependență Google (GMS) care strică Huawei și e
  inutilă pentru o tabletă mereu pornită.

## Consecințe (RO)
- Constrângerea "fără dependență de GMS" (ADR-0001) rămâne intactă.
- Dacă apare nevoia de a trezi o aplicație *închisă* (ex. telefonul managerului),
  intră în spatele unei semințe `NotificationService`, cu impl per platformă.

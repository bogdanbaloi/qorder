# ADR-0016: Remote backend adapter (the app talks to the BFF)

- Status: Accepted (status auto-advance + table view are follow-ups)
- Date: 2026-08-13

## Context (EN)
The BFF (ADR-0015) holds orders on a real server. The app now needs to talk to
it over HTTP so the customer and the waiter sync across DEVICES, not just across
tabs. The in-memory mock stays the default (tests, offline demo), so the swap
must be a configuration choice, not a rewrite.

## Decision (EN)
Add `RemoteBackend`, which implements the SAME `OrderingService` and
`OrderAcceptanceService` interfaces over the BFF's JSON REST contract. The
composition root selects mock or remote from config (`AppConfig.useRemoteBackend`,
true when a BFF URL is set), so no consumer changes (Open/Closed) and every
consumer still depends only on the interface (Dependency Inversion). The BFF URL
is passed at run time and NOT hard-coded:
`flutter run --dart-define=QORDER_BFF_URL=http://<lan-ip>:8080`. The `http.Client`
is injected, so `RemoteBackend` is unit-tested with a fake client.

## Alternatives rejected (EN)
- **Hard-code the URL in the repo**: machine-specific and leaks an address into
  a public repo. A dart-define keeps it out of the code.
- **A separate remote package / codegen client**: over-engineering for a handful
  of endpoints. Plain `http` + `dart:convert` is enough.
- **Change the callers to know about HTTP**: breaks the seam. The whole point of
  the interfaces is that callers never learn which backend is behind them.

## Consequences (EN)
- Flipping mock <-> remote is a one-line config change. The customer and waiter
  flow works across two devices against the BFF.
- Follow-ups: the BFF `tableOrders` endpoint (the "Pe masă" view is empty on
  remote for now) and server-side status advance (received -> preparing -> done).
- The BFF must be reachable on the LAN: run it on `0.0.0.0` so phones can hit the
  laptop's IP.

---

## Context (RO)
BFF-ul (ADR-0015) ține comenzile pe un server real. Acum aplicația trebuie să
vorbească cu el prin HTTP, ca să se sincronizeze clientul și ospăptarul între
DISPOZITIVE, nu doar între tab-uri. Mock-ul din memorie rămâne default (teste,
demo offline), deci schimbarea trebuie să fie o alegere de configurare, nu o
rescriere.

## Decizie (RO)
Adăugăm `RemoteBackend`, care implementează ACELEAȘI interfețe `OrderingService`
și `OrderAcceptanceService` peste contractul REST JSON al BFF-ului. Rădăcina de
compoziție alege mock sau remote din config (`AppConfig.useRemoteBackend`, adevărat
când e setat un URL de BFF), deci niciun consumator nu se schimbă (Open/Closed) și
fiecare depinde tot doar de interfață (Dependency Inversion). URL-ul BFF-ului e dat
la rulare și NU e hardcodat:
`flutter run --dart-define=QORDER_BFF_URL=http://<ip-lan>:8080`. `http.Client` e
injectat, deci `RemoteBackend` e testat unitar cu un client fals.

## Alternative respinse (RO)
- **URL hardcodat în repo**: specific mașinii și scurge o adresă într-un repo
  public. Un dart-define îl ține în afara codului.
- **Un pachet remote separat / client generat**: over-engineering pentru câteva
  endpoint-uri. `http` simplu + `dart:convert` ajunge.
- **Schimbăm apelanții să știe de HTTP**: strică cusătura. Tot rostul interfețelor
  e ca apelanții să nu afle niciodată ce backend e în spate.

## Consecințe (RO)
- Comutarea mock <-> remote e o schimbare de config de o linie. Fluxul client +
  ospăptar merge pe două dispozitive, pe BFF.
- De urmat: endpoint-ul `tableOrders` din BFF (vederea "Pe masă" e goală pe remote
  deocamdată) și avansul de status pe server (received -> preparing -> done).
- BFF-ul trebuie să fie accesibil în LAN: îl rulezi pe `0.0.0.0`, ca telefoanele
  să lovească IP-ul laptopului.

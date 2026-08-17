# ADR-0040: Account / loyalty screen with order history

- Status: Accepted
- Date: 2026-08-17

## Context (EN)
ADR-0039 removed the loyalty nag from the ordering flow but left loyalty with no
home and no visible payoff: a customer could enrol yet see nothing change. A
loyal customer needs a place that (1) holds enrolment (enrol / leave), (2) proves
the value of enrolling. The clearest first payoff is their own order history,
which the backend already keeps (ADR-0028, orders are never dropped).

## Decision (EN)
- **`AccountScreen`** (route `/me`, reachable from a person icon in the menu app
  bar) is the loyal customer's home: their name, a loyalty card (enrol / leave,
  moved here from the menu) and, once loyal, their order history.
- **History behind a port.** A `HistorySource` interface (Dependency Inversion)
  has a `RemoteHistorySource` (reads the BFF's new
  `GET /venues/:id/customers/:clientId/orders`, keyed by the anonymous client id)
  and a `MockHistorySource` (empty, since the in-app mock keeps no history). The
  composition root picks by backend, same seam as everything else.
- **Pure domain.** `PastOrder` is an immutable model with a `fromJson`; money
  stays integer bani via `Money`. The remote adapter degrades to an empty list
  on any error, so the screen never breaks.
- **BFF.** `OrderStore.forCustomer(venueId, clientId)` returns that client's
  orders newest-first; a new route exposes it. Metrics/history read the same
  retained orders.

## Alternatives rejected (EN)
- **Points / rewards as the first payoff.** No POS-backed rules exist yet;
  history is real data we already keep, so it is honest today.
- **History straight from the customer's local order list.** That is per-device
  and lost on reinstall; the loyalty promise is "your orders, wherever you sign
  in", which only the server can honour.
- **A new per-customer store.** The orders already carry `clientId`; a filtered
  read needs no new storage.

## Consequences (EN)
- Loyalty now has a real, visible payoff (history), and enrolment lives in a
  profile context rather than the ordering flow.
- History depends on the remote backend; on the in-app mock it is empty by
  design. Points / offers slot in behind the same screen and the same port later.

---

## Context (RO)
ADR-0039 a scos nagul de fidelitate din fluxul de comandă, dar a lăsat
fidelitatea fără o casă și fără payoff vizibil: un client se putea înrola și nu
vedea nimic schimbat. Un client fidel are nevoie de un loc care (1) ține
înrolarea (înrolare / renunțare), (2) dovedește valoarea înrolării. Primul payoff
clar e propriul istoric de comenzi, pe care backendul deja îl păstrează
(ADR-0028, comenzile nu se șterg).

## Decizie (RO)
- **`AccountScreen`** (ruta `/me`, accesibilă dintr-o iconiță de persoană în bara
  de meniu) e casa clientului fidel: numele, o fișă de fidelitate (înrolare /
  renunțare, mutată aici din meniu) și, odată fidel, istoricul de comenzi.
- **Istoric în spatele unui port.** O interfață `HistorySource` (Inversarea
  Dependenței) are un `RemoteHistorySource` (citește noul
  `GET /venues/:id/customers/:clientId/orders` al BFF-ului, pe id-ul anonim de
  client) și un `MockHistorySource` (gol, mockul in-app nu ține istoric).
  Rădăcina de compoziție alege după backend, același seam ca peste tot.
- **Domeniu pur.** `PastOrder` e un model imutabil cu `fromJson`; banii rămân
  bani întregi prin `Money`. Adaptorul remote degradează la listă goală la orice
  eroare, deci ecranul nu se rupe.
- **BFF.** `OrderStore.forCustomer(venueId, clientId)` întoarce comenzile acelui
  client, cele mai noi primele; o rută nouă îl expune. Metricile / istoricul
  citesc aceleași comenzi păstrate.

## Alternative respinse (RO)
- **Puncte / recompense ca prim payoff.** Nu există încă reguli din POS;
  istoricul e dată reală pe care deja o ținem, deci e onest azi.
- **Istoric direct din lista locală de comenzi.** E per-dispozitiv și se pierde
  la reinstalare; promisiunea fidelității e „comenzile tale, oriunde te
  autentifici", ceea ce doar serverul poate onora.
- **Un store nou per-client.** Comenzile poartă deja `clientId`; o citire
  filtrată nu cere storage nou.

## Consecințe (RO)
- Fidelitatea are acum un payoff real, vizibil (istoric), iar înrolarea stă în
  context de profil, nu în fluxul de comandă.
- Istoricul depinde de backendul remote; pe mockul in-app e gol prin proiectare.
  Puncte / oferte se adaugă în spatele aceluiași ecran și aceluiași port mai
  târziu.

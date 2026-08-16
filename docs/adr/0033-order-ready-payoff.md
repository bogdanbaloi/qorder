# ADR-0033: Order-ready payoff (alert, green banner, estimate)

- Status: Accepted
- Date: 2026-08-16

## Context (EN)
The customer could follow an order's status, but the moment that matters, "your
order is ready", was just another quiet step change. Nothing told them to look up.

## Decision (EN)
- **Ready alert.** The `OrderTracker` fires a one-shot `AlertSignal` (the existing
  haptic + sound port) when an order first transitions to `done`. It fires from
  the tracker, not a screen, so it reaches the customer whichever screen they are
  on. It never re-fires on a repeated done status.
- **Green banner.** The menu status banner turns green with a check icon while any
  order is ready, so the payoff is obvious at a glance.
- **Estimate.** Each not-yet-ready order shows a generic "de obicei gata în
  5-10 min", so the wait is framed.

## Alternatives rejected (EN)
- **A screen-local listener.** It would miss the moment if the customer had
  navigated away. Firing from the tracker (the ViewModel) is screen-independent.
- **A real per-item estimate.** The bar does not expose prep times yet, so a
  generic, honest range is better than a fake precise number. A real ETA is a
  follow-up once the backend reports it.
- **A push notification.** That needs the installed app and permission, a
  loyal-customer / Phase-2 concern. The in-app haptic works for the browser
  customer now.

## Consequences (EN)
- The customer feels the order is ready without watching the screen.
- The alert reuses the same `AlertSignal` port the waiter surface uses, faked in
  tests.
- Follow-up: a real ETA from the backend, and a push notification for the loyal
  installed app.

---

## Context (RO)
Clientul putea urmări statusul comenzii, dar momentul care contează, „comanda ta e
gata", era doar încă o schimbare tăcută de pas. Nimic nu-i spunea să se uite.

## Decizie (RO)
- **Alertă la gata.** `OrderTracker` declanșează un `AlertSignal` o singură dată
  (portul existent de haptic + sunet) când o comandă trece prima oară în `done`.
  Se declanșează din tracker, nu dintr-un ecran, deci ajunge la client pe orice
  ecran ar fi. Nu se re-declanșează la un status `done` repetat.
- **Banner verde.** Banner-ul de status de pe meniu devine verde cu o bifă cât
  timp vreo comandă e gata, ca payoff-ul să fie evident dintr-o privire.
- **Estimare.** Fiecare comandă încă negata arată un generic „de obicei gata în
  5-10 min", ca așteptarea să fie încadrată.

## Alternative respinse (RO)
- **Un listener local pe ecran.** Ar rata momentul dacă clientul a navigat aiurea.
  Declanșarea din tracker (ViewModel) e independentă de ecran.
- **O estimare reală pe produs.** Barul nu expune încă timpi de preparare, deci un
  interval generic și onest e mai bun decât un număr precis fals. Un ETA real e un
  follow-up când îl raportează backend-ul.
- **O notificare push.** Cere app-ul instalat și permisiune, treabă de
  client-fidel / Etapa 2. Haptic-ul în app merge pentru clientul din browser acum.

## Consecințe (RO)
- Clientul simte că e gata comanda fără să stea cu ochii pe ecran.
- Alerta refolosește același port `AlertSignal` ca suprafața ospătarului, fake-uit
  în teste.
- De urmat: un ETA real din backend și o notificare push pentru app-ul fidel
  instalat.

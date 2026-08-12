# ADR-0013: Multi-step orchestration lives in application use-cases

- Status: Accepted
- Date: 2026-08-13

## Context (EN)
Submitting an order is not a single call. It is a bounded retry with a per-call
timeout, a durable outbox and a stable idempotency key (ADR-0012). That
orchestration first grew inside the Riverpod controller, mixing presentation
state with backend orchestration. As more flows arrive (a waiter-confirmation
gate, the Phase 1 Ebriza adapter) the controller would keep absorbing logic that
cannot be unit-tested without a widget or provider harness.

## Decision (EN)
Put multi-step backend orchestration in a plain-Dart **use-case** under
`lib/domain/usecases`. `SubmitOrderUseCase` depends only on the `OrderingService`
and `OutboxRepository` interfaces (Dependency Inversion) and returns a
`SubmitOutcome`. The controller becomes a thin adapter: it builds the `Order`,
calls the use-case and maps the outcome to UI state plus UI-only side effects
(clear the cart, refresh the table view, notify). The `OutboxRepository`
interface moves to `lib/domain/repositories` next to `MenuRepository`, so every
port lives in the domain and dependencies point inward.

## Alternatives rejected (EN)
- **Keep orchestration in the controller**: not unit-testable without Riverpod,
  and it grows without bound as flows are added.
- **A use-case per single call** (a wrapper around one method): over-engineering.
  Only genuine multi-step flows earn a use-case.

## Consequences (EN)
- The submit resilience is unit-tested in isolation, with fakes, no widget or
  provider harness (`test/submit_order_use_case_test.dart`).
- New flows (waiter-confirmation, Ebriza) slot in as use-cases behind the same
  seam, the controller staying thin.

---

## Context (RO)
Trimiterea unei comenzi nu e un singur apel. E o reîncercare mărginită cu timeout
pe fiecare apel, un outbox durabil și o cheie de idempotență stabilă (ADR-0012).
Orchestrarea asta a crescut întâi în controllerul Riverpod, amestecând starea de
prezentare cu orchestrarea de backend. Pe măsură ce apar flow-uri noi (poartă de
confirmare a ospătarului, adaptorul Ebriza din Faza 1), controllerul ar tot
înghiți logică ce nu poate fi testată unitar fără widget sau provider.

## Decizie (RO)
Punem orchestrarea de backend cu mai mulți pași într-un **use-case** de Dart pur,
în `lib/domain/usecases`. `SubmitOrderUseCase` depinde doar de interfețele
`OrderingService` și `OutboxRepository` (Dependency Inversion) și întoarce un
`SubmitOutcome`. Controllerul devine un adaptor subțire: construiește `Order`-ul,
cheamă use-case-ul și mapează rezultatul la starea de UI plus efectele care țin
doar de UI (golește coșul, reîmprospătează vederea mesei, notifică). Interfața
`OutboxRepository` se mută în `lib/domain/repositories`, lângă `MenuRepository`,
deci fiecare port stă în domeniu și dependențele arată spre interior.

## Alternative respinse (RO)
- **Ținem orchestrarea în controller**: netestabilă unitar fără Riverpod și
  crește nemărginit pe măsură ce se adaugă flow-uri.
- **Un use-case per apel simplu** (un wrapper peste o metodă): over-engineering.
  Doar flow-urile reale cu mai mulți pași merită un use-case.

## Consecințe (RO)
- Reziliența la submit e testată unitar izolat, cu fake-uri, fără widget sau
  provider (`test/submit_order_use_case_test.dart`).
- Flow-urile noi (confirmare ospătar, Ebriza) intră ca use-case-uri în spatele
  aceleiași cusături, controllerul rămânând subțire.

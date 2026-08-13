# Changelog

## [Phase 0] - 2026-08-12

Walking skeleton on a mock backend. Architecture, ADRs, tests, CI.

### Added
- Layered MVVM (View / ViewModel / Domain / Data) wired in one composition root
  (`lib/di/providers.dart`).
- Backend behind `OrderingService` + `MenuRepository` interfaces.
  `MockOrderingService` (monotonic FIFO sequence, timed status stream, injectable
  failure) and `BundledMenuRepository` (JSON asset).
- Menu model: categories, items, option groups/choices, time-windowed
  availability. Money as integer minor units (never float).
- Cart with options and quantity, table-number entry and validation, submit gated
  on a validated table.
- Degrade-open submit: bounded automatic retry (outbox), never a silent drop.
- 13 bilingual ADRs (`docs/adr/`) and requirement-to-test traceability
  (`docs/requirements.md`).
- GitHub Actions CI: `dart format` check, `flutter analyze --fatal-infos`,
  `flutter test`.
- 15 unit + widget tests (green); integration test for the full order flow.
- Persistent cart action in the menu app bar (with an item-count badge) and a
  current-table indicator on the menu, so the cart is reachable even when empty
  and the QR table is visible. 16 tests green. (Demonstrates cheap feature adds.)
- Resilience layer: a durable outbox behind a `LocalStore` port +
  `OutboxRepository` (in-memory for tests, shared_preferences on device/web),
  idempotency keys so a resend never duplicates an order, network timeouts, and
  automatic resend of pending orders on launch. ADR-0012. 21 tests green.
- Shared table: multiple phones on one table. Each order carries a name + an
  anonymous device id. A "Pe masă" view shows all orders on the table (read from
  the backend), grouped by name, the customer's own highlighted.
- Configurable notification target (waiter / tablet / both) behind an
  `OrderNotifier` interface with a composite for "both" (SOLID: strategy +
  composite, config-driven). 26 tests green.
- Centralized magic strings/numbers into constants (`Routes`, `AppConstants`,
  `NotificationChannels`) and enabled the `no-magic-number` lint (the clang-tidy
  magic-number equivalent) plus targeted design rules, all fatal in CI.
- Extracted `SubmitOrderUseCase` (application layer, `lib/domain/usecases`): the
  submit orchestration (bounded retry, timeout, idempotent outbox) moved out of
  the controller, which is now a thin presentation adapter. Moved the
  `OutboxRepository` interface into `lib/domain/repositories` next to
  `MenuRepository`, so every port lives in the domain. Unit-tested in isolation.
  ADR-0013. 32 tests green.
- SOLID follow-up pass: the menu-tap "auto-pick required options" rule moved to
  the domain (`MenuItem.defaultSelectedOptions` + `CartController.addMenuItem`),
  the mock's shared-table ledger split into `InMemoryTableLedger`, and the
  launch resume named + marked `unawaited`. Added cart widget tests (table view,
  quantity stepper). 35 tests green.
- Widened the design gate with clang-tidy-style DCL rules, all fatal in CI:
  unused parameters, redundant type casts, collection calls on unrelated types,
  no `late`, no throw-in-catch, prefer conditional expressions, no empty block.
- Waiter confirmation gate (ADR-0014): a per-venue `AcceptanceMode`
  (auto / waiterConfirm) picks an `OrderAcceptancePolicy`. In waiterConfirm the
  order waits (pendingAcceptance) until a waiter accepts it via a segregated
  `OrderAcceptanceService`, then runs received -> preparing -> done. Default
  stays auto, so existing venues are untouched. Waiter screen is next. 38 green.
- Waiter surface: a `/waiter` screen (a thin consumer of
  `OrderAcceptanceService`) lists orders awaiting confirmation and accepts them,
  releasing each into processing. The demo venue is set to waiterConfirm so the
  end-to-end flow is visible: submit on one tab, confirm on `/waiter`, the
  customer advances. 40 tests green.
- Demo cross-tab: the waiter-gate state is shared across browser tabs on one
  device via the LocalStore (localStorage on web), with the waiter surface
  auto-refreshing every 2s. A stopgap until the Phase 1 BFF shares across
  devices.

### Not yet (by design)
- Real Ebriza integration + thin BFF (Phase 1).
- QR / Universal + App Links / store routing / Huawei (Phase 2).
- Full menu: Phase 0 seeds a representative subset, and it comes live from
  Ebriza in Phase 1.

# Changelog

## [Phase 1] - in progress

A real shared backend, so the customer and waiter apps sync across devices (not
just across tabs on one device).

### Added
- Thin BFF (`bff/`, Dart + shelf): a small server holding orders and the waiter
  acceptance flow behind an `OrderStore` port. REST endpoints for submit /
  pending / accept / status, idempotent submit, CORS for the web app. Ebriza
  agnostic for now, the POS adapter slots in behind the store later. ADR-0015.
  7 tests green.
- Remote backend adapter: `RemoteBackend` implements the customer + waiter order
  interfaces over the BFF's REST contract. The composition root selects mock or
  remote from config (a `--dart-define=QORDER_BFF_URL` URL, no hard-coded
  address), so the swap is one line and nothing downstream changes. ADR-0016.
  44 app tests green.
- Shared table on the server: the BFF serves a table's orders
  (`GET /venues/../tables/../orders`, carrying clientId to mark "mine") and
  `RemoteBackend.tableOrders` reads it, so the "Pe masă" view works across
  devices, not just on the mock.
- Optional `requireCustomerName` (on for the demo venue): the submit gate needs
  a name, so the shared table shows who ordered what.
- Live shared-table view: the customer "Pe masă" view now polls (2s) and keeps
  the last list visible during refresh, so an order from another phone on the
  same table appears live, not just after the viewer's own submit. Mirrors the
  waiter surface. Phase 1's BFF push replaces polling later.
- Table-to-waiter requests ("cheamă ospătarul" / "adu nota"): a `WaiterRequest`
  behind two segregated interfaces, `WaiterCaller` (customer `raise`) and
  `WaiterRequestBoard` (waiter `requests` / `resolve`), mirroring the ordering
  vs acceptance split (Interface Segregation). Mock, `RemoteBackend` and a BFF
  `WaiterRequestStore` all fulfil it; idempotent per (venue, table, kind),
  independent of the POS, so it ships in the Standard tier before Ebriza. The
  menu has a call action, the waiter surface a "Cereri" section with resolve.
  ADR-0017, REQ-CALL-001.
- Staff alert on the waiter surface: an `AlertSignal` (device haptic + system
  sound, behind a provider so it is faked in tests) fires when the count of
  pending orders plus requests grows, via a derived count provider and a
  `ref.listen`, so staff are not tied to the screen. Richer web audio is a
  follow-up. 52 app + 11 BFF tests green.
- Order timings: the server stamps 'submitted', 'accepted', 'ready' and
  'delivered', a pure `OrderTimings` value object computes the acceptance time
  and the ready-to-table delivery gap (isolated from bar prep time, the owner's
  metric). Two waiter events, Gata and Livrat, behind a segregated
  `OrderProgress` interface, plus an "În lucru" section that shows the timings.
  POS-independent, feeds the future owner analytics. ADR-0018, REQ-TIME-001.
  57 app + 13 BFF tests green. Also dropped the waiter poll to 1s for snappier
  requests/notifications.

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

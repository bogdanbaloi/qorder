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
- Menu search + category navigation: a pure `Menu.filtered` (name / description
  / tag, drops empty categories) drives a live search field with a clear button,
  and a horizontal bar of category chips jumps the list to a section via a
  GlobalKey plus `Scrollable.ensureVisible`. The filter is model logic, reused
  when the menu comes from Ebriza. ADR-0019, REQ-MENU-002. 61 app tests green.
- Menu item detail sheet: an optional `imageUrl` on `MenuItem`, and tapping a row
  opens a bottom sheet with the photo (or a graceful placeholder), description,
  tag badges, price plus an "Adaugă în coș" button, now the single add path. The
  row shows a thumbnail and the tags as small badges. Ready for Ebriza images,
  just data. ADR-0020, REQ-MENU-003. 62 app tests green.
- Order status as visual steps: after submitting, the customer sees a compact
  stepper (Așteaptă, Preluată, În pregătire, Gata) with finished steps checked
  and the current one highlighted, instead of a single line of text. The ordered
  stages and the current-step lookup are pure domain (`orderStepStages`,
  `orderStepIndex`), unit-tested. ADR-0021, REQ-ORD-004. 63 app tests green.
- Review before submit: tapping "Trimite comanda" opens a dialog with the table,
  name, items and total. The order is sent only after confirming, so a mis-tap or
  a wrong table is caught before it reaches the bar. ADR-0022, REQ-ORD-005.
  64 app tests green.
- Waiter surface clarity: each section header shows its count (Cereri (2),
  Comenzi noi (3), În lucru (1)) and each item shows how long it has waited
  (de 12s), so the waiter gauges load and urgency at a glance. Needed a
  `createdAtMs` on `AwaitingOrder`, populated by the mock at submit and by the
  BFF from the order's submitted stamp. ADR-0023, REQ-ACC-003. 64 app tests
  green.
- Real menu: imported the full Hardward Pub menu from the site into
  `assets/menu/demo.json` (29 categories, 212 items with prices and
  descriptions), replacing the Phase-0 subset. A test parses the shipped asset.
  The live menu still comes from Ebriza in Phase 1, this is the demo snapshot.
- Menu visuals to match the venue site: the menu is flattened into small rows so
  a category chip jumps to the right section precisely (a tall Column per
  category made `scrollable_positioned_list` land short). Headings, item names
  and prices are the signature orange. The techno display font (Chakra Petch) is
  bundled under `assets/fonts` (SIL OFL 1.1) instead of fetched at runtime, so it
  renders offline and on mobile web, and `google_fonts` is dropped. A new
  `Branding.alternatingCategoryBands` token alternates dark and orange category
  bands like the site, off by default and on for the demo venue. ADR-0024.
- Smart time-of-day availability: an item can carry its own `TimeWindow` (like a
  category), and a pure `MenuItem.isAvailableAt(now)` ANDs the manual flag with
  the window. The menu disables what is unavailable now and shows a
  "disponibil HH:MM" note, reading the domain rule (MVVM). Windows are data, so a
  venue opens it without code. The demo seeds Morning Deal at 06:00-12:00.
  ADR-0025, REQ-MENU-004. 70 app tests green.
- Happy-hour promotions: a pure pricing engine in the domain (`Discount` sealed
  into percentage and fixed, `Promotion` with a window plus a category/tag scope,
  `priceItem` picking the best active one). Promotions are data on the menu
  (JSON), so a venue opens a happy hour without code. The menu shows the base
  struck through with the reduced price and the promo name, and the cart calls
  the same `priceItem` at add time so the total matches the menu. `TimeWindow`
  moved to its own file (re-exported) to avoid an import cycle. The demo runs
  Happy Hour 16:00-20:00 at 20% off live beers. ADR-0026, REQ-PRICE-001. 79 app
  tests green.
- Menu search also matches a category name: a search that hits a category name
  (like "vin") keeps that whole category, so a search by category returns all of
  its items, not only items with the word in their name. REQ-MENU-002.
- RO/EN UI toggle: a hand-written i18n where each language is an `AppStrings`
  implementation (`StringsRo`, `StringsEn`) behind an interface, selected by a
  `languageProvider` (Romanian default, persisted through the `LocalStore` port)
  and read via `stringsProvider`. The customer surfaces (menu and cart) hold no
  string literals, they read labels off the current table. A toggle button sits in
  the menu app bar. Adding a language is a new implementation, no widget edits. The
  menu content stays as the venue supplies it. ADR-0027, REQ-I18N-001. 84 app
  tests green.
- Track every order, not only the last: an `OrderTracker` keeps the customer's
  placed orders and watches each one's status stream, so the cart shows a "my
  orders" list with a live stepper per order (number plus Așteaptă / Preluată /
  În pregătire / Gata). On submit the order controller calls `track`, idempotent
  per order id. The status still comes from the backend, the tracker only fans the
  existing per-order stream out to many. ADR-0028, REQ-ORD-006. 87 app tests green.
- Order status on the menu too: a compact, tappable status banner at the top of
  the menu summarises each active order ("#5 · În pregătire"), so the customer
  follows progress while browsing and taps through to the cart for the full
  steppers. The stage-to-label mapping is a shared `orderStageLabel` helper reused
  by the stepper and the banner, so the wording never drifts. REQ-ORD-006. 89 app
  tests green.
- Category icons: bundled the venue site's own five drink-type SVGs (coffee, beer,
  shots, wine, rum) under `assets/icons` and render them with `flutter_svg`. A pure
  `categoryIconAsset` maps a category to an icon, from an explicit `Category.icon`
  key or derived from the name by keyword, so a venue can override any category
  from data. The category header shows the icon, tinted dark on the inverted
  orange bands. ADR-0029, REQ-MENU-005. 91 app tests green.

- Menu orientation: the active category chip highlights and scrolls into view as
  the menu scrolls (an `ItemPositionsListener` maps the top row to its category,
  the chip bar is itself a positioned list). A new "available now" `FilterChip`
  hides closed categories and items outside their window, reusing
  `MenuItem.isAvailableAt` and `Category.copyWith`. ADR-0030, REQ-MENU-006. 92 app
  tests green.

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

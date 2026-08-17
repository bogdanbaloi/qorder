# Requirement-to-test traceability

Every requirement maps to at least one automated test. This is the OFT-style
discipline from the HMI platform, idiomatic to Flutter.

Fiecare cerință e legată de cel puțin un test automat.

| REQ | Requirement | Test(s) |
|-----|-------------|---------|
| REQ-MONEY-001 | Money is exact (integer minor units), never floating point | `test/money_test.dart` |
| REQ-MENU-001 | Menu is a structured model parsed from JSON, rendered natively | `test/menu_parse_test.dart`, `test/menu_asset_test.dart`, `test/widget_test.dart` |
| REQ-MENU-002 | The menu is searchable (item name/description/tag, or a category name which keeps the whole category, drops empty categories) and jump-to-category navigable | `test/menu_search_test.dart`, `test/widget_test.dart` |
| REQ-MENU-003 | Tapping an item opens a detail sheet (photo/placeholder, description, tag badges, price); adding is done from the sheet | `test/widget_test.dart`, `integration_test/app_test.dart` |
| REQ-MENU-004 | An item (like a category) can carry a time-of-day window; the menu is smart about the hour, disabling what is unavailable now with a "disponibil HH:MM" note | `test/menu_item_availability_test.dart` |
| REQ-MENU-005 | Each category shows a drink-type icon (the venue site's SVGs), derived from the name or overridden per category from data | `test/category_icon_test.dart` |
| REQ-MENU-006 | The active category chip highlights and scrolls into view as the menu scrolls; an "available now" filter hides what is closed | `test/menu_item_availability_test.dart` |
| REQ-MENU-007 | Adding is fast: a quantity stepper in the detail sheet, a quick-add "+" on the row, a light haptic and a brief confirmation | `test/widget_test.dart`, `test/cart_test.dart` |
| REQ-PRICE-001 | Time-boxed promotions (happy hour) reduce an item's price via a pure engine; the menu shows the reduced price and the cart charges it | `test/pricing_test.dart`, `test/cart_test.dart` |
| REQ-I18N-001 | Every surface (customer, waiter, owner, access gate) is toggleable RO/EN (RO default, persisted) via a shared toggle, each language a separate string table so widgets hold no literals | `test/i18n_test.dart` |
| REQ-CART-001 | Cart math sums lines with options and quantity | `test/cart_test.dart` |
| REQ-CART-002 | The customer name persists across sessions; the cart shows the happy-hour saving | `test/customer_name_test.dart`, `test/cart_test.dart` |
| REQ-TBL-001 | Submit is gated on a validated table AND a non-empty cart | `test/submit_flow_test.dart` |
| REQ-ORD-001 | A good submit confirms (server id) and clears the cart, never a silent drop | `test/submit_flow_test.dart`, `test/submit_order_use_case_test.dart` |
| REQ-ORD-002 | Orders receive a monotonic FIFO sequence | `test/ordering_mock_test.dart` |
| REQ-ORD-003 | Processing streams status: received -> preparing -> done | `test/ordering_mock_test.dart` |
| REQ-ORD-004 | The order status is shown as visual steps (finished checked, current highlighted), driven by pure domain ordering | `test/order_steps_test.dart` |
| REQ-ORD-005 | Submitting shows a review dialog (table, items, total); the order is sent only on confirm | `test/order_confirm_test.dart`, `integration_test/app_test.dart` |
| REQ-ORD-006 | The customer follows the live status of every order placed (a "my orders" list with a stepper each in the cart, plus a compact status banner on the menu), not only the last one | `test/order_tracker_test.dart`, `test/order_status_labels_test.dart` |
| REQ-ORD-007 | When an order becomes ready the app fires a one-shot alert and turns the status banner green; not-yet-ready orders show a generic time estimate | `test/order_tracker_test.dart` |
| REQ-ERR-001 | Submit failure retries then fails clearly, cart preserved (degrade-open) | `test/submit_flow_test.dart`, `test/ordering_mock_test.dart`, `test/submit_order_use_case_test.dart` |
| REQ-ACC-001 | In waiterConfirm mode a submit waits (pendingAcceptance) until a waiter accepts it, then processes normally | `test/order_acceptance_test.dart` |
| REQ-ACC-002 | The waiter surface lists orders awaiting confirmation and accepts them, clearing each from the list | `test/waiter_screen_test.dart` |
| REQ-ACC-003 | The waiter surface shows a count per section and how long each item has waited | `test/waiter_screen_test.dart` |
| REQ-REMOTE-001 | The remote adapter submits, lists pending, accepts and reads status over the BFF's REST contract | `test/remote_backend_test.dart` |
| REQ-CALL-001 | A table can call the waiter or ask for the bill; the request shows on the waiter surface and is resolved there. Idempotent per (table, kind), scoped per venue, independent of the POS | `test/waiter_requests_test.dart`, `test/remote_backend_test.dart`, `test/waiter_screen_test.dart`, `bff/test/order_api_test.dart` |
| REQ-TIME-001 | Order timestamps (submitted/accepted/ready/delivered) give the acceptance time and the ready-to-table delivery gap, isolated from bar prep time. POS-independent | `test/order_timings_test.dart`, `test/order_progress_test.dart`, `test/remote_backend_test.dart`, `bff/test/order_api_test.dart` |
| REQ-FLOW-001 | Full happy path: browse -> add -> set table -> submit -> confirmed | `integration_test/app_test.dart` |
| REQ-DL-001 | A `/t/:table` link pre-fills the table number (Phase 2 wiring) | seam present in `lib/app/router.dart` (test in Phase 2) |
| REQ-STAFF-001 | A role/identity seam (customer/staff/owner, normal/loyal); the staff surface is behind a config access code and the signed-in role persists | `test/session_test.dart` |
| REQ-LOYAL-001 | A customer can enrol as loyal (persisted); only a loyal customer gets the in-app table pick, since a normal customer's table comes from the QR link | `test/session_test.dart` |
| REQ-LOYAL-002 | The loyal in-app QR scanner reads the table sticker; a pure parser extracts the table from our link, a query, or a bare number | `test/table_qr_test.dart` |
| REQ-LOYAL-003 | A loyal customer has an account screen (enrol / leave + order history); history comes from the backend through a `HistorySource` port, keyed by the client id, and the client parses each past order | `test/past_order_test.dart`, `bff/test/customer_orders_test.dart` |
| REQ-LOYAL-004 | A loyal customer earns points from spend and unlocks a venue-configured reward ladder; a pure policy derives points + progress from the order history (no separate ledger), and an empty program shows no rewards | `test/loyalty_policy_test.dart` |
| REQ-LOYAL-005 | A loyal customer sees their points during ordering (an app-bar chip); a normal customer sees no loyalty UI | `test/loyalty_chip_test.dart` |
| REQ-OWNER-001 | The owner has a dashboard (behind an access code) with a live snapshot: pending / in-progress / requests counts and the average acceptance and delivery times, derived without a new backend | `test/venue_metrics_test.dart`, `test/session_test.dart` |
| REQ-OWNER-002 | The owner dashboard shows real revenue and a daily history from the backend (which keeps past orders); the client reads it through a `MetricsSource` port | `bff/test/metrics_test.dart`, `test/sales_metrics_test.dart` |
| REQ-OWNER-003 | The owner dashboard shows the average order value and the day-over-day movement (orders + revenue delta, percent when available), derived on the client from the existing metrics with no backend change | `test/metrics_insights_test.dart` |
| REQ-OWNER-004 | The backend aggregates today's hourly breakdown and the top products by units sold; the ranking is by units because the line snapshot carries no per-line price | `bff/test/metrics_test.dart` |

## Status
- Phase 0: REQ-MONEY/MENU/CART/TBL/ORD/ERR covered by `flutter test` (15 tests,
  green). REQ-FLOW-001 runs on a device: `flutter test integration_test`.
- REQ-DL-001 is a designed seam. Full deep-link test lands in Phase 2.

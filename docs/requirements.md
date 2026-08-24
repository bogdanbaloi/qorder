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
| REQ-ORD-008 | After an order is placed, adding to the cart returns the submit flow to idle, so the cart shows the submit button again (not the stale post-submit "new order" state) | `test/submit_flow_test.dart` |
| REQ-ORD-009 | "Delivered" is a customer-visible final stage: the waiter marking delivered advances the customer's status past "Ready" to "Delivered" (brought to the table) | `test/order_steps_test.dart`, `test/order_status_labels_test.dart`, `bff/test/order_api_test.dart` |
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
| REQ-LOYAL-006 | A loyal customer redeems an affordable reward for a code (spending points, so it re-locks until re-earned); the staff validate the code, which the backend records | `test/redemption_test.dart`, `test/loyalty_policy_test.dart`, `bff/test/redemptions_test.dart` |
| REQ-IDENT-001 | A customer signs in with their phone (OTP, mock-backed) and the identity persists; loyalty keys on the customerId when signed in and falls back to the anonymous clientId; consent is captured per venue and purpose | `test/session_test.dart`, `test/identity_test.dart` |
| REQ-IDENT-002 | The BFF issues + verifies an OTP (single-use, expiring), creates one customer per phone, and on sign-in merges the anonymous device's orders/redemptions to the customerId; consent is persisted per venue | `bff/test/identity_test.dart` |
| REQ-IDENT-003 | Customer-scoped reads/writes for a known customer require a matching bearer token (403 otherwise); anonymous keys stay open, so guessing a customerId cannot read another customer's data | `bff/test/enforcement_test.dart` |
| REQ-STAFF-002 | The BFF issues a scoped staff/owner token from the venue access code; staff/owner routes require a matching token (per-tenant), and the owner metrics require the owner role | `bff/test/staff_auth_test.dart`, `bff/test/order_api_test.dart` |
| REQ-IDENT-004 | OTP delivery is behind an `SmsSender` seam (dev sender logs the code; a real adapter texts it), and OTP starts are rate limited per phone so the SMS budget cannot be burned | `bff/test/identity_test.dart` |
| REQ-OWNER-001 | The owner has a dashboard (behind an access code) with a live snapshot: pending / in-progress / requests counts and the average acceptance and delivery times, derived without a new backend | `test/venue_metrics_test.dart`, `test/session_test.dart` |
| REQ-OWNER-002 | The owner dashboard shows real revenue and a daily history from the backend (which keeps past orders); the client reads it through a `MetricsSource` port | `bff/test/metrics_test.dart`, `test/sales_metrics_test.dart` |
| REQ-OWNER-003 | The owner dashboard shows the average order value and the day-over-day movement (orders + revenue delta, percent when available), derived on the client from the existing metrics with no backend change | `test/metrics_insights_test.dart` |
| REQ-OWNER-004 | The backend aggregates today's hourly breakdown and the top products by units sold; the ranking is by units because the line snapshot carries no per-line price | `bff/test/metrics_test.dart` |
| REQ-CFG-001 | The app is multi-tenant: it resolves the active venue's config through a `VenueConfigSource` port (unknown venue returns null), instead of a single hard-wired config. In-memory now, a remote source later, POS-independent | `test/venue_config_source_test.dart` |
| REQ-CFG-002 | The QR link carries the venue (`/v/:venue/t/:table`): a known venue becomes the active venue and opens the menu with the table pre-filled; an unknown venue shows a clear error instead of a wrong menu. `/t/:table` still works, mapped to the default venue | `test/venue_entry_test.dart` |
| REQ-CFG-003 | A venue is data: its config is parsed from a JSON catalogue asset (`AppConfig.fromJson`, hex colours), loaded at bootstrap with a degrade-open fallback to the built-in demo; the shipped asset matches the demo config. `backendBaseUrl` stays a build-time deployment overlay | `test/venue_config_json_test.dart` |
| REQ-CFG-004 | The owner edits the venue name and brand colours in a Settings screen and saves them. The write persists server-side, per venue, isolated by RLS (`AppConfig.toJson` round-trips, a `VenueConfigStore` behind `PUT /venues/:id/config`). The write is owner-only. A staff token is refused. A saved edit re-reads with the persisted value | `test/app_config_json_test.dart`, `test/owner_settings_test.dart`, `bff/test/venue_config_api_test.dart`, `bff/test/postgres_venue_config_test.dart` |
| REQ-CFG-005 | The customer app overlays each venue's server-saved config on the bundled asset at bootstrap, so an owner edit reaches customers at their next app open with no release. Each fetch degrades open (a miss or a down backend keeps the asset). The deployment `backendBaseUrl` is re-applied | `test/config_remote_overlay_test.dart` |
| REQ-PERSIST-001 | BFF data persists to multi-tenant Postgres, scoped by `venueId` (consent first): recorded choices survive, an upsert replaces prior choices, and one venue never reads another's rows. Falls back to in-memory with no `QORDER_DATABASE_URL` | `bff/test/postgres_consent_test.dart` |
| REQ-PERSIST-002 | Orders persist to multi-tenant Postgres. Each venue numbers its orders from 1 via an atomic counter. Submit is idempotent per venue and the lifecycle (accept, ready, delivered) is stamped. One venue never reads another venue's orders | `bff/test/postgres_order_test.dart` |
| REQ-PERSIST-003 | Redemptions persist to multi-tenant Postgres, scoped by `venueId`. A `seq` column keeps a stable newest-first order. Consume validates one pending code. One venue never reads another venue's redemptions | `bff/test/postgres_redemption_test.dart` |
| REQ-PERSIST-004 | Identity persists to GLOBAL Postgres tables (no `venue_id`, since a person is the same at any venue). The same phone maps to the same customer. A token authenticates its customer. Wrong, expired or reused codes fail. startChallenge is rate limited per phone | `bff/test/postgres_identity_test.dart` |
| REQ-OPS-001 | The operator sees cross-venue evidence: a snapshot of active venues with order count and distinct users per venue, from the durable data, behind an operator token (`GET /platform/metrics`) | `bff/test/postgres_platform_metrics_test.dart`, `bff/test/platform_metrics_test.dart` |
| REQ-OPS-002 | The operator opens `/admin`, enters the operator token and sees the cross-venue usage table. The token is session-only, never stored. A wrong token surfaces an error instead of a blank screen | `test/admin_screen_test.dart`, `test/remote_platform_metrics_source_test.dart` |
| REQ-PERSIST-005 | Row-Level Security enforces the tenant boundary at the database, not only in app code. Each tenant transaction drops to a non-superuser role and sets `app.venue_id`, so a query with no `venue_id` filter still returns only the scoped venue's rows. A cross-venue insert is refused by the policy. The operator plane reads every venue through the `__all__` sentinel | `bff/test/postgres_rls_test.dart` |
| REQ-PERSIST-006 | (Follow-up) The staff-authenticated order mutations (accept, ready, delivered) scope by the venue in the staff token's claims, so they run under their venue rather than the cross-venue sentinel. The public `status` poll stays venue-less by design | _pending_ |
| REQ-OBS-001 | The client logs through an `AppLogger` port (levels, console sink, quiet in release). Every degrade-open data source logs why it degraded before returning its fallback, instead of swallowing the error. The behaviour (the fallback) is unchanged | `test/logger_test.dart` |
| REQ-OBS-002 | The BFF logs through `BffLog` (timestamped, levelled, floor from `QORDER_LOG_LEVEL`). A refused auth logs a WARNING with the reason (no token, wrong venue, not owner), so a 403 is not silent. Startup logs the storage mode | `bff/test/logging_test.dart` |
| REQ-OBS-003 | The client ships warning and error records to `POST /logs` (a `RemoteLogger` in a `CompositeLogger` with the console), tagged with the venue, throttled and fire-and-forget. The BFF persists them through a `LogStore` (bounded batch and message length) and the operator reads them from `GET /logs` behind the operator token | `test/remote_logger_test.dart`, `bff/test/client_logs_api_test.dart`, `bff/test/postgres_log_store_test.dart` |
| REQ-OBS-004 | (Follow-up) `POST /logs` gets per-IP rate limiting and `client_logs` gets retention pruning, so the public endpoint cannot be used to fill the store over time | _pending_ |

## Status
- Phase 0: REQ-MONEY/MENU/CART/TBL/ORD/ERR covered by `flutter test` (15 tests,
  green). REQ-FLOW-001 runs on a device: `flutter test integration_test`.
- REQ-DL-001 is a designed seam. Full deep-link test lands in Phase 2.

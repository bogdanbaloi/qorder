# Changelog

## [Phase 1] - in progress

A real shared backend, so the customer and waiter apps sync across devices (not
just across tabs on one device).

### Added
- The operator picks a venue palette on the Admin screen. A palette is one brand
  accent plus a dark and a light pair, from a predefined set tuned for bars, pubs,
  restaurants and hotels, so each venue keeps its own look in both modes. Applying
  one saves it and re-themes the app at once. Every palette is contrast-checked in
  both modes by a test. REQ-CFG-009, ADR-0065.
- The operator can write a venue's config on the backend, so setting the palette
  works in a real deployment, not only the offline demo. The operator is a
  superadmin, so the venue config write accepts an owner token or the operator
  token. The Admin palette save authenticates with the operator token entered on
  that screen. A wrong token is refused. REQ-CFG-010, ADR-0066.
- Light and dark are a per-user choice. A toggle on the top bar (beside the
  language toggle) flips the app between light and dark for the current person on
  this device. It follows the system by default and persists across launches, so
  the owner and the customer each set their own look. REQ-CFG-008, ADR-0064.
- The venue theme is derived from a single brand accent through Material 3. Given
  the accent and a brightness, the scheme is generated with contrast that holds by
  construction, so light and dark both stay readable (checked by a WCAG-contrast
  test). This replaces the curated four-colour presets and the owner's raw colour
  pickers: the owner no longer edits colours in Settings, since the venue palette
  is an operator concern and a bespoke look is a paid service. Supersedes
  REQ-CFG-007. REQ-CFG-007, ADR-0064.
- Owner Settings edit the loyalty program. The owner sets the points-per-unit
  rate and manages the reward ladder (add, edit and remove a tier's threshold and
  text). It saves through the venue config and applies live, so the reward ladder
  is venue-editable data now, not a constant. REQ-LOYAL-007, ADR-0060.
- A dead token no longer traps the owner. When a Settings save is rejected as
  unauthorized (401/403), the app signs the session out, so the access-code gate
  reappears for a fresh sign-in instead of a stuck "could not save". The failure
  surfaces as a `SessionExpiredException` the caller acts on. REQ-IDENT-005.
- Owner Settings apply live. A successful save now pushes the edited config into
  a session-live override, so the running app re-themes at once (venue name,
  colours) instead of waiting for a manual reload. The override carries the
  backend URL, so the backend stays wired. It clears on a full restart.
  REQ-CFG-006, ADR-0061.
- Order mutations are venue-scoped under RLS. Accept, ready and delivered now run
  under the venue in the staff token's claims, not the cross-venue sentinel, so a
  venue cannot mutate another venue's order (the database refuses it). This closes
  the last write-isolation gap the RLS slice had left open. The public `status`
  poll and `relink` stay venue-less by design. REQ-PERSIST-006, ADR-0059.
- Hardened the public log endpoint. `POST /logs` is rate limited per caller IP
  (429 when a caller floods it). `client_logs` is bounded by retention pruning
  (keep the newest rows, pruned on startup and every few hours), so the open
  endpoint cannot fill the store over time. REQ-OBS-004, ADR-0063.
- Client logs reach the operator. The client ships its warning and error records
  to the BFF (`POST /logs`), tagged with the venue, throttled and best-effort, so
  a failure on a patron's device is no longer invisible. The BFF persists them in
  Postgres (bounded batch and message length) and the operator reads them back
  from `GET /logs` behind the operator token. The operator admin screen shows a
  "recent errors" list, so reading client failures needs no curl. REQ-OBS-003,
  ADR-0063.
- Logging, so failures stop being silent. The client logs through an `AppLogger`
  port (levels, a console sink quiet in release). Every degrade-open data source
  now logs why it degraded before returning its fallback. The BFF logs through
  `BffLog` (timestamped, levelled). A refused auth logs the reason, so a 403 is
  no longer silent. No external package on either side. REQ-OBS-001, REQ-OBS-002,
  ADR-0062.
- A saved venue config now reaches customers. At bootstrap, with a backend
  configured, each venue's server-saved config is overlaid on the bundled asset,
  so an owner's Settings edit shows for customers at their next app open, no
  release. Each fetch degrades open (a miss or a down backend keeps the asset).
  The read path stays synchronous, so no consumer changes. REQ-CFG-005, ADR-0061.
- Owner Settings: the owner edits the venue name and brand colours in a Settings
  screen (reached from the owner dashboard) and saves them. The write persists
  server-side per venue through a `VenueConfigStore`, isolated by RLS. A live
  preview shows the colours applied. `AppConfig.toJson` round-trips with the
  factory. The write is owner-only. The customer-facing app still reads the
  bundled asset. Reading the saved config live is a follow-up. REQ-CFG-004,
  ADR-0060.
- Owner Settings colours are picked from a curated palette (tap a swatch), not
  typed as hex, so an owner needs no colour codes. Dependency-free, no external
  picker package. REQ-CFG-004, ADR-0060.
- Row-Level Security enforces the tenant boundary at the database. A migration
  adds a non-superuser role, enables RLS on the tenant tables and a per-table
  policy keyed on `app.venue_id`. Each tenant transaction drops to that role and
  sets the venue, so a query missing a `venue_id` filter still returns only the
  scoped venue's rows. A test proves a bare `SELECT` sees one venue. The operator
  plane reads across venues through an `__all__` sentinel. REQ-PERSIST-005,
  ADR-0059.
- Operator admin UI: an `/admin` screen where the operator pastes the operator
  token and sees the cross-venue usage table (venues, orders, distinct users).
  The token is session-only, never stored on the device. A wrong token shows an
  error instead of a blank screen. REQ-OPS-002, ADR-0058.
- Operator evidence: a `GET /platform/metrics` endpoint (behind an operator token)
  reports active venues with order count and distinct users per venue, aggregated
  from the durable Postgres data. No UI yet. REQ-OPS-001, ADR-0057.
- Identity persists to Postgres in GLOBAL tables (no venue_id, since a person is
  the same at any venue). The same phone maps to the same customer. Tokens map
  back. OTP rate limiting is kept. The persistence track is now complete.
  REQ-PERSIST-004, ADR-0056.
- Owner-friendly menu hours: a time window is written as clock times in the menu
  ("start": "16:00"). The code converts to minutes, so nobody hand-computes
  minutes-from-midnight. Raw minutes still parse for back-compat.
- Redemptions persist to multi-tenant Postgres, scoped by venue. A `seq` column
  keeps a stable newest-first order. A cross-tenant test proves one venue never
  sees another's redemptions. The in-memory store stays for dev without a
  database. REQ-PERSIST-003, ADR-0055.
- Orders persist to multi-tenant Postgres. Each venue numbers its orders from 1
  via an atomic counter. PostgresOrderStore drops in behind the now-async
  OrderStore port. A cross-tenant test proves one venue never sees another's
  orders. The in-memory store stays for dev without a database. REQ-PERSIST-002,
  ADR-0054.
- BFF persistence on multi-tenant Postgres (consent first): consent now persists
  to Postgres, scoped by `venueId` (one venue never reads another's rows, proven
  by a cross-tenant test). `PostgresConsentStore` drops in behind the async
  `ConsentStore` port; the BFF uses it when `QORDER_DATABASE_URL` is set, else the
  in-memory store. Local dev/CI use a Docker Postgres; production a managed one
  (Neon/Supabase) via the same env. Other stores migrate next; RLS follows.
  REQ-PERSIST-001, ADR-0053.
- Venue config as a JSON document: a venue is now data parsed from a catalogue
  asset (`assets/venues/demo.json`) via `AppConfig.fromJson` (hex colours,
  name-based enums), loaded at bootstrap with a degrade-open fallback to the
  built-in demo. One binary serves every venue; a venue edit needs no app release.
  `backendBaseUrl` stays a `--dart-define` deployment overlay. REQ-CFG-003,
  ADR-0052.
- Venue from the QR link: a new `/v/:venue/t/:table` route carries the venue. A
  `VenueEntryScreen` resolves it against the config source, sets it as the active
  venue (so branding, menu, policy and loyalty follow) and opens the menu with the
  table pre-filled; an unknown venue shows a clear "venue not found" screen instead
  of a wrong menu. `/t/:table` still works, mapped to the default venue.
  REQ-CFG-002, ADR-0051.
- Multi-venue config seam: the app now resolves the active venue's `AppConfig`
  through a `VenueConfigSource` port instead of the single hard-wired
  `AppConfig.demo`. In-memory source now (config in the binary), a remote source
  drops in behind the port later. No behaviour change (the active venue is still
  `demo`); this is the foundation for venue-from-link and the owner Settings
  screen. REQ-CFG-001, ADR-0050.
- "Delivered" as the customer's final order stage: the waiter's "Livrat" now
  advances the customer's status past "Gata" (ready) to "Livrat" (brought to the
  table), so the customer follows the order the whole way. A new `OrderStage.
  delivered` + stepper step; the status stream ends on delivered. REQ-ORD-009.

### Security
- Staff and owner sign-in is rate limited. The access code is short, and
  `POST /venues/:id/staff/auth` had no throttle, so it could be brute-forced. It
  now bounds attempts per caller IP (10 a minute), and the guard runs before the
  code is checked, so over the budget even a correct code is refused. A normal
  sign-in is unaffected. REQ-SEC-002, ADR-0069.
- The OTP code is no longer exposed in production. `POST /auth/otp/start` echoed the
  code as `devCode` and the dev SMS sender printed it, a full OTP bypass, and the
  echo defaulted on. It is now off by default: a deployment opts in with
  `QORDER_EXPOSE_DEV_CODE=true` (the demo), otherwise the production sender neither
  returns nor logs the code. OTP delivery waits on a real SMS provider (a
  fail-closed stub, never a leak). REQ-SEC-001, ADR-0068.
- The public config read no longer leaks the access codes. `GET /venues/:id/config`
  is open (the customer app reads branding without a token), but the stored document
  carried the staff and owner access codes, so anyone could read them and sign in.
  The response now redacts those codes (the stored document is untouched, branding
  is still served). The codes the backend checks live in the staff auth store, not
  this document. REQ-CFG-011, ADR-0067.

### Fixed
- Owner Settings could not save from the web app: the CORS preflight allowed only
  GET and POST, so the browser blocked the config `PUT` before it reached the BFF
  (the owner saw "could not save"). PUT is now allowed. REQ-CFG-004.
- Second order stuck on "new order": after placing an order, the submit flow
  stayed in the `confirmed` phase, so adding new items to the cart still showed
  the "Comandă nouă" button instead of "Trimite comanda" (you had to reset via
  the menu first). The order controller now returns to idle when a new order is
  composed (the cart becomes non-empty after a placed order). REQ-ORD-008.

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
- Faster adding: the detail sheet gained a quantity stepper (and is now scrollable
  so it never overflows), each row gained a quick-add "+" that adds one without
  opening the sheet, and a single `_addWithFeedback` helper gives a light haptic
  and a brief confirmation on both paths. ADR-0031, REQ-MENU-007. 93 app tests
  green.
- Cart polish: the customer name now persists across sessions through the
  `LocalStore` port (same seam as the language), a cart line carries a
  `discountPerUnit` set from the pure `priceItem` so the order form shows "Ai
  economisit X" (the happy-hour saving), and the empty cart shows an icon above
  the text. ADR-0032, REQ-CART-002. 94 app tests green.
- Order-ready payoff: the `OrderTracker` fires a one-shot `AlertSignal` (haptic +
  sound, the same port the waiter surface uses) when an order first becomes
  ready, from the tracker so it reaches the customer on any screen. The menu
  status banner turns green with a check while an order is ready, and each
  not-yet-ready order shows a generic "de obicei gata în 5-10 min". ADR-0033,
  REQ-ORD-007. 95 app tests green.
- Identity/role seam and a staff guard (start of user management): a pure
  `Session` (an `AppRole` of customer/staff/owner plus a `CustomerKind` of
  normal/loyal) held by `sessionProvider`, with the role persisted through the
  `LocalStore` port. The `/waiter` route, previously open, is now wrapped in a
  `StaffGuard` that shows a code gate until the config-driven
  `AppConfig.staffAccessCode` is entered, with a logout on the surface. Real
  Ebriza-backed auth replaces the code later. ADR-0034, REQ-STAFF-001. 100 app
  tests green.
- Owner dashboard: an `/owner` surface (behind the owner access code) showing a
  live snapshot, a pure `VenueMetrics` derived from the data the waiter surface
  already exposes (pending / in-progress / requests counts and the average
  acceptance and delivery times), so there is no new backend endpoint. The staff
  guard generalized into a `RoleGuard(role:)` reused for both surfaces. Revenue
  and daily history come with a backend metrics endpoint later. ADR-0035,
  REQ-OWNER-001. 103 app tests green.
- Real owner metrics from the BFF: the BFF stores each order's `totalMinor` (the
  client already sends it) and a pure `computeMetrics` aggregates today's orders
  and revenue, the average acceptance and delivery times, and a per-day series,
  behind `GET /venues/:id/metrics`. The app reads it through a `MetricsSource`
  port (remote over the BFF, mock empty), and the dashboard shows an "Azi" section
  with a daily revenue bar chart. Access codes documented in `docs/access.md`.
  ADR-0036, REQ-OWNER-002. 105 app + 15 BFF tests green.
- Localize every surface: the RO/EN string table (ADR-0027) now covers the waiter
  surface, the owner dashboard and the access gate too, added to the same
  `AppStrings` interface. The inline menu toggle became a shared `LanguageToggle`
  widget, now on every app bar, so each surface switches language independently.
  Titles reuse the existing `tableAt` / `orderNumber` strings. ADR-0037,
  REQ-I18N-001. 106 app tests green.
- Loyal-customer enrollment: a loyalty action in the menu opens a sheet where a
  normal customer enrols with a name and becomes loyal (or a loyal one leaves).
  `SessionController.enrollLoyal` flips the `CustomerKind`, now persisted through
  the `LocalStore` port. The manual "Alege masa" table strip returns, gated to
  loyal customers only (a normal customer's table comes from the QR link). The
  in-app QR table scanner is the next step. ADR-0038, REQ-LOYAL-001. 107 app tests
  green.
- In-app QR table scanner: a `QrScanScreen` (mobile_scanner) reads the table
  sticker and returns the table; a pure `tableFromScan` parses the number from our
  link, a query or a bare number. The loyal table strip offers "Scanează" next to
  "Alege masa". Camera permissions added for Android / iOS. The loyalty enrollment
  button and sheet were removed from the menu app bar (it confused the normal QR
  customer and had no visible payoff); the `CustomerKind` seam, the gated strip and
  the scanner stay in code, ready for a dedicated account / loyalty screen. The
  camera needs a secure context, so it does not run on the plain-http demo.
  ADR-0039, REQ-LOYAL-002. 111 app tests green.
- Account / loyalty screen (`/me`, from a person icon in the menu): the loyal
  customer's home, with the enrol / leave card (moved off the menu) and, once
  loyal, their order history. History reads the backend through a new
  `HistorySource` port (`RemoteHistorySource` over
  `GET /venues/:id/customers/:clientId/orders`, keyed by the client id;
  `MockHistorySource` empty since the in-app mock keeps none). `PastOrder` is a
  pure model (money in bani); the BFF gained `OrderStore.forCustomer` (newest
  first) and its route. Each history tile shows table and the order's date.
  ADR-0040, REQ-LOYAL-003. 113 app tests + 16 BFF tests green.
- Loyalty points + reward ladder on the account screen: a pure
  `computeLoyalty(history, program)` derives points (1 per whole leu spent) and
  ladder progress from the same order history (no separate points ledger to
  drift). The program (`LoyaltyProgram` + `RewardTier` ladder) is venue config in
  `AppConfig`; reward text is venue content (untranslated). A rewards card shows
  points, a progress bar to the next reward and the locked / unlocked ladder.
  ADR-0041, REQ-LOYAL-004. 117 app tests green.
- Richer owner dashboard: average order value and day-over-day movement (orders
  + revenue delta with a percent) derived on the client from the existing
  metrics (pure `averageOrderValue` / `dayOverDay`, no backend change); plus a
  today hourly breakdown and top products by units sold, aggregated on the BFF
  (`computeMetrics` gains `hourly` + `topProducts`). Top products rank by units
  because the line snapshot carries no per-line price. The daily chart is
  generalised to a reusable `_BarChart`, so the hourly chart shares it.
  ADR-0042, REQ-OWNER-003, REQ-OWNER-004. 122 app tests + 18 BFF tests green.
- Loyal intuitiveness (cheap, no backend): a points chip in the menu app bar
  (`LoyaltyChip`), shown only to a loyal customer, so the reward loop is visible
  while ordering (tap opens the account); a "Bună, {name}" greeting on the
  account screen; and a welcome SnackBar on enrol. All View-layer, reusing
  `loyaltyStatusProvider`. ADR-0043, REQ-LOYAL-005. 123 app tests green.
- Reward redemption (closes the loyalty loop): a loyal customer redeems an
  affordable reward for a short code to show the staff; the staff surface lists
  pending redemptions and validates the code (same alert as a new order).
  Redeeming spends points — `computeLoyalty` subtracts `redeemedPoints`, so the
  points shown are spendable and a reward re-locks until re-earned. Recorded on
  the BFF behind a new `RedemptionStore` port + routes; two segregated client
  ports (`RewardRedeemer` customer, `RedemptionBoard` staff), one adapter.
  Affordability is client-side for now (honest, pending customer auth).
  ADR-0044, REQ-LOYAL-006. 127 app tests + 21 BFF tests green.
- Customer cross-device identity, slice 1 (mock-first, no SMS/backend change):
  phone + OTP sign-in behind an `IdentityService` port (`MockIdentityService`,
  fixed demo code `000000`). `Session` drops `CustomerKind` for a
  `CustomerIdentity?` — a loyal customer is an identified one; enrol becomes sign
  in. Loyalty keys on the effective `loyaltyKeyProvider` (customerId when signed
  in, else the anonymous clientId), so it follows the customer and merges on
  sign-in. Consent captured per venue + purpose via a `ConsentSource` port
  (loyalty required, marketing optional). A `SignInScreen` (phone → code →
  consent → verify). Enforcement + real SMS are the next slices.
  ADR-0045, REQ-IDENT-001. 131 app tests green.
- Customer identity backend, slice 2 (real BFF, POS-agnostic, no SMS/Ebriza): an
  `IdentityStore` issues + verifies an OTP (single-use, 5-min; the code returns as
  `devCode` until an SMS adapter lands) and creates one customer per phone. On
  sign-in the BFF `relink`s the anonymous device's orders + redemptions to the
  `customerId` (cross-device merge). A `ConsentStore` persists per-venue,
  per-purpose consent. Client `RemoteIdentityService` + `RemoteConsentSource`
  behind the same ports, selected by `useRemoteBackend`; `startSignIn` returns a
  `SignInChallenge` so the screen shows the dev code per environment. Per-request
  authorization + real SMS are slice 3; the Ebriza adapter is later.
  ADR-0046, REQ-IDENT-002. 131 app + 26 BFF tests green.
- Identity enforcement, slice 3 (the buildable half; real SMS still external):
  server-side authorization so a customer's data cannot be read by guessing their
  `customerId` (which derives from a phone). Customer-scoped routes now require a
  matching bearer token when the key is a known customer (403 otherwise);
  anonymous device keys stay open. The remote sources send the session token
  (`authToken`), wired from the composition root. Broader staff/owner per-tenant
  auth + real SMS remain later, extending the same token seam.
  ADR-0047, REQ-IDENT-003. 131 app + 28 BFF tests green.
- Per-tenant staff/owner authorization (server-issued token, POS-agnostic): the
  staff/owner surfaces were client-gated only, so the BFF was open. Now
  `POST /venues/:id/staff/auth` verifies the venue's code and issues a token
  scoped to (venue, role); staff/owner routes require a matching token
  (`_staffOk`), metrics require the owner role, per-tenant. Client: a
  `StaffAuthService` port (remote BFF vs mock local check), the gate exchanges the
  code for a token stored on `Session.staffToken`; `Session.token` unifies the
  customer + staff token, sent by the remote sources via `sessionTokenProvider`.
  ADR-0048, REQ-STAFF-002. 131 app + 31 BFF tests green.
- SMS sender seam + OTP rate limiting: OTP delivery is behind an `SmsSender` port
  (`DevSmsSender` logs the code; a real Twilio/Infobip/Viber adapter drops in at
  the composition root). `OrderApi.exposeDevCode` gates the `devCode` echo (on for
  the demo, off in production once SMS is live). OTP starts are rate limited (5
  per phone per 10 min -> 429), so the SMS budget cannot be burned; the sign-in
  screen shows a failure message. Client unchanged (null devCode = no hint).
  ADR-0049, REQ-IDENT-004. 131 app + 32 BFF tests green.

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

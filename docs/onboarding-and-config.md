# qorder — Onboarding & Configuration Model

Internal reference. Captures the design decisions for turning qorder from a
single-venue demo into a multi-venue product: how a venue is configured, what we
ask a new venue for, how we operate many venues, and the order we build it in.

This note precedes the ADRs it will spawn. It is a map, not an implementation.

---

## 1. Three planes — keep them separate

Most confusion comes from mixing these. They have different owners, lifecycles
and tools.

| Plane | What it is | What it needs |
|---|---|---|
| **Product** | The app plus the BFF, per-venue features | Exists today. Being made multi-venue. |
| **Operator** | Our own evidence: how many venues, users per venue, orders per venue | A cross-venue aggregate on the backend plus a small admin surface |
| **Infra** | How it runs: hosting, persistence, deployment | Docker plus a real database. Not Kubernetes yet. |

Deployment (Docker) and observability (a metrics dashboard) are different things.
Do not conflate "how the service starts" with "how we visualise usage".

---

## 2. Three kinds of "settings"

The word "settings" hides three concerns. Separate them:

| # | Kind | Set by | Stored | Examples |
|---|---|---|---|---|
| 1 | **VenueConfig** (tenant) | Owner + us at onboarding | Server, per venue | branding, menu source, table policy, loyalty, access codes |
| 2 | **User preferences** | The customer on their phone | Device-local | language, theme override, last venue |
| 3 | **Secrets / integrations** | Us / the owner | Server, never in the client | POS API keys, SMS provider keys |

The multi-venue read side (`VenueConfigSource`) and the owner Settings screen are
the two halves of #1: read and write of the same document. Read does not need
write, so multi-venue ships before the Settings screen.

---

## 3. The core shift: config as data, not code

Today the venue config is a Dart constant (`AppConfig.demo`, single venue,
`venueId: 'demo'`). Branding, table policy, loyalty, and access codes are already
per-venue **data**, which is good, but the config is baked into the binary.

Consequence: changing a colour for a venue means recompile plus redeploy.
Unacceptable for many venues.

The shift: config becomes a **document (JSON) fetched at runtime**, keyed by
`venueId`. Result:

- one binary serves all venues,
- an owner edits settings and it takes effect with no app release.

This single move unlocks both multi-venue and the Settings screen. They are the
same move seen from two sides.

---

## 4. Multi-venue resolution (venue from the link)

The QR sticker encodes **venue + table**, resolved on our domain (a dynamic
redirect), independent of any POS. The app resolves the venue at entry:

- New route `/v/:venue/t/:table` carries the venue. Keep `/t/:table` working,
  mapped to the default venue, so nothing breaks.
- A `VenueConfigSource` port answers `AppConfig configFor(String venueId)`.
  In-memory / asset implementation now, remote (our backend) later.
- The resolved `venueId` drives `appConfigProvider`. No venue in the link
  (a loyal customer opening the installed app) falls back to the last-used venue.
- Unknown venue shows a clear error screen, never a crash.

`VenueConfigSource` is the read side of "settings" (#1 above) and the foundation
the Settings screen later writes through.

---

## 5. Menu intake (onboarding)

Good news: the menu is already a defined schema and is JSON-driven
(`lib/domain/models/menu.dart`, `assets/menu/demo.json`). Menu → Categories →
Items, with price, description, tags, variants (option groups with price deltas),
time-of-day availability, and promotions. The question is not the schema. It is
what we ask a venue for and how we fill the schema.

A pub owner does not write JSON. Intake is a **simple template** (a spreadsheet),
one row per item, that we convert to JSON.

### Intake template (no-POS venue)

| Column | Required | Example | Maps to |
|---|---|---|---|
| Category | yes | "Bere" | `Category.name` |
| Category order | no (default: sheet order) | 1 | `Category.sortOrder` |
| Item name | yes | "Ciucaș 0.5L" | `MenuItem.name` |
| Price (lei) | yes | 9.00 | `basePrice` (→ 900 minor units) |
| Description | no | "blondă, la halbă" | `description` |
| Tags | no | "NOU; vegan" | `tags` |
| Availability | no (default: always) | "always" / "17:00-19:00" | `availability` window |
| Image | no | link / file | `imageUrl` |
| Variant group | no | "Mărime" | `OptionGroup.name` |
| Variant + price delta | no | "0.3L (-2) / 0.5L (0)" | `OptionChoice.priceDelta` |

Only the first three are strictly required (**category, name, price**). Prices are
asked in **lei** and converted to minor units (bani) by us. The owner never
touches minor units.

### Three intake paths (POS-agnostic)

1. **Has a POS (Ebriza or other):** no template. We **sync** products,
   categories, and prices through the POS adapter. Ask only for API access. The
   menu stays current automatically.
2. **No POS:** the owner fills the template above.
3. **Only a PDF / photo / online menu:** this is where AI earns its place. OCR
   plus extraction into the schema (name, price, category), then a **human review
   pass** before it goes live. Unstructured to structured, with a person in the
   loop. This is different from using AI to count things, which a query does.

### Rest of the venue settings (once, not per item)

Separate from the menu, onboarding also collects: venue name, brand colours (or
"we take them from your site"), table count / range, loyalty program (points rate
plus reward ladder), staff and owner access codes. These are the other parts of
VenueConfig; they do not mix with the menu.

---

## 6. Operator evidence (cross-venue analytics)

The evidence we need (how many venues, users per venue, orders per venue) is the
**Operator plane**. It is a query, not AI agents.

The data mostly exists in the BFF already (orders, customers per phone, consent
per venue). "Users per venue" is distinct customers (by `customerId`) with
activity at a `venueId`. So evidence is a cross-venue aggregate:

- a `PlatformMetricsSource` port → list of venues plus per-venue user / order
  counts,
- an admin surface (a page, or at first a report / CLI; no UI required to start).

**Precondition:** the data must be tagged by `venueId`. That is exactly the
multi-venue work in section 4. So operator evidence is the natural continuation,
not a parallel effort. It also needs persistence (section 7) so the evidence
survives a restart.

---

## 7. Infra guidance (honest)

- **Kubernetes: not yet.** k8s (an orchestrator for many services across many
  machines, run by a team) is complexity you pay for without using at a scale of
  a few to a few dozen venues. Use **Docker** (one container, or Docker Compose
  for BFF plus database). Move to k8s when it hurts, not preemptively.
- **The real infra gap is persistence.** The BFF keeps everything **in memory**
  (order, identity, redemption, consent stores). On a restart, the evidence
  disappears. Real operation needs a **database** (SQLite → Postgres) plus the
  Docker container. This matters before k8s and before AI.
- **AI agents are not the mechanism for evidence.** Counting venues and users is
  `SELECT COUNT`. AI adds cost and nondeterminism for something a query does.
  Where AI fits later: support triage, plain-language anomaly alerts, "health of
  venue X" summaries. Not the counting itself.

---

## 8. Current QR flow (state + gaps)

Implemented in `main`:

| Flow | State | Where |
|---|---|---|
| Normal customer, table from the QR link | In code | `router.dart` `/t/:table` → `MenuScreen(tableParam)` → `setFromQr` |
| Loyal customer, in-app table pick | In code | `_TableStrip` → "Scan table" (real camera via `mobile_scanner` → parser → `setManual`) plus "Choose table" (manual) |
| QR parser | Implemented + tested | `tableFromScan` (`/t/7`, `?table=7`, bare number); `test/table_qr_test.dart` |
| Normal / loyal seam | Real | `isLoyalCustomer` = a signed-in customer |

Gaps:

1. **Native deep link not registered.** On **web** it works (scan → our URL →
   the web app routes to `/t/7`). On an **installed native app**, App Links
   (Android) / Universal Links (iOS) are not configured, so a sticker scan does
   not open the installed app yet. Needs intent-filters, `associated-domains`,
   and the `.well-known` files on our domain. This is infra and needs the real
   domain.
2. **The normal deep-link consumption is only lightly tested.** A widget test
   (`test/widget_test.dart`, "deep-link table shows in the app bar") covers that
   `MenuScreen(tableParam:)` surfaces the table; a focused test asserting the
   validated table state (and an out-of-policy number rejected) would lock it
   harder.
3. **In-app camera needs HTTPS or a native build** (not a plain-http LAN demo).
4. **Table validation is a local range policy**, not real POS validation
   (Ebriza "List tables" is future).

---

## 9. Delivery slices (order + what each unlocks)

Each slice is self-contained and gets the full treatment: ADR, tests, SOLID and
MVVM review.

**Config track**

1. **`VenueConfigSource` port** (foundation). DONE (ADR-0050). The port plus an
   in-memory implementation holding the config, one venue (the demo) now behind
   the port; `appConfigProvider` reads through the source for the active
   `venueId`. No behaviour change; decouples the app from a single constant.
2. **Venue from the link.** DONE (ADR-0051). `/v/:venue/t/:table` plus a
   `VenueEntryScreen` gate: known venue becomes active and opens the menu with the
   table; unknown venue shows a clear error. `/t/:table` still maps to the default
   venue. Multi-tenancy proven by tests; a focused normal deep-link validation
   test is included.
3. **Config as a JSON document.** DONE (ADR-0052). `AppConfig.fromJson` (hex
   colours, name-based enums) parses a venue from a catalogue asset, loaded at
   bootstrap with a degrade-open fallback; the shipped asset matches the demo.
   `backendBaseUrl` stays a `--dart-define` deployment overlay. One binary for all
   venues; `toJson` lands with the Settings screen.
4. **Owner Settings screen.** The write side, editing the same config store,
   inside the existing owner dashboard.

**Parallel tracks (independent, scheduled separately)**

- **Persistence plus Docker** (infra). The real prerequisite for operator
  evidence and for not losing data on restart.
- **Menu intake pipeline.** The template, the converter to menu JSON, and later
  AI-assisted transcription for PDF / photo menus.
- **Operator evidence.** `PlatformMetricsSource` plus an admin report, after data
  is venue-tagged and persisted.
- **SMS seam.** Real `SmsSender` port plus OTP rate limiting. Small and isolated;
  makes phone sign-in real.
- **Ebriza adapter.** The POS behind ports; Ebriza is one adapter. The big
  productization step, tackled on its own.

Slice 1 is the mother: once config is addressable per venue behind a port, the
rest builds on it.

---

## Open questions

- How much can the **owner** edit self-serve versus what **we** set at
  onboarding? This decides how much Settings UI we build.
- Domain / QR provisioning: the real domain, the redirect service, and the
  `.well-known` files for native deep links.
- Menu freshness for POS venues: sync cadence (on change, polled, webhook).

# qorder

A QR table-ordering app for pubs. A customer scans the QR at their table, browses
a native menu, builds a cart, confirms the table number, and submits the order to
the bar. Venue-neutral engine (branding + menu are config), first customer:
Demo Pub. Integrates with the **Ebriza** POS.

> `qorder` is a working codename. Branding lives in config, not the app name.

## Status: Phase 1 in progress (real shared backend)

Phase 0 (walking skeleton) is done. Phase 1 adds a thin BFF (`bff/`) so the
customer, waiter and owner apps sync across devices, plus the surfaces built on
top of it.

Built so far:
- **Customer:** menu from JSON (time-aware availability, happy hours), search +
  jump-to-category, cart with options, table gate, submit with an idempotent
  outbox, live order status, call-waiter / bill.
- **Waiter:** live board of orders to accept, table requests, and in-progress
  orders (mark ready / delivered) with timings and a sound/vibration alert.
- **Owner:** dashboard with today's orders + revenue, average order value,
  day-over-day movement, acceptance/delivery times, and daily + hourly +
  top-product breakdowns.
- **Loyalty:** phone sign-in (OTP, mock for now), order history, points + reward
  ladder derived from spend, a points chip in the ordering flow, and reward
  redemption (spend points -> code -> staff validate).
- **Cross-cutting:** role/identity seam (customer phone sign-in; staff / owner
  behind access codes), consent captured per venue + purpose, RO/EN toggle on
  every surface, in-app QR table scanner.

- `flutter test` -> 127 app tests pass; `bff` -> `dart test` -> 21 tests pass.
- `flutter analyze` clean; Dart Code Linter (design smells) clean.

## Architecture

Layered MVVM, dependencies point inward, wired in one composition root.

```
View (widgets)            lib/features/*/*_screen.dart          dumb, no logic
ViewModel (Riverpod)      lib/features/*/*_controller.dart      presentation state
Domain (pure Dart)        lib/domain/**                         models + interfaces
Data / infra              lib/data/**                           mock + (later) Ebriza
Composition root          lib/di/providers.dart                 binds interface->impl
```

The backend is behind `OrderingService` + `MenuRepository` interfaces (like the
HMI `IntegrationBackend`). Phase 0 runs on a mock. Phase 1 drops in the Ebriza
adapter with no change to the app. See `docs/adr/` for every decision, and
`docs/requirements.md` for requirement-to-test traceability.

## Run

```bash
flutter pub get
flutter test                       # unit + widget (headless, no device)
flutter run                        # needs an Android emulator / iOS simulator
flutter test integration_test      # full-flow test, needs a device
```

Deep-link demo (Phase 2 seam already present):

```bash
flutter run
# then, with the app running on a device:
# adb shell am start -a android.intent.action.VIEW -d "https://order.demo.app/t/12"
```

## Roadmap

- **Phase 0 (done):** architecture, ADRs, mock, menu from JSON, cart, table gate,
  submit, tests, CI.
- **Phase 1 (in progress):** thin BFF (orders, waiter flow, requests, owner
  metrics, loyalty) so the apps sync across devices; waiter + owner + loyalty
  surfaces. Remaining: the Ebriza adapter (`Open bill`, `List items`,
  `List tables`, status via WebHooks) behind the same store ports, and the BFF
  holding Ebriza credentials. Bar view can also stay the existing Ebriza iPad.
- **Phase 2:** QR + Universal/App Links + store-routing landing page (App Store /
  Play / AppGallery), Huawei build, offline outbox hardening, RO/EN, polish.

## Open items (not blocking Phase 0)
- Confirm an API-injected Ebriza order surfaces on the iPad like a Glovo order.
- Register an app in Ebriza Marketplace. The venue authorizes it (`ebriza-clientid`).
- Own the deep-link domain, plus Apple Developer + Google Play + AppGallery accounts.

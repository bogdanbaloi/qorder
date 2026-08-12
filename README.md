# qorder

A QR table-ordering app for pubs. A customer scans the QR at their table, browses
a native menu, builds a cart, confirms the table number, and submits the order to
the bar. Venue-neutral engine (branding + menu are config), first customer:
Demo Pub. Integrates with the **Ebriza** POS.

> `qorder` is a working codename. Branding lives in config, not the app name.

## Status: Phase 0 (walking skeleton) is DONE and green

Browse menu (from bundled JSON) -> cart with options -> table number entry +
validation -> submit gated on a valid table -> `MockOrderingService` (with FIFO
sequence, timed status, and injectable failure to prove degrade-open).

- `flutter test` -> 15 unit/widget tests pass.
- `flutter analyze` -> clean.

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
HMI `IntegrationBackend`). Phase 0 runs on a mock; Phase 1 drops in the Ebriza
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
- **Phase 1:** thin BFF holding Ebriza credentials, Ebriza adapter (`Open bill`,
  `List items`, `List tables`, status via WebHooks). Bar view = the existing
  Ebriza iPad.
- **Phase 2:** QR + Universal/App Links + store-routing landing page (App Store /
  Play / AppGallery), Huawei build, offline outbox hardening, RO/EN, polish.

## Open items (not blocking Phase 0)
- Confirm an API-injected Ebriza order surfaces on the iPad like a Glovo order.
- Register an app in Ebriza Marketplace; the venue authorizes it (`ebriza-clientid`).
- Own the deep-link domain; Apple Developer + Google Play + AppGallery accounts.

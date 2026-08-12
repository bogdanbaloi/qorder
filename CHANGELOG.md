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
- Cart with options and quantity; table-number entry and validation; submit gated
  on a validated table.
- Degrade-open submit: bounded automatic retry (outbox), never a silent drop.
- 11 bilingual ADRs (`docs/adr/`) and requirement-to-test traceability
  (`docs/requirements.md`).
- GitHub Actions CI: `dart format` check, `flutter analyze --fatal-infos`,
  `flutter test`.
- 15 unit + widget tests (green); integration test for the full order flow.
- Persistent cart action in the menu app bar (with an item-count badge) and a
  current-table indicator on the menu, so the cart is reachable even when empty
  and the QR table is visible. 16 tests green. (Demonstrates cheap feature adds.)

### Not yet (by design)
- Real Ebriza integration + thin BFF (Phase 1).
- QR / Universal + App Links / store routing / Huawei (Phase 2).
- Full menu (Phase 0 seeds a representative subset; the full menu comes live from
  Ebriza in Phase 1).

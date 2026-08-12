# ADR-0011: What we reuse (and not) from the Industrial HMI platform

- Status: Accepted
- Date: 2026-08-12

## Context (EN)
The author has a C++ Industrial HMI platform with strong patterns. The temptation
is to haul patterns over. The risk is cargo-culting C++ into mobile.

## Decision (EN)
Reuse the **method and patterns**, not the industrial machinery:
- **Bring**: backend-behind-an-interface (`IntegrationBackend` -> `OrderingService`/
  `MenuRepository`), composition root, degrade-open + explicit boundary errors,
  config policy vs mechanism, a FIFO queue (the outbox), the observer pattern
  (Riverpod streams), ADRs + requirement-to-test traceability, CI/lint gates.
- **Do NOT bring**: lock-free / SPSC / memory-ordering implementations (Dart is
  single-threaded with isolates, wrong tool), PIMPL (solves a C++ compile-firewall
  that does not exist in Dart), Modbus/OPC-UA/MQTT/telemetry (no industrial I/O).

## Alternatives rejected (EN)
- **Port patterns literally** (lock-free structures, PIMPL): resume-driven
  over-engineering. Keep the intent, not the C++ mechanism.

## Consequences (EN)
- Two small feature analogs are justified: a connection/degraded-state indicator
  (serves degrade-open) and config feature flags (serves multi-client). Crash
  reporting, if added, uses a non-GMS tool (e.g. Sentry), not Firebase Crashlytics.

---

## Context (RO)
Autorul are o platformă de HMI industrial în C++ cu tipare puternice. Tentația e
să care tiparele. Riscul e cargo-cult de C++ în mobile.

## Decizie (RO)
Reutilizăm **metoda și tiparele**, nu mașinăria industrială:
- **Aducem**: backend în spatele unei interfețe (`IntegrationBackend` ->
  `OrderingService`/`MenuRepository`), rădăcina de compoziție, degrade-open +
  erori explicite la graniță, config policy vs mechanism, o coadă FIFO (outbox-ul),
  pattern-ul Observer (fluxuri Riverpod), ADR-uri + trasabilitate cerință-la-test,
  gate-uri CI/lint.
- **NU aducem**: implementări lock-free / SPSC / memory-ordering (Dart e cu un
  singur fir plus isolates, unealta greșită), PIMPL (rezolvă un firewall de
  compilare din C++ inexistent în Dart), Modbus/OPC-UA/MQTT/telemetrie (fără I/O
  industrial).

## Alternative respinse (RO)
- **Portarea literală a tiparelor** (structuri lock-free, PIMPL): over-engineering
  de dragul CV-ului. Păstrăm intenția, nu mecanismul de C++.

## Consecințe (RO)
- Două analogii mici de feature sunt justificate: un indicator de stare/mod
  degradat (servește degrade-open) și feature flags în config (servește
  multi-client). Raportarea de crash-uri, dacă se adaugă, folosește o unealtă
  non-GMS (ex. Sentry), nu Firebase Crashlytics.

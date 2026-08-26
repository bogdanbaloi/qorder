# 0077 - Client error boundary

## Status

Accepted. The client twin of the BFF error hygiene (ADR-0076).

## Context

`main` called `runApp` with no global error handling: no `FlutterError.onError`,
no `PlatformDispatcher.onError`, no `runZonedGuarded`. So an uncaught error in a
widget build or an async callback surfaced as the framework's red (debug) or grey
(release) error screen. It was never logged. In production the customer saw a
broken screen and the operator never learned it happened.

The BFF already catches uncaught errors at its edge (ADR-0076). The client needed
the same.

## Decision

Install a global error boundary in `main`, reusing the existing `AppLogger` seam.

- `FlutterError.onError` logs the framework/widget error through `AppLogger`, then
  still calls `presentError`, so the red screen keeps helping in debug.
- `platformDispatcher.onError` logs an uncaught async error and returns `true`, so
  it does not crash the isolate. (The two hooks together replace the older
  `runZonedGuarded` pattern.)
- In release, `ErrorWidget.builder` returns a calm, self-contained fallback (it
  sets its own `Directionality` and colours), instead of the raw error widget.
- The logging is extracted into two small functions (`reportFlutterError`,
  `reportPlatformError`), so a unit test drives them without touching global state.

## Consequences

- An unexpected crash becomes a logged, observable event and a calm screen, not a
  silent broken UI. A test asserts both report paths log at error level with the
  exception.
- The errors are logged through whatever `AppLogger` `main` injects, so they reach
  the backend if that logger ships to `/logs`. Wiring a shipping logger into `main`
  (today it is the console logger) is a separate, small step.
- The handling stays distributed elsewhere (degrade-open in data sources, typed
  exceptions, ViewModel error states). This boundary is only the last-resort net,
  not a central handler.

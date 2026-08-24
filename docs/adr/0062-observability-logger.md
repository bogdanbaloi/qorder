# 0062 - A logging seam, so failures are not silent

## Status

Accepted

## Context

Several data sources degrade open: on an error they return a safe fallback (the
bundled asset, a null status, an empty list) so the app keeps working. The catch
was silent, so the actual error vanished. When a save failed or the backend was
unreachable, nothing said why, so debugging meant guessing. The BFF was no
better: a refused auth returned 403 with no reason. Startup wrote a couple of
ad-hoc `stdout` lines.

The industrial HMI project logs through an injected seam. qorder had none.

## Decision

A small logging seam on each side, no external package.

- **Client:** an `AppLogger` port (Domain) with levels (debug, info, warning,
  error) and a one-method contract, plus a `SilentLogger` no-op default and a
  `ConsoleLogger` that writes through `dart:developer` and drops debug and info
  in release. Data sources take an optional `AppLogger` (defaulting to
  `SilentLogger`, so a standalone source and its unit tests need no wiring). The
  composition root injects the real one through `loggerProvider`. Every
  degrade-open catch now logs why it degraded before returning the fallback.
- **BFF:** a `BffLog` that writes `timestamp [LEVEL] message` to stdout, with a
  level floor from `QORDER_LOG_LEVEL` and an injectable sink (stdout by default,
  a collector in tests). Startup logs the storage mode. `_staffOk` logs a
  WARNING with the specific reason when it refuses a request.

No dependency on either side: the client already had `dart:developer`, the BFF
uses stdout. A remote log collector can drop in behind either seam later.

## Consequences

- A failure now says what happened. A wrong owner token logs
  `auth refused: role staff is not owner`, the exact line missing when the owner
  Settings save returned 403 during the demo.
- Degrade-open behaviour is unchanged: the sources still return their fallback,
  they just log first. No consumer changes, since the logger defaults to silent.
- The poll loop logs at debug, not warning, so a transient network blip during
  status polling does not spam the log.
- Levels drop debug and info noise from a release build, so a shipped app logs
  only warnings and errors.
- The seam is a port, so a remote collector (or a structured JSON sink) is a
  later swap, not a rewrite.

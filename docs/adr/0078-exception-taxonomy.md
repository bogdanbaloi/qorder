# 0078 - A sealed exception taxonomy

## Status

Accepted. Sizes the "centralized exceptions" question raised alongside the error
boundary (ADR-0077).

## Context

Error handling in the app is deliberately distributed (degrade-open in data
sources, error state in ViewModels, the global boundary in ADR-0077), which is the
right shape: what to DO about an error is context-specific. But the exceptions the
app raises on purpose had no shared vocabulary. There was one domain exception,
`SessionExpiredException`. Every backend failure was a bare
`throw Exception('X failed: <status>')` (eight of them, across the remote data
sources). A caller could not tell a backend failure from any other `Exception`,
and there was no compiler help to handle each kind.

A central "error manager" that owns classification, messaging and recovery would be
an anti-SRP god-object, so that was rejected. What is worth centralizing is the
DEFINITIONS, not the handling.

## Decision

Centralize the definitions, keep the handling distributed.

- A `sealed class AppException implements Exception` with the kinds the app really
  raises: `SessionExpiredException` (moved under it) and `BackendException` (a
  failed backend call, carrying the `operation` name and the `statusCode`). Sealed,
  so a `switch` over `AppException` is exhaustive: the compiler flags a new kind a
  handler forgot. A sealed type's subtypes share its library, so they live in one
  file.
- The eight bare `throw Exception('X failed')` in the remote sources now throw
  `BackendException('X', statusCode: ...)`, so a backend failure is a typed thing.
- Programming errors (an `ArgumentError` for a bad argument) stay outside the
  taxonomy: they are bugs to fix, not conditions to handle.
- No message-mapper and no central handler are added. A pure
  `userMessageFor(AppException, AppStrings)` would be the natural next step, but
  there is no consumer yet (the ViewModels carry their own messages), so adding it
  now would be dead code. It lands when a caller needs to map an exception to a
  message.

## Consequences

- The app has one vocabulary for the errors it raises. A handler that switches on
  `AppException` is checked for completeness by the compiler. A test exercises the
  exhaustive switch and the `BackendException` fields.
- Existing catches are unaffected: `BackendException` and `SessionExpiredException`
  are still `Exception`s, so the degrade-open `on Object` catches and the
  `on SessionExpiredException` handler keep working.
- The taxonomy is intentionally small (two kinds). It grows only when a real new
  condition appears, not speculatively.

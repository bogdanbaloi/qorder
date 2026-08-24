import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../../domain/diagnostics/app_logger.dart';

// dart:developer severity levels (the java.util.logging scale).
const int _severityDebug = 500;
const int _severityInfo = 800;
const int _severityWarning = 900;
const int _severityError = 1000;

/// Writes logs to the developer console via `dart:developer`. In release the
/// floor is [LogLevel.warning], so debug and info noise is dropped from a
/// shipped build while warnings and errors still surface. Records below the
/// floor are skipped.
class ConsoleLogger implements AppLogger {
  final LogLevel minLevel;

  ConsoleLogger({LogLevel? minLevel})
    : minLevel = minLevel ?? (kReleaseMode ? LogLevel.warning : LogLevel.debug);

  @override
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.index < minLevel.index) return;
    developer.log(
      message,
      name: 'qorder',
      level: _severity(level),
      error: error,
      stackTrace: stackTrace,
    );
  }

  // Map to dart:developer levels (roughly the java.util.logging scale).
  int _severity(LogLevel level) => switch (level) {
    LogLevel.debug => _severityDebug,
    LogLevel.info => _severityInfo,
    LogLevel.warning => _severityWarning,
    LogLevel.error => _severityError,
  };
}

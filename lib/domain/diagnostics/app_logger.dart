/// Severity of a log record, low to high.
enum LogLevel { debug, info, warning, error }

/// The logging PORT (Dependency Inversion). The app logs through this seam, so
/// the sink (console now, a remote collector later) is swappable and tests stay
/// silent. One method carries everything. The extension below is the sugar.
abstract interface class AppLogger {
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  });
}

/// Convenience level methods, so callers write `logger.warning(...)` instead of
/// passing a [LogLevel] every time.
extension AppLoggerLevels on AppLogger {
  void debug(String message) => log(LogLevel.debug, message);

  void info(String message) => log(LogLevel.info, message);

  void warning(String message, {Object? error, StackTrace? stackTrace}) =>
      log(LogLevel.warning, message, error: error, stackTrace: stackTrace);

  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      log(LogLevel.error, message, error: error, stackTrace: stackTrace);
}

/// A no-op logger. The default for data sources when none is injected, so a
/// standalone source (and its unit tests) needs no logging wiring.
class SilentLogger implements AppLogger {
  const SilentLogger();

  @override
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    // No-op: the silent logger drops every record.
    return;
  }
}

import '../../domain/diagnostics/app_logger.dart';

/// Fans one log record out to several sinks, so the app can log to the console
/// AND ship warnings to the backend at the same time (Composite pattern). A
/// failing sink must not stop the others, so each is guarded.
class CompositeLogger implements AppLogger {
  final List<AppLogger> sinks;

  const CompositeLogger(this.sinks);

  @override
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    for (final sink in sinks) {
      try {
        sink.log(level, message, error: error, stackTrace: stackTrace);
      } on Object {
        // A logging sink must never break the app or the other sinks.
      }
    }
  }
}

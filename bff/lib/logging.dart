import 'dart:io';

/// Severity of a log record, low to high.
enum BffLogLevel { debug, info, warning, error }

/// Minimal structured logging for the BFF, to stdout. No dependency: the server
/// writes `timestamp [LEVEL] message` lines, so an operator sees what happened
/// (a refused auth, the storage mode) instead of silence. The floor comes from
/// `QORDER_LOG_LEVEL` (debug/info/warning/error), defaulting to info.
class BffLog {
  final BffLogLevel floor;

  /// Where a formatted line goes. Defaults to stdout. A test passes a collector.
  final void Function(String line) sink;

  BffLog({BffLogLevel? floor, void Function(String line)? sink})
    : floor = floor ?? _floorFromEnv(),
      sink = sink ?? stdout.writeln;

  void debug(String message) => _emit(BffLogLevel.debug, message);

  void info(String message) => _emit(BffLogLevel.info, message);

  void warning(String message) => _emit(BffLogLevel.warning, message);

  void error(String message) => _emit(BffLogLevel.error, message);

  void _emit(BffLogLevel level, String message) {
    if (level.index < floor.index) return;
    final now = DateTime.now().toIso8601String();
    sink('$now [${level.name.toUpperCase()}] $message');
  }

  static BffLogLevel _floorFromEnv() {
    final name = Platform.environment['QORDER_LOG_LEVEL']?.toLowerCase();
    return BffLogLevel.values.firstWhere(
      (level) => level.name == name,
      orElse: () => BffLogLevel.info,
    );
  }
}

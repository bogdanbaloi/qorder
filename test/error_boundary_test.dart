import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/app/error_boundary.dart';
import 'package:qorder/domain/diagnostics/app_logger.dart';

/// Records what it is asked to log, so the test can assert the boundary reports.
class _RecordingLogger implements AppLogger {
  final records = <({LogLevel level, String message, Object? error})>[];

  @override
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    records.add((level: level, message: message, error: error));
  }
}

/// REQ-OBS-005: uncaught Flutter and async errors are logged, not swallowed.
void main() {
  test('a Flutter framework error is logged at error level', () {
    final logger = _RecordingLogger();
    final boom = StateError('widget boom');

    reportFlutterError(logger, FlutterErrorDetails(exception: boom));

    expect(logger.records.single.level, LogLevel.error);
    expect(logger.records.single.error, boom);
  });

  test('an uncaught async error is logged at error level', () {
    final logger = _RecordingLogger();
    final boom = Exception('async boom');

    reportPlatformError(logger, boom, StackTrace.current);

    expect(logger.records.single.level, LogLevel.error);
    expect(logger.records.single.error, boom);
  });
}

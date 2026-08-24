import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:qorder/data/config/remote_venue_config_api.dart';
import 'package:qorder/domain/diagnostics/app_logger.dart';

/// Captures records, so a test can assert that a degrade-open path logged.
class _CapturingLogger implements AppLogger {
  final records = <({LogLevel level, String message})>[];

  @override
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    records.add((level: level, message: message));
  }
}

void main() {
  // REQ-OBS-001: the level sugar maps to the right LogLevel.
  test('the level methods map to their LogLevel', () {
    final logger = _CapturingLogger();
    logger.warning('w');
    logger.error('e');
    logger.info('i');
    logger.debug('d');
    expect(logger.records.map((r) => r.level), [
      LogLevel.warning,
      LogLevel.error,
      LogLevel.info,
      LogLevel.debug,
    ]);
  });

  // REQ-OBS-001: a degrade-open fetch logs why it degraded instead of swallowing.
  test(
    'a failed config fetch logs a warning and still degrades open',
    () async {
      final logger = _CapturingLogger();
      final client = MockClient((_) async => http.Response('boom', 500));
      final source = RemoteVenueConfigApi(
        baseUrl: 'http://x',
        client: client,
        logger: logger,
      );

      final result = await source.fetch('demo');

      expect(result, isNull); // still degrades open
      expect(
        logger.records.any(
          (r) => r.level == LogLevel.warning && r.message.contains('config'),
        ),
        isTrue,
      );
    },
  );
}

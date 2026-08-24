import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:qorder/data/diagnostics/composite_logger.dart';
import 'package:qorder/data/diagnostics/remote_logger.dart';
import 'package:qorder/domain/diagnostics/app_logger.dart';

class _Capturing implements AppLogger {
  final records = <LogLevel>[];
  @override
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    records.add(level);
  }
}

void main() {
  // REQ-OBS-003: warnings ship to the BFF, debug/info do not.
  test('ships warning and error, drops debug and info', () async {
    final posted = <Map<String, dynamic>>[];
    final client = MockClient((req) async {
      posted.add(jsonDecode(req.body) as Map<String, dynamic>);
      return http.Response('{"stored":1}', 200);
    });
    final logger = RemoteLogger(
      baseUrl: 'http://x',
      client: client,
      venueId: 'demo',
    );

    logger.debug('d');
    logger.info('i');
    logger.warning('something broke');
    // The POST is fire-and-forget; let its microtask run.
    await Future<void>.delayed(Duration.zero);

    expect(posted.length, 1);
    final record = (posted.single['records'] as List).single as Map;
    expect(record['level'], 'warning');
    expect(record['message'], 'something broke');
    expect(record['venueId'], 'demo');
  });

  // A logging call must never throw, even when shipping fails.
  test('a failed ship is swallowed, not thrown', () async {
    final client = MockClient((_) async => throw Exception('network down'));
    final logger = RemoteLogger(baseUrl: 'http://x', client: client);

    expect(() => logger.error('boom'), returnsNormally);
    await Future<void>.delayed(Duration.zero);
  });

  // REQ-OBS-003: the composite fans one record out to every sink.
  test('composite logs to every sink', () {
    final a = _Capturing();
    final b = _Capturing();
    CompositeLogger([a, b]).warning('x');
    expect(a.records, [LogLevel.warning]);
    expect(b.records, [LogLevel.warning]);
  });
}

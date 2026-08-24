import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/data/platform/remote_operator_logs_source.dart';

void main() {
  // REQ-OBS-003: the source parses the operator log list and sends the token.
  test('parses recent logs and sends the operator token', () async {
    late String sentAuth;
    final client = MockClient((req) async {
      sentAuth = req.headers['authorization'] ?? '';
      return http.Response(
        '[{"level":"error","message":"boom","venueId":"demo"},'
        '{"level":"warning","message":"slow"}]',
        200,
      );
    });
    final source = RemoteOperatorLogsSource(
      baseUrl: 'http://x',
      client: client,
    );

    final logs = await source.recent('op-secret');
    expect(sentAuth, 'Bearer op-secret');
    expect(logs.length, 2);
    expect(logs.first.message, 'boom');
    expect(logs.first.venueId, 'demo');
    expect(logs.last.venueId, isNull);
  });

  test('throws on a non-200 (a wrong token)', () async {
    final client = MockClient((_) async => http.Response('forbidden', 403));
    final source = RemoteOperatorLogsSource(
      baseUrl: 'http://x',
      client: client,
    );
    expect(() => source.recent('wrong'), throwsException);
  });
}

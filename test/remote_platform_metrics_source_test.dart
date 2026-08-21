import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/data/platform/remote_platform_metrics_source.dart';

void main() {
  // REQ-OPS-002: the source parses the operator snapshot and sends the token.
  test('parses the snapshot and sends the operator token', () async {
    late String sentAuth;
    final client = MockClient((req) async {
      sentAuth = req.headers['authorization'] ?? '';
      return http.Response(
        '{"venueCount":1,"venues":[{"venueId":"demo","orders":3,"users":2}]}',
        200,
      );
    });
    final source = RemotePlatformMetricsSource(
      baseUrl: 'http://x',
      client: client,
    );

    final snap = await source.snapshot('op-secret');
    expect(sentAuth, 'Bearer op-secret');
    expect(snap.venueCount, 1);
    expect(snap.venues.single.venueId, 'demo');
    expect(snap.venues.single.orders, 3);
    expect(snap.venues.single.users, 2);
  });

  test(
    'throws on a non-200 (a wrong token), so the UI can report it',
    () async {
      final client = MockClient((req) async => http.Response('forbidden', 403));
      final source = RemotePlatformMetricsSource(
        baseUrl: 'http://x',
        client: client,
      );
      expect(() => source.snapshot('wrong'), throwsException);
    },
  );
}

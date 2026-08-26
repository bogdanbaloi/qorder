import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:qorder/core/config/app_config.dart';
import 'package:qorder/data/config/remote_venue_config_api.dart';
import 'package:qorder/domain/errors/app_exception.dart';

void main() {
  // REQ-IDENT-005: a rejected token surfaces as SessionExpiredException, so the
  // caller can re-authenticate instead of a stuck failure.
  test('save throws SessionExpiredException on 403', () async {
    final client = MockClient((_) async => http.Response('forbidden', 403));
    final api = RemoteVenueConfigApi(
      baseUrl: 'http://x',
      client: client,
      authToken: 'dead-token',
    );
    expect(
      () => api.save('demo', AppConfig.demo),
      throwsA(isA<SessionExpiredException>()),
    );
  });

  test('save throws a generic error on 500 (not a session expiry)', () async {
    final client = MockClient((_) async => http.Response('boom', 500));
    final api = RemoteVenueConfigApi(baseUrl: 'http://x', client: client);
    expect(
      () => api.save('demo', AppConfig.demo),
      throwsA(allOf(isA<Exception>(), isNot(isA<SessionExpiredException>()))),
    );
  });
}

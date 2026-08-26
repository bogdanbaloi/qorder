import 'package:qorder_bff/consent_store.dart';
import 'package:qorder_bff/identity_store.dart';
import 'package:qorder_bff/order_api.dart';
import 'package:qorder_bff/order_store.dart';
import 'package:qorder_bff/redemption_store.dart';
import 'package:qorder_bff/request_store.dart';
import 'package:qorder_bff/staff_auth_store.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

/// REQ-SEC-009 (CORS origin is configurable) and REQ-SEC-010 (the operator token
/// is compared in constant time, and the compare stays correct).
Handler _handler({String allowedOrigin = '*', String? operatorToken}) => OrderApi(
      InMemoryOrderStore(),
      InMemoryWaiterRequestStore(),
      InMemoryRedemptionStore(),
      InMemoryIdentityStore(),
      InMemoryConsentStore(),
      InMemoryStaffAuthStore(codesByVenue: const {}),
      allowedOrigin: allowedOrigin,
      operatorToken: operatorToken,
    ).handler;

Future<String?> _corsOrigin(Handler h) async {
  final res = await h(
    Request('OPTIONS', Uri.parse('http://x/venues/demo/config')),
  );
  return res.headers['access-control-allow-origin'];
}

Future<int> _metrics(Handler h, String token) async {
  final res = await h(
    Request(
      'GET',
      Uri.parse('http://x/platform/metrics'),
      headers: {'authorization': 'Bearer $token'},
    ),
  );
  return res.statusCode;
}

void main() {
  test('CORS allows any origin by default (dev/demo)', () async {
    expect(await _corsOrigin(_handler()), '*');
  });

  test('CORS can be locked to a configured origin', () async {
    const origin = 'https://app.qorder.ro';
    expect(await _corsOrigin(_handler(allowedOrigin: origin)), origin);
  });

  test('the operator token compare stays correct', () async {
    final h = _handler(operatorToken: 'secret-op-token');
    // Exact token passes.
    expect(await _metrics(h, 'secret-op-token'), 200);
    // A wrong token is refused.
    expect(await _metrics(h, 'wrong'), 403);
    // A prefix of the token is refused (no early accept).
    expect(await _metrics(h, 'secret-op'), 403);
  });
}

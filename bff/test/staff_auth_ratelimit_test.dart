import 'dart:convert';

import 'package:qorder_bff/consent_store.dart';
import 'package:qorder_bff/identity_store.dart';
import 'package:qorder_bff/order_api.dart';
import 'package:qorder_bff/order_store.dart';
import 'package:qorder_bff/rate_limiter.dart';
import 'package:qorder_bff/redemption_store.dart';
import 'package:qorder_bff/request_store.dart';
import 'package:qorder_bff/staff_auth_store.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

/// REQ-SEC-002: staff/owner sign-in is rate limited per IP, so the short access
/// code cannot be brute-forced.
Handler _handler({required int maxAttempts}) => OrderApi(
      InMemoryOrderStore(),
      InMemoryWaiterRequestStore(),
      InMemoryRedemptionStore(),
      InMemoryIdentityStore(),
      InMemoryConsentStore(),
      InMemoryStaffAuthStore(
        codesByVenue: {
          'demo': {'staff': '2468', 'owner': '1357'},
        },
      ),
      staffAuthLimiter: RateLimiter(
        maxPerWindow: maxAttempts,
        window: const Duration(minutes: 1),
      ),
    ).handler;

Future<Response> _auth(Handler handler, String code) async => handler(
      Request(
        'POST',
        Uri.parse('http://x/venues/demo/staff/auth'),
        body: jsonEncode({'role': 'staff', 'code': code}),
      ),
    );

void main() {
  test('sign-in is rate limited per IP', () async {
    final handler = _handler(maxAttempts: 3);

    // Three wrong-code attempts are allowed (each a 401, not rate limited).
    for (var i = 0; i < 3; i++) {
      expect((await _auth(handler, '0000')).statusCode, 401);
    }

    // Over the budget the guard fires before auth, so even the correct code is
    // refused with 429.
    expect((await _auth(handler, '2468')).statusCode, 429);
  });

  test('a normal sign-in within the budget succeeds', () async {
    final handler = _handler(maxAttempts: 10);
    expect((await _auth(handler, '2468')).statusCode, 200);
  });
}

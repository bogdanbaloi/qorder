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

/// REQ-SEC-005 and REQ-SEC-006: the public write routes are bounded, so a huge
/// body cannot exhaust memory and a spammer cannot flood them.
Handler _handler({RateLimiter? writeLimiter}) => OrderApi(
      InMemoryOrderStore(),
      InMemoryWaiterRequestStore(),
      InMemoryRedemptionStore(),
      InMemoryIdentityStore(),
      InMemoryConsentStore(),
      InMemoryStaffAuthStore(codesByVenue: const {}),
      publicWriteLimiter: writeLimiter,
    ).handler;

Future<int> _submit(Handler h, String body) async {
  final res = await h(
    Request('POST', Uri.parse('http://x/venues/demo/orders'), body: body),
  );
  return res.statusCode;
}

void main() {
  // REQ-SEC-005: a body over the cap is refused before it is read.
  test('a huge request body is rejected with 413', () async {
    final big = jsonEncode({'tableNumber': 1, 'blob': 'x' * 70000});
    expect(await _submit(_handler(), big), 413);
  });

  // REQ-SEC-006: public submits are bounded per caller IP.
  test('public writes are rate limited per IP', () async {
    final h = _handler(
      writeLimiter: RateLimiter(
        maxPerWindow: 2,
        window: const Duration(minutes: 1),
      ),
    );
    final order = jsonEncode({'tableNumber': 1, 'lines': [], 'totalMinor': 0});

    expect(await _submit(h, order), 200);
    expect(await _submit(h, order), 200);
    // Over the budget the next submit is refused.
    expect(await _submit(h, order), 429);
  });
}

import 'dart:convert';

import 'package:qorder_bff/consent_store.dart';
import 'package:qorder_bff/identity_store.dart';
import 'package:qorder_bff/order_api.dart';
import 'package:qorder_bff/order_store.dart';
import 'package:qorder_bff/redemption_store.dart';
import 'package:qorder_bff/request_store.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

// REQ-IDENT-003: a known customer's data requires a matching bearer token; an
// anonymous key is self-scoped. Stops reading someone's history by guessing the
// customerId (which derives from their phone).
Handler _handler() => OrderApi(
  InMemoryOrderStore(),
  InMemoryWaiterRequestStore(),
  InMemoryRedemptionStore(),
  InMemoryIdentityStore(codeGen: () => '123456', tokenGen: () => 'tok-1'),
  InMemoryConsentStore(),
).handler;

Future<Response> _get(Handler h, String path, {String? token}) async => h(
  Request(
    'GET',
    Uri.parse('http://x$path'),
    headers: {if (token != null) 'authorization': 'Bearer $token'},
  ),
);

void main() {
  test('anonymous key needs no token', () async {
    final h = _handler();
    final res = await _get(h, '/venues/demo/customers/anon-device/orders');
    expect(res.statusCode, 200);
  });

  test('a known customer needs a matching token', () async {
    final h = _handler();
    // Verify a customer to make cust:0740 a known customer with token tok-1.
    final start = await h(
      Request(
        'POST',
        Uri.parse('http://x/auth/otp/start'),
        body: jsonEncode({'phone': '0740'}),
      ),
    );
    final challengeId =
        (jsonDecode(await start.readAsString()) as Map)['challengeId'] as String;
    await h(
      Request(
        'POST',
        Uri.parse('http://x/auth/otp/verify'),
        body: jsonEncode({'challengeId': challengeId, 'code': '123456'}),
      ),
    );

    const path = '/venues/demo/customers/cust:0740/orders';
    expect((await _get(h, path)).statusCode, 403); // no token
    expect((await _get(h, path, token: 'wrong')).statusCode, 403);
    expect((await _get(h, path, token: 'tok-1')).statusCode, 200);
  });
}

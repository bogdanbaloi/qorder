import 'dart:convert';

import 'package:qorder_bff/consent_store.dart';
import 'package:qorder_bff/identity_store.dart';
import 'package:qorder_bff/order_api.dart';
import 'package:qorder_bff/order_store.dart';
import 'package:qorder_bff/redemption_store.dart';
import 'package:qorder_bff/request_store.dart';
import 'package:qorder_bff/staff_auth_store.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

Handler _api({String? operatorToken}) => OrderApi(
      InMemoryOrderStore(),
      InMemoryWaiterRequestStore(),
      InMemoryRedemptionStore(),
      InMemoryIdentityStore(),
      InMemoryConsentStore(),
      InMemoryStaffAuthStore(codesByVenue: const {}),
      operatorToken: operatorToken,
    ).handler;

void main() {
  test('operator metrics need the operator token', () async {
    final handler = _api(operatorToken: 'op-secret');

    final noToken = await handler(
      Request('GET', Uri.parse('http://x/platform/metrics')),
    );
    expect(noToken.statusCode, 403);

    final ok = await handler(
      Request(
        'GET',
        Uri.parse('http://x/platform/metrics'),
        headers: {'authorization': 'Bearer op-secret'},
      ),
    );
    expect(ok.statusCode, 200);
    final body = jsonDecode(await ok.readAsString()) as Map<String, dynamic>;
    expect(body['venueCount'], 0); // empty store with no database
  });

  test('operator routes are off when no token is configured', () async {
    final handler = _api(); // no operator token
    final res = await handler(
      Request(
        'GET',
        Uri.parse('http://x/platform/metrics'),
        headers: {'authorization': 'Bearer anything'},
      ),
    );
    expect(res.statusCode, 403);
  });
}

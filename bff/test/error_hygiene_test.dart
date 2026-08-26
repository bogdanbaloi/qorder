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

/// REQ-SEC-011: an uncaught error (e.g. a malformed body) returns a generic 500,
/// never a stack trace or an exception message that leaks internals.
void main() {
  Handler handler() => OrderApi(
        InMemoryOrderStore(),
        InMemoryWaiterRequestStore(),
        InMemoryRedemptionStore(),
        InMemoryIdentityStore(),
        InMemoryConsentStore(),
        InMemoryStaffAuthStore(codesByVenue: const {}),
      ).handler;

  test('a malformed body returns a generic 500 without leaking internals',
      () async {
    final res = await handler()(
      Request(
        'POST',
        Uri.parse('http://x/venues/demo/orders'),
        body: '{ not valid json',
      ),
    );

    expect(res.statusCode, 500);
    final body = await res.readAsString();
    expect(body, isNot(contains('FormatException')));
    expect(body, isNot(contains('#0'))); // no stack frame
    expect(jsonDecode(body), {'error': 'internal error'});
  });
}

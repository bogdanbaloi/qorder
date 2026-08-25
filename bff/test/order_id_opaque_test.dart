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

/// REQ-SEC-003: the order id is opaque, so the public status route cannot be
/// enumerated by counting sequences.
void main() {
  Handler handler() => OrderApi(
        InMemoryOrderStore(),
        InMemoryWaiterRequestStore(),
        InMemoryRedemptionStore(),
        InMemoryIdentityStore(),
        InMemoryConsentStore(),
        InMemoryStaffAuthStore(codesByVenue: const {}),
      ).handler;

  Future<String> submit(Handler h) async {
    final res = await h(
      Request(
        'POST',
        Uri.parse('http://x/venues/demo/orders'),
        body: jsonEncode({
          'tableNumber': 5,
          'lines': [
            {'name': 'Beer', 'qty': 1},
          ],
          'totalMinor': 1000,
        }),
      ),
    );
    final body = jsonDecode(await res.readAsString()) as Map<String, dynamic>;
    return body['serverOrderId'] as String;
  }

  Future<int> statusCode(Handler h, String id) async {
    final res = await h(Request('GET', Uri.parse('http://x/orders/$id/status')));
    return res.statusCode;
  }

  test('the order id is not the guessable sequence form', () async {
    final id = await submit(handler());
    expect(id, isNot('BFF-demo-1'));
    expect(id, startsWith('BFF-demo-1-')); // readable seq, opaque suffix
  });

  test('guessing the sequence id does not resolve, the real id does', () async {
    final h = handler();
    final id = await submit(h);

    // Walking the sequence (the old enumeration) now misses.
    expect(await statusCode(h, 'BFF-demo-1'), 404);
    // The real, opaque id still works for the customer who holds it.
    expect(await statusCode(h, id), 200);
  });
}

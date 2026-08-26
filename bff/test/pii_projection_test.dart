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

/// REQ-SEC-012 and REQ-SEC-013: the public reads return only what they need, not
/// the order's or the patrons' PII.
void main() {
  Handler handler() => OrderApi(
        InMemoryOrderStore(),
        InMemoryWaiterRequestStore(),
        InMemoryRedemptionStore(),
        InMemoryIdentityStore(),
        InMemoryConsentStore(),
        InMemoryStaffAuthStore(codesByVenue: const {}),
      ).handler;

  Future<Map<String, dynamic>> submit(Handler h) async {
    final res = await h(
      Request(
        'POST',
        Uri.parse('http://x/venues/demo/orders'),
        body: jsonEncode({
          'tableNumber': 5,
          'clientId': 'alice',
          'customerName': 'Alice',
          'totalMinor': 1000,
          'lines': [
            {'name': 'Beer', 'qty': 1},
          ],
        }),
      ),
    );
    return jsonDecode(await res.readAsString()) as Map<String, dynamic>;
  }

  // REQ-SEC-012: the public status poll returns the stage, not the order PII.
  test('order status is a projection without PII', () async {
    final h = handler();
    final id = (await submit(h))['serverOrderId'] as String;

    final res =
        await h(Request('GET', Uri.parse('http://x/orders/$id/status')));
    final body = jsonDecode(await res.readAsString()) as Map<String, dynamic>;

    expect(body['stage'], isNotNull); // what the poll needs
    expect(body.containsKey('customerName'), isFalse);
    expect(body.containsKey('clientId'), isFalse);
    expect(body.containsKey('lines'), isFalse);
    expect(body.containsKey('totalMinor'), isFalse);
  });

  // REQ-SEC-013: the shared-table entries do not carry each patron's clientId.
  test('table entries do not expose the clientId', () async {
    final h = handler();
    await submit(h);

    final res = await h(
      Request('GET', Uri.parse('http://x/venues/demo/tables/5/orders?clientId=alice')),
    );
    final body = jsonDecode(await res.readAsString()) as Map<String, dynamic>;
    final entry = (body['entries'] as List).single as Map<String, dynamic>;

    expect(entry['name'], 'Alice');
    expect(entry['isMine'], isTrue);
    expect(entry.containsKey('clientId'), isFalse);
  });
}

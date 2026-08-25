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

/// REQ-SEC-004: the shared-table view is visible only to a patron on that table
/// (a device with an order there), so an outsider cannot enumerate tables and
/// scrape names and orders.
void main() {
  Handler handler() => OrderApi(
        InMemoryOrderStore(),
        InMemoryWaiterRequestStore(),
        InMemoryRedemptionStore(),
        InMemoryIdentityStore(),
        InMemoryConsentStore(),
        InMemoryStaffAuthStore(codesByVenue: const {}),
      ).handler;

  Future<void> submit(Handler h, String clientId, int table) async {
    await h(
      Request(
        'POST',
        Uri.parse('http://x/venues/demo/orders'),
        body: jsonEncode({
          'tableNumber': table,
          'clientId': clientId,
          'customerName': 'Alice',
          'lines': [
            {'name': 'Beer', 'qty': 1},
          ],
        }),
      ),
    );
  }

  Future<List<dynamic>> tableEntries(Handler h, String query) async {
    final res = await h(
      Request('GET', Uri.parse('http://x/venues/demo/tables/5/orders$query')),
    );
    final body = jsonDecode(await res.readAsString()) as Map<String, dynamic>;
    return body['entries'] as List;
  }

  test('a patron on the table sees the orders', () async {
    final h = handler();
    await submit(h, 'alice', 5);
    expect(await tableEntries(h, '?clientId=alice'), isNotEmpty);
  });

  test('an outsider sees nothing (no enumeration)', () async {
    final h = handler();
    await submit(h, 'alice', 5);
    // A client with no order on the table gets an empty view.
    expect(await tableEntries(h, '?clientId=eve'), isEmpty);
    // No client id at all is also empty.
    expect(await tableEntries(h, ''), isEmpty);
  });
}

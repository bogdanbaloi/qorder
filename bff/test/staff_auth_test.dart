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

// REQ-STAFF-002: the BFF verifies a venue's access code and issues a scoped
// staff/owner token; staff/owner routes require a matching token (per-tenant),
// and the owner metrics need the owner role.
void main() {
  test('authenticate checks the venue code and scopes the token', () {
    final store = InMemoryStaffAuthStore(
      codesByVenue: {
        'demo': {'staff': '2468', 'owner': '1357'},
      },
      tokenGen: () => 'tok',
    );
    expect(store.authenticate('demo', 'staff', '0000'), isNull); // wrong
    expect(store.authenticate('other', 'staff', '2468'), isNull); // no venue
    final token = store.authenticate('demo', 'staff', '2468');
    expect(token, 'tok');
    expect(store.claims('tok')?.venueId, 'demo');
    expect(store.claims('tok')?.role, 'staff');
  });

  test('metrics needs an owner token; a staff token is forbidden', () async {
    final staff = InMemoryStaffAuthStore(
      codesByVenue: {
        'demo': {'staff': '2468', 'owner': '1357'},
      },
    );
    final handler = OrderApi(
      InMemoryOrderStore(),
      InMemoryWaiterRequestStore(),
      InMemoryRedemptionStore(),
      InMemoryIdentityStore(),
      InMemoryConsentStore(),
      staff,
    ).handler;

    Future<String> auth(String role, String code) async {
      final res = await handler(
        Request(
          'POST',
          Uri.parse('http://x/venues/demo/staff/auth'),
          body: jsonEncode({'role': role, 'code': code}),
        ),
      );
      return (jsonDecode(await res.readAsString()) as Map)['token'] as String;
    }

    final staffToken = await auth('staff', '2468');
    final ownerToken = await auth('owner', '1357');
    const path = 'http://x/venues/demo/metrics';

    expect((await handler(Request('GET', Uri.parse(path)))).statusCode, 403);
    expect(
      (await handler(
        Request(
          'GET',
          Uri.parse(path),
          headers: {'authorization': 'Bearer $staffToken'},
        ),
      )).statusCode,
      403, // staff cannot read owner metrics
    );
    expect(
      (await handler(
        Request(
          'GET',
          Uri.parse(path),
          headers: {'authorization': 'Bearer $ownerToken'},
        ),
      )).statusCode,
      200,
    );
  });
}

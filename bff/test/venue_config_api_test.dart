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

/// REQ-CFG-004: the venue config endpoints. GET is open (the customer app reads
/// it). PUT is owner-only, since it changes what every customer sees.
void main() {
  late Handler handler;
  late String ownerToken;
  late String staffToken;

  setUp(() {
    final staff = InMemoryStaffAuthStore(
      codesByVenue: {
        'demo': {'staff': '2468', 'owner': '1357'},
      },
    );
    ownerToken = staff.authenticate('demo', 'owner', '1357')!;
    staffToken = staff.authenticate('demo', 'staff', '2468')!;
    handler = OrderApi(
      InMemoryOrderStore(),
      InMemoryWaiterRequestStore(),
      InMemoryRedemptionStore(),
      InMemoryIdentityStore(),
      InMemoryConsentStore(),
      staff,
    ).handler;
  });

  Future<Response> get() async => handler(
        Request('GET', Uri.parse('http://x/venues/demo/config')),
      );

  Future<Response> put(String token, Map<String, dynamic> doc) async => handler(
        Request(
          'PUT',
          Uri.parse('http://x/venues/demo/config'),
          headers: {'authorization': 'Bearer $token'},
          body: jsonEncode(doc),
        ),
      );

  test('GET is 404 until a config is saved', () async {
    expect((await get()).statusCode, 404);
  });

  test('the owner saves a config and it reads back', () async {
    final saved = await put(ownerToken, {'branding': {'venueName': 'Noul Local'}});
    expect(saved.statusCode, 200);

    final read = await get();
    expect(read.statusCode, 200);
    final doc = jsonDecode(await read.readAsString()) as Map<String, dynamic>;
    expect((doc['branding'] as Map)['venueName'], 'Noul Local');
  });

  test('a staff token cannot write the config (owner-only)', () async {
    expect((await put(staffToken, {'branding': {}})).statusCode, 403);
  });
}

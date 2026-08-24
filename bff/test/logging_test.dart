import 'dart:convert';

import 'package:qorder_bff/consent_store.dart';
import 'package:qorder_bff/identity_store.dart';
import 'package:qorder_bff/logging.dart';
import 'package:qorder_bff/order_api.dart';
import 'package:qorder_bff/order_store.dart';
import 'package:qorder_bff/redemption_store.dart';
import 'package:qorder_bff/request_store.dart';
import 'package:qorder_bff/staff_auth_store.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

/// REQ-OBS-002: a refused auth is logged with its reason, so a 403 is not silent.
void main() {
  test('BffLog respects the level floor', () {
    final lines = <String>[];
    final log = BffLog(floor: BffLogLevel.warning, sink: lines.add);
    log.info('quiet');
    log.warning('loud');
    expect(lines.length, 1);
    expect(lines.single, contains('[WARNING]'));
    expect(lines.single, contains('loud'));
  });

  test('a refused owner write logs why', () async {
    final lines = <String>[];
    final staff = InMemoryStaffAuthStore(
      codesByVenue: {
        'demo': {'staff': '2468', 'owner': '1357'},
      },
    );
    final staffToken = staff.authenticate('demo', 'staff', '2468')!;
    final handler = OrderApi(
      InMemoryOrderStore(),
      InMemoryWaiterRequestStore(),
      InMemoryRedemptionStore(),
      InMemoryIdentityStore(),
      InMemoryConsentStore(),
      staff,
      log: BffLog(sink: lines.add),
    ).handler;

    // A staff token on the owner-only config write is refused.
    final res = await handler(
      Request(
        'PUT',
        Uri.parse('http://x/venues/demo/config'),
        headers: {'authorization': 'Bearer $staffToken'},
        body: jsonEncode({'branding': {}}),
      ),
    );

    expect(res.statusCode, 403);
    expect(
      lines.any((l) => l.contains('[WARNING]') && l.contains('not owner')),
      isTrue,
    );
  });
}

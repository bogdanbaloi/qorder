import 'dart:convert';

import 'package:qorder_bff/consent_store.dart';
import 'package:qorder_bff/identity_store.dart';
import 'package:qorder_bff/log_store.dart';
import 'package:qorder_bff/order_api.dart';
import 'package:qorder_bff/order_store.dart';
import 'package:qorder_bff/rate_limiter.dart';
import 'package:qorder_bff/redemption_store.dart';
import 'package:qorder_bff/request_store.dart';
import 'package:qorder_bff/staff_auth_store.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

/// REQ-OBS-003: apps ship warnings to POST /logs (public, bounded). The operator
/// reads them back from GET /logs (behind the operator token).
void main() {
  Handler api(LogStore logs, {RateLimiter? limiter}) => OrderApi(
        InMemoryOrderStore(),
        InMemoryWaiterRequestStore(),
        InMemoryRedemptionStore(),
        InMemoryIdentityStore(),
        InMemoryConsentStore(),
        InMemoryStaffAuthStore(codesByVenue: const {}),
        operatorToken: 'op-secret',
        logs: logs,
        clientLogLimiter: limiter,
      ).handler;

  Future<Response> postLog(Handler h, Object body) async => h(
        Request(
          'POST',
          Uri.parse('http://x/logs'),
          body: jsonEncode(body),
        ),
      );

  test('a shipped warning is stored and readable by the operator', () async {
    final logs = InMemoryLogStore();
    final h = api(logs);

    final res = await postLog(h, {
      'records': [
        {
          'level': 'warning',
          'message': 'config fetch failed',
          'venueId': 'demo'
        },
      ],
    });
    expect(res.statusCode, 200);

    final read = await h(
      Request(
        'GET',
        Uri.parse('http://x/logs'),
        headers: {'authorization': 'Bearer op-secret'},
      ),
    );
    expect(read.statusCode, 200);
    final list = jsonDecode(await read.readAsString()) as List;
    expect(list.length, 1);
    expect((list.single as Map)['message'], 'config fetch failed');
    expect((list.single as Map)['venueId'], 'demo');
  });

  test('GET /logs needs the operator token', () async {
    final res = await api(InMemoryLogStore())(
      Request('GET', Uri.parse('http://x/logs')),
    );
    expect(res.statusCode, 403);
  });

  test('the batch is capped and empty messages are dropped', () async {
    final logs = InMemoryLogStore();
    final h = api(logs);
    await postLog(h, {
      'records': [
        for (var i = 0; i < 200; i++) {'level': 'error', 'message': 'e$i'},
        {'level': 'warning', 'message': '   '},
      ],
    });
    final stored = await logs.recent(limit: 1000);
    expect(stored.length, 50); // capped at 50, the blank one dropped
  });

  test('the endpoint is rate limited per caller', () async {
    final h = api(
      InMemoryLogStore(),
      limiter: RateLimiter(maxPerWindow: 1, window: const Duration(minutes: 1)),
    );
    final one = {
      'records': [
        {'level': 'warning', 'message': 'x'},
      ],
    };
    expect((await postLog(h, one)).statusCode, 200);
    expect((await postLog(h, one)).statusCode, 429);
  });
}

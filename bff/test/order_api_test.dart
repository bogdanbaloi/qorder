import 'dart:convert';

import 'package:qorder_bff/order_api.dart';
import 'package:qorder_bff/order_store.dart';
import 'package:qorder_bff/redemption_store.dart';
import 'package:qorder_bff/request_store.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

Future<Map<String, dynamic>> _bodyJson(Response r) async =>
    jsonDecode(await r.readAsString()) as Map<String, dynamic>;

void main() {
  test('submit -> pending -> accept -> status over HTTP', () async {
    final handler =
        OrderApi(
          InMemoryOrderStore(),
          InMemoryWaiterRequestStore(),
          InMemoryRedemptionStore(),
        ).handler;

    final submit = await handler(
      Request(
        'POST',
        Uri.parse('http://x/venues/demo/orders'),
        body: jsonEncode({
          'tableNumber': 7,
          'idempotencyKey': 'k1',
          'customerName': 'Andrei',
          'lines': const [],
        }),
      ),
    );
    expect(submit.statusCode, 200);
    final placed = await _bodyJson(submit);
    final id = placed['serverOrderId'] as String;
    expect(placed['stage'], 'pendingAcceptance');
    expect(placed['tableNumber'], 7);

    final pending = await handler(
      Request('GET', Uri.parse('http://x/venues/demo/orders/pending')),
    );
    final list = jsonDecode(await pending.readAsString()) as List;
    expect(list.length, 1);

    final accept = await handler(
      Request('POST', Uri.parse('http://x/orders/$id/accept')),
    );
    expect(accept.statusCode, 200);
    expect((await _bodyJson(accept))['stage'], 'received');

    final status = await handler(
      Request('GET', Uri.parse('http://x/orders/$id/status')),
    );
    expect((await _bodyJson(status))['stage'], 'received');
  });

  test('table orders lists what is on the table, marking mine', () async {
    final handler =
        OrderApi(
          InMemoryOrderStore(),
          InMemoryWaiterRequestStore(),
          InMemoryRedemptionStore(),
        ).handler;
    Future<void> submit(String client, String who, int table) async {
      await handler(
        Request(
          'POST',
          Uri.parse('http://x/venues/demo/orders'),
          body: jsonEncode({
            'tableNumber': table,
            'clientId': client,
            'customerName': who,
            'lines': [
              {'name': 'Beer', 'qty': 1},
            ],
          }),
        ),
      );
    }

    await submit('me', 'Andrei', 7);
    await submit('you', 'Radu', 7);

    final res = await handler(
      Request(
          'GET', Uri.parse('http://x/venues/demo/tables/7/orders?clientId=me')),
    );
    final body = await _bodyJson(res);
    expect(body['tableNumber'], 7);
    final entries = (body['entries'] as List).cast<Map<String, dynamic>>();
    expect(entries.length, 2);
    final mine = entries.where((e) => e['isMine'] == true).toList();
    expect(mine.length, 1);
    expect(mine.single['name'], 'Andrei');
  });

  test('accept on an unknown id is 404', () async {
    final handler =
        OrderApi(
          InMemoryOrderStore(),
          InMemoryWaiterRequestStore(),
          InMemoryRedemptionStore(),
        ).handler;
    final res = await handler(
      Request('POST', Uri.parse('http://x/orders/nope/accept')),
    );
    expect(res.statusCode, 404);
  });

  test('raise -> list -> resolve waiter requests over HTTP', () async {
    final handler =
        OrderApi(
          InMemoryOrderStore(),
          InMemoryWaiterRequestStore(),
          InMemoryRedemptionStore(),
        ).handler;

    final raised = await handler(
      Request(
        'POST',
        Uri.parse('http://x/venues/demo/tables/7/requests'),
        body: jsonEncode({'kind': 'bill', 'customerName': 'Andrei'}),
      ),
    );
    expect(raised.statusCode, 200);
    final req = await _bodyJson(raised);
    final id = req['id'] as String;
    expect(req['kind'], 'bill');
    expect(req['tableNumber'], 7);

    // Idempotent per (table, kind): a second bill request does not pile up.
    await handler(
      Request(
        'POST',
        Uri.parse('http://x/venues/demo/tables/7/requests'),
        body: jsonEncode({'kind': 'bill'}),
      ),
    );

    final list = await handler(
      Request('GET', Uri.parse('http://x/venues/demo/requests')),
    );
    expect((jsonDecode(await list.readAsString()) as List).length, 1);

    final resolve = await handler(
      Request('POST', Uri.parse('http://x/requests/$id/resolve')),
    );
    expect(resolve.statusCode, 200);

    final after = await handler(
      Request('GET', Uri.parse('http://x/venues/demo/requests')),
    );
    expect(jsonDecode(await after.readAsString()) as List, isEmpty);
  });

  test('resolve on an unknown request id is 404', () async {
    final handler =
        OrderApi(
          InMemoryOrderStore(),
          InMemoryWaiterRequestStore(),
          InMemoryRedemptionStore(),
        ).handler;
    final res = await handler(
      Request('POST', Uri.parse('http://x/requests/nope/resolve')),
    );
    expect(res.statusCode, 404);
  });

  test('accept -> ready -> delivered stamps the order over HTTP', () async {
    final handler =
        OrderApi(
          InMemoryOrderStore(),
          InMemoryWaiterRequestStore(),
          InMemoryRedemptionStore(),
        ).handler;

    final submit = await handler(
      Request(
        'POST',
        Uri.parse('http://x/venues/demo/orders'),
        body: jsonEncode({
          'tableNumber': 7,
          'idempotencyKey': 'k1',
          'lines': const [],
        }),
      ),
    );
    final id = (await _bodyJson(submit))['serverOrderId'] as String;

    await handler(Request('POST', Uri.parse('http://x/orders/$id/accept')));

    final inprog = await handler(
      Request('GET', Uri.parse('http://x/venues/demo/orders/inprogress')),
    );
    expect((jsonDecode(await inprog.readAsString()) as List).length, 1);

    await handler(Request('POST', Uri.parse('http://x/orders/$id/ready')));
    final delivered = await handler(
      Request('POST', Uri.parse('http://x/orders/$id/delivered')),
    );
    expect(delivered.statusCode, 200);
    final stamps =
        (await _bodyJson(delivered))['stamps'] as Map<String, dynamic>;
    expect(stamps.keys.toSet(), {
      'submitted',
      'accepted',
      'ready',
      'delivered',
    });

    // A delivered order leaves the in-progress list.
    final after = await handler(
      Request('GET', Uri.parse('http://x/venues/demo/orders/inprogress')),
    );
    expect(jsonDecode(await after.readAsString()) as List, isEmpty);
  });

  test('ready on an unknown order id is 404', () async {
    final handler =
        OrderApi(
          InMemoryOrderStore(),
          InMemoryWaiterRequestStore(),
          InMemoryRedemptionStore(),
        ).handler;
    final res = await handler(
      Request('POST', Uri.parse('http://x/orders/nope/ready')),
    );
    expect(res.statusCode, 404);
  });
}

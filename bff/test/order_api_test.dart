import 'dart:convert';

import 'package:qorder_bff/order_api.dart';
import 'package:qorder_bff/order_store.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

Future<Map<String, dynamic>> _bodyJson(Response r) async =>
    jsonDecode(await r.readAsString()) as Map<String, dynamic>;

void main() {
  test('submit -> pending -> accept -> status over HTTP', () async {
    final handler = OrderApi(InMemoryOrderStore()).handler;

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

  test('accept on an unknown id is 404', () async {
    final handler = OrderApi(InMemoryOrderStore()).handler;
    final res = await handler(
      Request('POST', Uri.parse('http://x/orders/nope/accept')),
    );
    expect(res.statusCode, 404);
  });
}

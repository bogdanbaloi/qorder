import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qorder/core/money.dart';
import 'package:qorder/data/ordering/remote_backend.dart';
import 'package:qorder/domain/models/cart.dart';
import 'package:qorder/domain/models/order.dart';
import 'package:qorder/domain/models/table_ref.dart';

Order _order() => const Order(
  id: 'ord-1',
  idempotencyKey: 'k1',
  venueId: 'demo',
  customerName: 'Andrei',
  tableRef: TableRef(number: 5, source: TableSource.manual, validated: true),
  lines: [
    CartLine(
      id: 'l1',
      itemId: 'b',
      nameSnapshot: 'Beer',
      unitPriceSnapshot: Money(1000),
      qty: 1,
    ),
  ],
  total: Money(1000),
);

RemoteBackend _backend(MockClient client) =>
    RemoteBackend(baseUrl: 'http://bff', client: client);

void main() {
  test('submitOrder POSTs to the venue and parses the confirmation', () async {
    late http.Request captured;
    final backend = _backend(
      MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'serverOrderId': 'BFF-1',
            'sequence': 3,
            'stage': 'pendingAcceptance',
          }),
          200,
        );
      }),
    );

    final result = await backend.submitOrder(_order());

    expect(result, isA<SubmitConfirmed>());
    final confirmed = result as SubmitConfirmed;
    expect(confirmed.serverOrderId, 'BFF-1');
    expect(confirmed.sequence, 3);
    expect(captured.method, 'POST');
    expect(captured.url.path, '/venues/demo/orders');
    expect(
      (jsonDecode(captured.body) as Map<String, dynamic>)['idempotencyKey'],
      'k1',
    );
  });

  test('submitOrder maps a server error to a retryable failure', () async {
    final backend = _backend(MockClient((_) async => http.Response('no', 500)));
    final result = await backend.submitOrder(_order());
    expect(result, isA<SubmitFailed>());
    expect((result as SubmitFailed).retryable, true);
  });

  test('pending parses the awaiting list', () async {
    final backend = _backend(
      MockClient(
        (_) async => http.Response(
          jsonEncode([
            {
              'serverOrderId': 'BFF-1',
              'venueId': 'demo',
              'tableNumber': 5,
              'sequence': 1,
              'customerName': 'Andrei',
            },
          ]),
          200,
        ),
      ),
    );

    final list = await backend.pending('demo');

    expect(list.length, 1);
    expect(list.single.serverOrderId, 'BFF-1');
    expect(list.single.tableNumber, 5);
    expect(list.single.customerName, 'Andrei');
  });

  test('accept POSTs to the accept endpoint', () async {
    late Uri url;
    final backend = _backend(
      MockClient((request) async {
        url = request.url;
        return http.Response('', 200);
      }),
    );

    await backend.accept('BFF-1');

    expect(url.path, '/orders/BFF-1/accept');
  });
}

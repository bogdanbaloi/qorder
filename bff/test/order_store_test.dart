import 'package:qorder_bff/models.dart';
import 'package:qorder_bff/order_store.dart';
import 'package:test/test.dart';

Map<String, dynamic> _order({
  String key = 'k1',
  int table = 5,
  String clientId = 'me',
}) =>
    {
      'idempotencyKey': key,
      'tableNumber': table,
      'customerName': 'Andrei',
      'clientId': clientId,
      'lines': [
        {'name': 'Beer', 'qty': 1},
      ],
    };

void main() {
  test('submit holds an order pending, accept releases it', () async {
    final store = InMemoryOrderStore(requiresWaiter: true);
    final placed = await store.submit(venueId: 'demo', order: _order());

    expect(placed.stage, OrderStage.pendingAcceptance);
    expect(placed.sequence, 1);
    expect((await store.pending('demo')).length, 1);

    final accepted = await store.accept('demo', placed.serverOrderId);
    expect(accepted!.stage, OrderStage.received);
    expect(await store.pending('demo'), isEmpty);
    final status = await store.status(placed.serverOrderId);
    expect(status!.stage, OrderStage.received);
  });

  test('idempotent: the same key returns the same order', () async {
    final store = InMemoryOrderStore();
    final a = await store.submit(venueId: 'demo', order: _order(key: 'dup'));
    final b = await store.submit(venueId: 'demo', order: _order(key: 'dup'));
    expect(a.serverOrderId, b.serverOrderId);
    expect((await store.pending('demo')).length, 1);
  });

  test('auto mode does not hold an order pending', () async {
    final store = InMemoryOrderStore(requiresWaiter: false);
    final placed = await store.submit(venueId: 'demo', order: _order());
    expect(placed.stage, OrderStage.received);
    expect(await store.pending('demo'), isEmpty);
  });

  test('pending is scoped by venue', () async {
    final store = InMemoryOrderStore();
    await store.submit(venueId: 'demo', order: _order(key: 'a'));
    expect(await store.pending('other'), isEmpty);
    expect((await store.pending('demo')).length, 1);
  });

  test('accept on an unknown id returns null', () async {
    expect(await InMemoryOrderStore().accept('demo', 'nope'), isNull);
  });

  test('a venue cannot accept another venue order', () async {
    final store = InMemoryOrderStore(requiresWaiter: true);
    final placed = await store.submit(venueId: 'demo', order: _order());
    expect(await store.accept('other', placed.serverOrderId), isNull);
    // The order stays pending, untouched by the wrong venue.
    expect((await store.pending('demo')).length, 1);
  });

  test('forTable returns only the orders on that table', () async {
    final store = InMemoryOrderStore();
    await store.submit(
        venueId: 'demo', order: _order(key: 'a', clientId: 'me'));
    await store.submit(venueId: 'demo', order: _order(key: 'b', table: 9));
    final onTable5 = await store.forTable('demo', 5);
    expect(onTable5.length, 1);
    expect(onTable5.single.clientId, 'me');
    expect(onTable5.single.tableNumber, 5);
  });
}

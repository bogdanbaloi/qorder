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
  test('submit holds an order pending, accept releases it', () {
    final store = InMemoryOrderStore(requiresWaiter: true);
    final placed = store.submit(venueId: 'demo', order: _order());

    expect(placed.stage, OrderStage.pendingAcceptance);
    expect(placed.sequence, 1);
    expect(store.pending('demo').length, 1);

    final accepted = store.accept(placed.serverOrderId);
    expect(accepted!.stage, OrderStage.received);
    expect(store.pending('demo'), isEmpty);
    expect(store.status(placed.serverOrderId)!.stage, OrderStage.received);
  });

  test('idempotent: the same key returns the same order', () {
    final store = InMemoryOrderStore();
    final a = store.submit(venueId: 'demo', order: _order(key: 'dup'));
    final b = store.submit(venueId: 'demo', order: _order(key: 'dup'));
    expect(a.serverOrderId, b.serverOrderId);
    expect(store.pending('demo').length, 1);
  });

  test('auto mode does not hold an order pending', () {
    final store = InMemoryOrderStore(requiresWaiter: false);
    final placed = store.submit(venueId: 'demo', order: _order());
    expect(placed.stage, OrderStage.received);
    expect(store.pending('demo'), isEmpty);
  });

  test('pending is scoped by venue', () {
    final store = InMemoryOrderStore();
    store.submit(venueId: 'demo', order: _order(key: 'a'));
    expect(store.pending('other'), isEmpty);
    expect(store.pending('demo').length, 1);
  });

  test('accept on an unknown id returns null', () {
    expect(InMemoryOrderStore().accept('nope'), isNull);
  });

  test('forTable returns only the orders on that table', () {
    final store = InMemoryOrderStore();
    store.submit(venueId: 'demo', order: _order(key: 'a', clientId: 'me'));
    store.submit(venueId: 'demo', order: _order(key: 'b', table: 9));
    final onTable5 = store.forTable('demo', 5);
    expect(onTable5.length, 1);
    expect(onTable5.single.clientId, 'me');
    expect(onTable5.single.tableNumber, 5);
  });
}

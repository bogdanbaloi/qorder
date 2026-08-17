import 'package:qorder_bff/order_store.dart';
import 'package:test/test.dart';

Map<String, dynamic> _order(String key, String client, int total) => {
      'idempotencyKey': key,
      'tableNumber': 5,
      'clientId': client,
      'totalMinor': total,
      'lines': <dynamic>[],
    };

void main() {
  test('forCustomer returns only that client\'s orders', () {
    final store = InMemoryOrderStore();
    store.submit(venueId: 'demo', order: _order('k1', 'me', 1000));
    store.submit(venueId: 'demo', order: _order('k2', 'other', 2000));
    store.submit(venueId: 'demo', order: _order('k3', 'me', 3000));

    final mine = store.forCustomer('demo', 'me');
    expect(mine.length, 2);
    expect(mine.every((o) => o.clientId == 'me'), isTrue);
    expect(mine.map((o) => o.totalMinor).toSet(), {1000, 3000});

    expect(store.forCustomer('demo', 'other').single.totalMinor, 2000);
    expect(store.forCustomer('demo', 'nobody'), isEmpty);
  });
}

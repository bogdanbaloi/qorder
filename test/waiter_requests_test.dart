import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/core/storage/local_store.dart';
import 'package:qorder/data/ordering/mock_ordering_service.dart';
import 'package:qorder/domain/waiter/waiter_request.dart';

MockOrderingService _mock() => MockOrderingService(
  sharedStore: InMemoryLocalStore(),
  seedDemo: false,
  latency: Duration.zero,
);

void main() {
  // REQ-CALL-001: a table can call the waiter or ask for the bill; the waiter
  // sees the request and resolves it. Idempotent per (table, kind).
  test('raise, list, resolve waiter requests (mock)', () async {
    final mock = _mock();
    expect(await mock.requests('demo'), isEmpty);

    await mock.raise(
      venueId: 'demo',
      tableNumber: 7,
      kind: WaiterRequestKind.callWaiter,
      customerName: 'Andrei',
    );
    // A second call of the same kind does not pile up (idempotent per key).
    await mock.raise(
      venueId: 'demo',
      tableNumber: 7,
      kind: WaiterRequestKind.callWaiter,
    );
    // A different kind is a distinct request.
    await mock.raise(
      venueId: 'demo',
      tableNumber: 7,
      kind: WaiterRequestKind.bill,
    );

    final list = await mock.requests('demo');
    expect(list.length, 2);
    expect(list.map((r) => r.kind).toSet(), {
      WaiterRequestKind.callWaiter,
      WaiterRequestKind.bill,
    });

    await mock.resolve(list.first.id);
    expect((await mock.requests('demo')).length, 1);
  });

  // REQ-CALL-001: requests never leak across venues.
  test('requests are scoped by venue', () async {
    final mock = _mock();
    await mock.raise(
      venueId: 'a',
      tableNumber: 1,
      kind: WaiterRequestKind.bill,
    );
    await mock.raise(
      venueId: 'b',
      tableNumber: 2,
      kind: WaiterRequestKind.bill,
    );
    expect((await mock.requests('a')).length, 1);
    expect((await mock.requests('a')).single.tableNumber, 1);
  });
}

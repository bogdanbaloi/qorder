import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/core/money.dart';
import 'package:qorder/core/storage/local_store.dart';
import 'package:qorder/data/outbox/outbox_repository.dart';
import 'package:qorder/domain/models/cart.dart';
import 'package:qorder/domain/models/pending_order.dart';

PendingOrder _pending(String key, int table) => PendingOrder(
  idempotencyKey: key,
  venueId: 'demo',
  tableNumber: table,
  lines: const [
    CartLine(
      id: 'l1',
      itemId: 'b',
      nameSnapshot: 'Beer',
      unitPriceSnapshot: Money(1000),
      qty: 2,
    ),
  ],
  totalMinor: 2000,
  createdAtMicros: 1,
  attempts: 1,
);

void main() {
  // REQ-RES-001: a pending order survives a "restart" (lives in the store,
  // not the repository), and round-trips through JSON intact.
  test(
    'outbox persists across repository instances (survives restart)',
    () async {
      final store = InMemoryLocalStore();
      await LocalStoreOutboxRepository(store).enqueue(_pending('k1', 12));

      // Fresh launch: a NEW repository over the SAME store.
      final pending = await LocalStoreOutboxRepository(
        store,
      ).pending('demo');
      expect(pending.length, 1);
      expect(pending.first.idempotencyKey, 'k1');
      expect(pending.first.tableNumber, 12);
      expect(pending.first.lines.first.lineTotal.amountMinor, 2000);
    },
  );

  test('remove clears the entry', () async {
    final store = InMemoryLocalStore();
    final repo = LocalStoreOutboxRepository(store);
    await repo.enqueue(_pending('k1', 12));
    await repo.remove('k1');
    expect(await repo.pending('demo'), isEmpty);
  });

  test('pending is scoped by venue', () async {
    final store = InMemoryLocalStore();
    final repo = LocalStoreOutboxRepository(store);
    await repo.enqueue(_pending('k1', 5));
    expect(await repo.pending('other'), isEmpty);
    expect((await repo.pending('demo')).length, 1);
  });
}

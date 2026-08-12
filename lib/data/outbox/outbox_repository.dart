import '../../core/storage/local_store.dart';
import '../../domain/models/pending_order.dart';

/// The outbox: durable, FIFO queue of orders waiting to be (re)sent. One
/// responsibility (Single Responsibility); depends only on the [LocalStore]
/// port (Dependency Inversion), so the engine underneath is swappable.
abstract interface class OutboxRepository {
  Future<void> enqueue(PendingOrder order);
  Future<List<PendingOrder>> pending(String venueId);
  Future<void> remove(String idempotencyKey);
}

class LocalStoreOutboxRepository implements OutboxRepository {
  static const _box = 'outbox';
  final LocalStore store;

  LocalStoreOutboxRepository(this.store);

  @override
  Future<void> enqueue(PendingOrder order) =>
      store.put(_box, order.idempotencyKey, order.toJson());

  @override
  Future<List<PendingOrder>> pending(String venueId) async {
    final rows = await store.all(_box);
    return rows
        .map(PendingOrder.fromJson)
        .where((p) => p.venueId == venueId)
        .toList();
  }

  @override
  Future<void> remove(String idempotencyKey) =>
      store.delete(_box, idempotencyKey);
}

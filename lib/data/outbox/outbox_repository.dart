import '../../core/storage/local_store.dart';
import '../../domain/models/pending_order.dart';
import '../../domain/repositories/outbox_repository.dart';

/// A [OutboxRepository] backed by a [LocalStore] port. The engine underneath is
/// swappable (in-memory for tests, shared_preferences on device/web, a
/// transactional store in Phase 1) without changing any caller.
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

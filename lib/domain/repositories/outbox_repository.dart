import '../models/pending_order.dart';

/// The outbox: a durable, FIFO queue of orders waiting to be (re)sent. One
/// responsibility (Single Responsibility). The concrete storage engine lives in
/// the data layer (Dependency Inversion), so it is swappable without touching
/// callers. Kept next to `MenuRepository`, so every port lives in the domain.
abstract interface class OutboxRepository {
  Future<void> enqueue(PendingOrder order);
  Future<List<PendingOrder>> pending(String venueId);
  Future<void> remove(String idempotencyKey);
}

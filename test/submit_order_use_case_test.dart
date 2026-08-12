import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/core/money.dart';
import 'package:qorder/core/storage/local_store.dart';
import 'package:qorder/data/outbox/outbox_repository.dart';
import 'package:qorder/domain/models/cart.dart';
import 'package:qorder/domain/models/order.dart';
import 'package:qorder/domain/models/table_orders.dart';
import 'package:qorder/domain/models/table_ref.dart';
import 'package:qorder/domain/services/ordering_service.dart';
import 'package:qorder/domain/usecases/submit_order_use_case.dart';

/// A hand-rolled `OrderingService` that returns a scripted `SubmitResult` and
/// counts how many times it was called. No Riverpod, no widgets: the use-case
/// is exercised in isolation.
class _FakeOrderingService implements OrderingService {
  final SubmitResult Function(int attempt) _reply;
  int calls = 0;

  _FakeOrderingService(this._reply);

  @override
  Future<SubmitResult> submitOrder(Order order) async {
    calls++;
    return _reply(calls);
  }

  @override
  Stream<OrderStatus> watchOrder(String orderId) => throw UnimplementedError();

  @override
  Future<TableOrders> tableOrders(
    String venueId,
    int tableNumber, {
    required String myClientId,
  }) => throw UnimplementedError();
}

Order _order() => const Order(
  id: 'ord-1',
  idempotencyKey: 'idem-1',
  venueId: 'demo',
  tableRef: TableRef(number: 7, source: TableSource.manual, validated: true),
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

void main() {
  // REQ-ORD-001: a confirmed submit reports the server id + sequence and leaves
  // nothing behind in the outbox.
  test('confirmed on the first try: no outbox entry', () async {
    final outbox = LocalStoreOutboxRepository(InMemoryLocalStore());
    final service = _FakeOrderingService(
      (_) => const SubmitConfirmed(serverOrderId: 'S1', sequence: 4),
    );
    final useCase = SubmitOrderUseCase(service, outbox);

    final outcome = await useCase(_order());

    expect(outcome, isA<SubmitSuccess>());
    final ok = outcome as SubmitSuccess;
    expect(ok.serverOrderId, 'S1');
    expect(ok.sequence, 4);
    expect(ok.attempts, 1);
    expect(service.calls, 1);
    expect(await outbox.pending('demo'), isEmpty);
  });

  // REQ-ERR-001: a retryable failure retries up to the bound, then fails clearly
  // and lands in the outbox for a later resend (degrade-open).
  test('retryable failure retries to the bound then enqueues', () async {
    final outbox = LocalStoreOutboxRepository(InMemoryLocalStore());
    final service = _FakeOrderingService(
      (_) => const SubmitFailed(reason: 'Rețea', retryable: true),
    );
    final useCase = SubmitOrderUseCase(service, outbox);

    final outcome = await useCase(_order());

    expect(outcome, isA<SubmitFailure>());
    expect((outcome as SubmitFailure).attempts, 3);
    expect(service.calls, 3);
    final pending = await outbox.pending('demo');
    expect(pending.length, 1);
    expect(pending.first.idempotencyKey, 'idem-1');
    expect(pending.first.attempts, 3);
  });

  // A non-retryable failure fails on the first try, no retry, still durable.
  test('non-retryable failure fails immediately and enqueues', () async {
    final outbox = LocalStoreOutboxRepository(InMemoryLocalStore());
    final service = _FakeOrderingService(
      (_) => const SubmitFailed(reason: 'Refuzat', retryable: false),
    );
    final useCase = SubmitOrderUseCase(service, outbox);

    final outcome = await useCase(_order());

    expect((outcome as SubmitFailure).attempts, 1);
    expect(service.calls, 1);
    expect((await outbox.pending('demo')).length, 1);
  });

  // Recovery: a retry that finally confirms clears the outbox and reports the
  // attempt count it took.
  test('retry that eventually confirms clears the outbox', () async {
    final outbox = LocalStoreOutboxRepository(InMemoryLocalStore());
    final service = _FakeOrderingService(
      (attempt) => attempt < 2
          ? const SubmitFailed(reason: 'Rețea', retryable: true)
          : const SubmitConfirmed(serverOrderId: 'S2', sequence: 9),
    );
    final useCase = SubmitOrderUseCase(service, outbox);

    final outcome = await useCase(_order());

    expect(outcome, isA<SubmitSuccess>());
    expect((outcome as SubmitSuccess).attempts, 2);
    expect(service.calls, 2);
    expect(await outbox.pending('demo'), isEmpty);
  });
}

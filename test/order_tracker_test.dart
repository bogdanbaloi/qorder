import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/di/providers.dart';
import 'package:qorder/domain/alerts/alert_signal.dart';
import 'package:qorder/domain/models/order.dart';
import 'package:qorder/domain/models/table_orders.dart';
import 'package:qorder/domain/services/ordering_service.dart';
import 'package:qorder/features/order/order_tracker.dart';

class _FakeAlertSignal implements AlertSignal {
  int fired = 0;

  @override
  Future<void> fire() async => fired++;
}

class _FakeOrderingService implements OrderingService {
  final Map<String, StreamController<OrderStatus>> _controllers = {};

  @override
  Stream<OrderStatus> watchOrder(String orderId) => _controllers
      .putIfAbsent(orderId, StreamController<OrderStatus>.broadcast)
      .stream;

  void emit(String orderId, OrderStage stage) =>
      _controllers[orderId]?.add(OrderStatus(orderId: orderId, stage: stage));

  @override
  Future<SubmitResult> submitOrder(Order order) => throw UnimplementedError();

  @override
  Future<TableOrders> tableOrders(
    String venueId,
    int tableNumber, {
    required String myClientId,
  }) => throw UnimplementedError();
}

// REQ-ORD-006: the customer follows the live status of EVERY order placed, not
// only the last one.
void main() {
  ProviderContainer containerWith(_FakeOrderingService fake) {
    final container = ProviderContainer(
      overrides: [orderingServiceProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test(
    'track adds an order at unknown stage, then follows its status',
    () async {
      final fake = _FakeOrderingService();
      final container = containerWith(fake);

      container.read(orderTrackerProvider.notifier).track('o1', 5);
      expect(container.read(orderTrackerProvider).single.sequence, 5);
      expect(container.read(orderTrackerProvider).single.stage, isNull);

      fake.emit('o1', OrderStage.received);
      await pumpEventQueue();
      expect(
        container.read(orderTrackerProvider).single.stage,
        OrderStage.received,
      );
    },
  );

  test('tracks several orders independently', () async {
    final fake = _FakeOrderingService();
    final container = containerWith(fake);
    final tracker = container.read(orderTrackerProvider.notifier);

    tracker.track('o1', 1);
    tracker.track('o2', 2);
    fake.emit('o1', OrderStage.preparing);
    fake.emit('o2', OrderStage.pendingAcceptance);
    await pumpEventQueue();

    final orders = container.read(orderTrackerProvider);
    expect(orders.length, 2);
    expect(
      orders.firstWhere((o) => o.serverOrderId == 'o1').stage,
      OrderStage.preparing,
    );
    expect(
      orders.firstWhere((o) => o.serverOrderId == 'o2').stage,
      OrderStage.pendingAcceptance,
    );
  });

  test('track is idempotent per order id', () {
    final fake = _FakeOrderingService();
    final container = containerWith(fake);
    final tracker = container.read(orderTrackerProvider.notifier);

    tracker.track('o1', 1);
    tracker.track('o1', 1);
    expect(container.read(orderTrackerProvider).length, 1);
  });

  test('fires the ready alert once when an order becomes done', () async {
    final fake = _FakeOrderingService();
    final alert = _FakeAlertSignal();
    final container = ProviderContainer(
      overrides: [
        orderingServiceProvider.overrideWithValue(fake),
        alertSignalProvider.overrideWithValue(alert),
      ],
    );
    addTearDown(container.dispose);

    container.read(orderTrackerProvider.notifier).track('o1', 1);
    fake.emit('o1', OrderStage.preparing);
    await pumpEventQueue();
    expect(alert.fired, 0);

    fake.emit('o1', OrderStage.done);
    await pumpEventQueue();
    expect(alert.fired, 1);

    // A repeat 'done' status must not re-fire the alert.
    fake.emit('o1', OrderStage.done);
    await pumpEventQueue();
    expect(alert.fired, 1);
  });
}

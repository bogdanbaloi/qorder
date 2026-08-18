import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/core/money.dart';
import 'package:qorder/data/ordering/mock_ordering_service.dart';
import 'package:qorder/di/providers.dart';
import 'package:qorder/domain/alerts/alert_signal.dart';
import 'package:qorder/domain/models/menu.dart';
import 'package:qorder/features/cart/cart_controller.dart';
import 'package:qorder/features/order/order_controller.dart';
import 'package:qorder/features/table/customer_provider.dart';
import 'package:qorder/features/table/table_controller.dart';

const _beer = MenuItem(
  id: 'b',
  categoryId: 'x',
  name: 'Beer',
  basePrice: Money(1000),
);

/// No-op alert, so the "order ready" haptic does not need a Flutter binding.
class _FakeAlertSignal implements AlertSignal {
  @override
  Future<void> fire() async {}
}

void main() {
  // REQ-TBL-001: submit is gated on a validated table AND a non-empty cart.
  test('submit gate opens only with validated table and items', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    expect(c.read(canSubmitProvider), false); // empty
    c.read(cartProvider.notifier).addItem(_beer);
    expect(c.read(canSubmitProvider), false); // no table
    c.read(tableProvider.notifier).setManual(12);
    expect(c.read(canSubmitProvider), false); // demo requires a name
    c.read(customerNameProvider.notifier).set('Andrei');
    expect(c.read(canSubmitProvider), true);
    c.read(tableProvider.notifier).setManual(9999); // out of policy range
    expect(c.read(canSubmitProvider), false);
  });

  // REQ-ORD-001: a good submit confirms with a sequence and clears the cart.
  test('confirmed submit assigns sequence and clears cart', () async {
    final c = ProviderContainer(
      overrides: [
        orderingServiceProvider.overrideWithValue(
          MockOrderingService(latency: Duration.zero, stageGap: Duration.zero),
        ),
      ],
    );
    addTearDown(c.dispose);

    c.read(cartProvider.notifier).addItem(_beer);
    c.read(tableProvider.notifier).setManual(12);
    await c.read(orderControllerProvider.notifier).submit();

    final s = c.read(orderControllerProvider);
    expect(s.phase, SubmitPhase.confirmed);
    expect(s.sequence, 1);
    expect(c.read(cartProvider).isEmpty, true);
  });

  // REQ-ORD-008: after a placed order, adding to the cart returns the flow to
  // idle, so the cart shows "submit" again (not the stale "new order" button).
  test('composing a new order after one is placed re-enables submit', () async {
    final c = ProviderContainer(
      overrides: [
        orderingServiceProvider.overrideWithValue(
          MockOrderingService(latency: Duration.zero, stageGap: Duration.zero),
        ),
        alertSignalProvider.overrideWithValue(_FakeAlertSignal()),
      ],
    );
    addTearDown(c.dispose);

    c.read(cartProvider.notifier).addItem(_beer);
    c.read(tableProvider.notifier).setManual(12);
    c.read(customerNameProvider.notifier).set('Andrei');
    // Read once so the controller (and its cart listener) is built.
    expect(c.read(orderControllerProvider).phase, SubmitPhase.idle);
    await c.read(orderControllerProvider.notifier).submit();
    expect(c.read(orderControllerProvider).phase, SubmitPhase.confirmed);
    expect(c.read(cartProvider).isEmpty, true);

    // The customer starts a new order -> back to idle (the submit button).
    c.read(cartProvider.notifier).addItem(_beer);
    await pumpEventQueue();
    expect(c.read(orderControllerProvider).phase, SubmitPhase.idle);
  });

  // REQ-ERR-001: on failure it retries then fails clearly. Cart is preserved.
  test('failed submit retries then fails, cart preserved', () async {
    final c = ProviderContainer(
      overrides: [
        orderingServiceProvider.overrideWithValue(
          MockOrderingService(forceFailure: true, latency: Duration.zero),
        ),
      ],
    );
    addTearDown(c.dispose);

    c.read(cartProvider.notifier).addItem(_beer);
    c.read(tableProvider.notifier).setManual(3);
    await c.read(orderControllerProvider.notifier).submit();

    final s = c.read(orderControllerProvider);
    expect(s.phase, SubmitPhase.failed);
    expect(s.attempts, 3);
    expect(c.read(cartProvider).isEmpty, false);
  });
}

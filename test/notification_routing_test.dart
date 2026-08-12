import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/data/notifications/logging_notifier.dart';
import 'package:qorder/domain/notifications/order_notifier.dart';

OrderNotifier _build(NotificationTarget target, NotificationLog log) =>
    buildOrderNotifier(
      target,
      waiter: LoggingOrderNotifier('waiter', log),
      tablet: LoggingOrderNotifier('tablet', log),
    );

void main() {
  const n = OrderNotification(
    tableNumber: 12,
    sequence: 1,
    customerName: 'Andrei',
  );

  // REQ-NOTE-001: the notification target is configurable and modular.
  test('waiter target notifies only the waiter', () async {
    final log = NotificationLog();
    await _build(NotificationTarget.waiter, log).notify(n);
    expect(log.sent.map((s) => s.channel).toList(), ['waiter']);
  });

  test('tablet target notifies only the tablet', () async {
    final log = NotificationLog();
    await _build(NotificationTarget.tablet, log).notify(n);
    expect(log.sent.map((s) => s.channel).toList(), ['tablet']);
  });

  test('both target notifies waiter and tablet', () async {
    final log = NotificationLog();
    await _build(NotificationTarget.both, log).notify(n);
    expect(log.sent.map((s) => s.channel).toSet(), {'waiter', 'tablet'});
    expect(log.sent.length, 2);
  });
}

import 'package:flutter/foundation.dart';

/// WHERE a new-order notification is delivered. This is POLICY (configurable),
/// kept separate from the mechanism of delivering it (mechanism vs policy).
enum NotificationTarget { waiter, tablet, both }

/// Named delivery channels (no magic channel strings scattered around).
class NotificationChannels {
  const NotificationChannels._();
  static const waiter = 'waiter';
  static const tablet = 'tablet';
}

@immutable
class OrderNotification {
  final int tableNumber;
  final int sequence;
  final String? customerName;
  const OrderNotification({
    required this.tableNumber,
    required this.sequence,
    this.customerName,
  });
}

/// One responsibility: deliver a new-order notification to a destination
/// (Single Responsibility). Implementations: waiter phone, bar tablet, or a
/// composite of both. Callers depend on this interface, not on a concrete
/// channel (Dependency Inversion).
abstract interface class OrderNotifier {
  Future<void> notify(OrderNotification notification);
}

/// Fans a notification out to several notifiers (used for "both"). Adding a new
/// channel does not change this class (Open/Closed).
class CompositeOrderNotifier implements OrderNotifier {
  final List<OrderNotifier> targets;
  const CompositeOrderNotifier(this.targets);

  @override
  Future<void> notify(OrderNotification n) async {
    await Future.wait(targets.map((t) => t.notify(n)));
  }
}

/// Builds the notifier from the configured target. A new target or a new
/// channel drops in here without touching callers (Open/Closed).
OrderNotifier buildOrderNotifier(
  NotificationTarget target, {
  required OrderNotifier waiter,
  required OrderNotifier tablet,
}) => switch (target) {
  NotificationTarget.waiter => waiter,
  NotificationTarget.tablet => tablet,
  NotificationTarget.both => CompositeOrderNotifier([waiter, tablet]),
};

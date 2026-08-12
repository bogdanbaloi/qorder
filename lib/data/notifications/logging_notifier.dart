import '../../domain/notifications/order_notifier.dart';

class SentNotification {
  final String channel;
  final int tableNumber;
  final int sequence;
  const SentNotification(this.channel, this.tableNumber, this.sequence);
}

/// A shared record of what was notified (Phase 0), so the UI and tests can see
/// how routing behaved.
class NotificationLog {
  final List<SentNotification> sent = [];
}

/// Phase 0 notifier: records the delivery on a named channel. Phase 1 replaces
/// this behind the SAME interface with a real WaiterNotifier (push to the
/// waiter's phone) and a TabletNotifier (Ebriza push-to-POS). Callers do not
/// change (Liskov substitution).
class LoggingOrderNotifier implements OrderNotifier {
  final String channel;
  final NotificationLog log;
  LoggingOrderNotifier(this.channel, this.log);

  @override
  Future<void> notify(OrderNotification n) async {
    log.sent.add(SentNotification(channel, n.tableNumber, n.sequence));
  }
}

import 'package:flutter/foundation.dart';

/// Operational timestamps for one order (epoch millis), keyed by event:
/// 'submitted', 'accepted', 'ready', 'delivered'. A missing key means that event
/// has not happened yet.
typedef OrderStamps = Map<String, int>;

/// Pure computation of the durations the owner cares about, from the stamps. A
/// value object with no I/O, so it is trivially unit-tested.
@immutable
class OrderTimings {
  final OrderStamps stamps;
  const OrderTimings(this.stamps);

  Duration? _between(String from, String to) {
    final a = stamps[from];
    final b = stamps[to];
    if (a == null || b == null) return null;
    return Duration(milliseconds: b - a);
  }

  /// Submit to waiter-accept: how fast the waiter picks the order up.
  Duration? get acceptance => _between('submitted', 'accepted');

  /// Ready to at-the-table: the waiter-availability gap. The drink is made and
  /// waiting while the waiter is busy elsewhere. Isolated from the bar's prep
  /// time on purpose, this is the owner's key metric.
  Duration? get delivery => _between('ready', 'delivered');
}

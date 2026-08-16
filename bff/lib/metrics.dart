import 'models.dart';

/// Aggregates the owner metrics from a venue's orders. Pure: it takes the orders
/// and the current time, so it is unit-tested without a server. Revenue is the
/// sum of order totals; the daily series buckets orders by their 'submitted' day.
Map<String, dynamic> computeMetrics(
  List<BffOrder> orders, {
  required int nowMs,
}) {
  String dayOf(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$month-$day';
  }

  int revenue(List<BffOrder> os) => os.fold(0, (sum, o) => sum + o.totalMinor);

  int? averageGap(String from, String to) {
    final gaps = <int>[];
    for (final o in orders) {
      final a = o.stamps[from];
      final b = o.stamps[to];
      if (a != null && b != null) gaps.add(b - a);
    }
    if (gaps.isEmpty) return null;
    return gaps.reduce((x, y) => x + y) ~/ gaps.length;
  }

  final byDay = <String, List<BffOrder>>{};
  for (final o in orders) {
    final submitted = o.stamps['submitted'];
    if (submitted == null) continue;
    byDay.putIfAbsent(dayOf(submitted), () => <BffOrder>[]).add(o);
  }

  final today = dayOf(nowMs);
  final todayOrders = byDay[today] ?? const <BffOrder>[];
  final days = byDay.keys.toList()..sort();

  return {
    'ordersToday': todayOrders.length,
    'revenueTodayMinor': revenue(todayOrders),
    'avgAcceptanceMs': averageGap('submitted', 'accepted'),
    'avgDeliveryMs': averageGap('ready', 'delivered'),
    'daily': [
      for (final day in days)
        {
          'date': day,
          'orders': byDay[day]!.length,
          'revenueMinor': revenue(byDay[day]!),
        },
    ],
  };
}

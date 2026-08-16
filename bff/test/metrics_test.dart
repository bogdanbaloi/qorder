import 'package:qorder_bff/metrics.dart';
import 'package:qorder_bff/models.dart';
import 'package:test/test.dart';

// The owner metrics: revenue is the sum of order totals, the averages come from
// the stamps, and the daily series buckets by the submitted day.
BffOrder _order({
  required String id,
  required int total,
  required Map<String, int> stamps,
  String venue = 'demo',
}) => BffOrder(
  serverOrderId: id,
  venueId: venue,
  tableNumber: 5,
  sequence: 1,
  stage: OrderStage.done,
  lines: const [],
  totalMinor: total,
  stamps: stamps,
);

void main() {
  // 2026-08-16 12:00 and 2026-08-15 12:00 as epoch millis.
  final day16 = DateTime(2026, 8, 16, 12).millisecondsSinceEpoch;
  final day15 = DateTime(2026, 8, 15, 12).millisecondsSinceEpoch;
  final now = DateTime(2026, 8, 16, 18).millisecondsSinceEpoch;

  test('sums today revenue and orders, and builds the daily series', () {
    final orders = [
      _order(
        id: 'a',
        total: 2000,
        stamps: {'submitted': day16, 'accepted': day16 + 4000},
      ),
      _order(
        id: 'b',
        total: 3000,
        stamps: {'submitted': day16, 'accepted': day16 + 8000},
      ),
      _order(id: 'c', total: 5000, stamps: {'submitted': day15}),
    ];
    final m = computeMetrics(orders, nowMs: now);

    expect(m['ordersToday'], 2);
    expect(m['revenueTodayMinor'], 5000); // 2000 + 3000
    expect(m['avgAcceptanceMs'], 6000); // (4000 + 8000) / 2
    final daily = m['daily'] as List;
    expect(daily.length, 2);
    expect(daily.first['date'], '2026-08-15');
    expect(daily.last, {
      'date': '2026-08-16',
      'orders': 2,
      'revenueMinor': 5000,
    });
  });

  test('averages are null when no order has that leg', () {
    final orders = [
      _order(id: 'a', total: 1000, stamps: {'submitted': now}),
    ];
    final m = computeMetrics(orders, nowMs: now);
    expect(m['avgAcceptanceMs'], isNull);
    expect(m['avgDeliveryMs'], isNull);
  });
}

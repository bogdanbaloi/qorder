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
  List<dynamic> lines = const [],
}) =>
    BffOrder(
      serverOrderId: id,
      venueId: venue,
      tableNumber: 5,
      sequence: 1,
      stage: OrderStage.done,
      lines: lines,
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

  test('buckets today by hour (active hours only, ascending)', () {
    final at18 = DateTime(2026, 8, 16, 18).millisecondsSinceEpoch;
    final at20 = DateTime(2026, 8, 16, 20).millisecondsSinceEpoch;
    final orders = [
      _order(id: 'a', total: 1000, stamps: {'submitted': at18}),
      _order(id: 'b', total: 2000, stamps: {'submitted': at18}),
      _order(id: 'c', total: 3000, stamps: {'submitted': at20}),
      _order(id: 'd', total: 9000, stamps: {'submitted': day15}), // other day
    ];
    final hourly = computeMetrics(orders, nowMs: now)['hourly'] as List;
    expect(hourly.length, 2);
    expect(hourly.first, {'hour': 18, 'orders': 2, 'revenueMinor': 3000});
    expect(hourly.last, {'hour': 20, 'orders': 1, 'revenueMinor': 3000});
  });

  test('ranks top products by units sold across all orders', () {
    final orders = [
      _order(
        id: 'a',
        total: 1000,
        stamps: {'submitted': day16},
        lines: [
          {'name': 'Bere', 'qty': 2},
          {'name': 'Cafea', 'qty': 1},
        ],
      ),
      _order(
        id: 'b',
        total: 2000,
        stamps: {'submitted': day15},
        lines: [
          {'name': 'Bere', 'qty': 3},
        ],
      ),
    ];
    final top = computeMetrics(orders, nowMs: now)['topProducts'] as List;
    expect(top.first, {'name': 'Bere', 'qty': 5}); // 2 + 3
    expect(top.last, {'name': 'Cafea', 'qty': 1});
  });
}

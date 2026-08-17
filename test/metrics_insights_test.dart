import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/core/money.dart';
import 'package:qorder/domain/metrics/metrics_insights.dart';
import 'package:qorder/domain/metrics/sales_metrics.dart';

// REQ-OWNER-003: the owner dashboard shows richer insight (average order value +
// day-over-day movement) derived on the client from the existing metrics.
DailyMetric _day(String date, int orders, int revenueMinor) =>
    DailyMetric(date: date, orders: orders, revenue: Money(revenueMinor));

void main() {
  test('average order value divides revenue by orders (bani)', () {
    const metrics = SalesMetrics(ordersToday: 4, revenueToday: Money(10000));
    expect(averageOrderValue(metrics).amountMinor, 2500);
  });

  test('average order value is zero with no orders', () {
    const metrics = SalesMetrics(ordersToday: 0, revenueToday: Money(0));
    expect(averageOrderValue(metrics).amountMinor, 0);
  });

  test('day-over-day needs at least two days', () {
    expect(dayOverDay(const []), isNull);
    expect(dayOverDay([_day('2026-08-16', 3, 3000)]), isNull);
  });

  test('day-over-day compares the last two days', () {
    final comparison = dayOverDay([
      _day('2026-08-15', 4, 4000),
      _day('2026-08-16', 6, 5000),
    ])!;
    expect(comparison.ordersDelta, 2);
    expect(comparison.revenueDelta.amountMinor, 1000);
    expect(comparison.revenueRatio, closeTo(0.25, 0.001)); // 1000 / 4000
  });

  test('day-over-day ratio is null when the previous day had no revenue', () {
    final comparison = dayOverDay([
      _day('2026-08-15', 0, 0),
      _day('2026-08-16', 2, 2000),
    ])!;
    expect(comparison.revenueDelta.amountMinor, 2000);
    expect(comparison.revenueRatio, isNull);
  });
}

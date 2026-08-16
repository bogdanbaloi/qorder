import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/domain/metrics/sales_metrics.dart';

// REQ-OWNER-002: the owner sees real revenue and a daily history from the
// backend; the client parses the metrics payload.
void main() {
  test('parses the metrics payload from the backend', () {
    final json = <String, dynamic>{
      'ordersToday': 12,
      'revenueTodayMinor': 45600,
      'avgAcceptanceMs': 6000,
      'avgDeliveryMs': null,
      'daily': [
        {'date': '2026-08-15', 'orders': 20, 'revenueMinor': 78000},
        {'date': '2026-08-16', 'orders': 12, 'revenueMinor': 45600},
      ],
    };
    final metrics = SalesMetrics.fromJson(json);
    expect(metrics.ordersToday, 12);
    expect(metrics.revenueToday.amountMinor, 45600);
    expect(metrics.avgAcceptance, const Duration(seconds: 6));
    expect(metrics.avgDelivery, isNull); // a missing leg stays null
    expect(metrics.history.length, 2);
    expect(metrics.history.last.date, '2026-08-16');
    expect(metrics.history.last.revenue.amountMinor, 45600);
  });

  test('empty metrics are zeroed', () {
    const metrics = SalesMetrics.empty();
    expect(metrics.ordersToday, 0);
    expect(metrics.revenueToday.amountMinor, 0);
    expect(metrics.avgAcceptance, isNull);
    expect(metrics.history, isEmpty);
  });
}

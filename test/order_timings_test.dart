import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/domain/timing/order_timings.dart';

void main() {
  // REQ-TIME-001: acceptance = accepted - submitted; delivery = delivered -
  // ready (the ready-to-table gap, isolated from the bar's prep time).
  test('computes acceptance and delivery from stamps', () {
    const t = OrderTimings({
      'submitted': 1000,
      'accepted': 4000,
      'ready': 10000,
      'delivered': 25000,
    });
    expect(t.acceptance, const Duration(seconds: 3));
    expect(t.delivery, const Duration(seconds: 15));
  });

  test('a duration is null until both its stamps exist', () {
    const t = OrderTimings({'submitted': 1000, 'accepted': 4000});
    expect(t.acceptance, const Duration(seconds: 3));
    expect(t.delivery, isNull);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/domain/history/past_order.dart';

// REQ-LOYAL-003: a loyal customer sees their order history; the client parses a
// past order from the backend order JSON.
void main() {
  test('parses a past order from the backend order JSON', () {
    final json = <String, dynamic>{
      'sequence': 5,
      'tableNumber': 7,
      'totalMinor': 4200,
      'stage': 'done',
      'stamps': {'submitted': 12345},
    };
    final order = PastOrder.fromJson(json);
    expect(order.sequence, 5);
    expect(order.tableNumber, 7);
    expect(order.total.amountMinor, 4200);
    expect(order.stage, 'done');
    expect(order.submittedAtMs, 12345);
  });

  test('missing total and stamps default safely', () {
    final order = PastOrder.fromJson(const <String, dynamic>{
      'sequence': 1,
      'tableNumber': 2,
    });
    expect(order.total.amountMinor, 0);
    expect(order.submittedAtMs, 0);
    expect(order.stage, '');
  });
}

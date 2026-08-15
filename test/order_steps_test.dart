import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/domain/models/order.dart';

void main() {
  // REQ-ORD-004: the status stepper maps each stage to its ordered position,
  // so finished steps are checked and the current one is highlighted.
  test('orderStepIndex maps each stage to its position', () {
    expect(orderStepStages.length, 4);
    expect(orderStepIndex(OrderStage.pendingAcceptance), 0);
    expect(orderStepIndex(OrderStage.received), 1);
    expect(orderStepIndex(OrderStage.preparing), 2);
    expect(orderStepIndex(OrderStage.done), 3);
    expect(orderStepIndex(null), 0);
  });
}

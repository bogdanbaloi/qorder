import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/core/i18n/strings_en.dart';
import 'package:qorder/core/i18n/strings_ro.dart';
import 'package:qorder/domain/models/order.dart';
import 'package:qorder/features/order/order_status_labels.dart';

// REQ-ORD-006: the stepper and the menu banner share one stage->label mapping,
// so the wording never drifts and both localize together.
void main() {
  test('maps each stage in Romanian', () {
    const s = StringsRo();
    expect(orderStageLabel(s, OrderStage.pendingAcceptance), 'Așteaptă');
    expect(orderStageLabel(s, OrderStage.received), 'Preluată');
    expect(orderStageLabel(s, OrderStage.preparing), 'În pregătire');
    expect(orderStageLabel(s, OrderStage.done), 'Gata');
    expect(orderStageLabel(s, OrderStage.delivered), 'Livrat');
  });

  test('maps each stage in English', () {
    const s = StringsEn();
    expect(orderStageLabel(s, OrderStage.pendingAcceptance), 'Waiting');
    expect(orderStageLabel(s, OrderStage.received), 'Accepted');
    expect(orderStageLabel(s, OrderStage.preparing), 'Preparing');
    expect(orderStageLabel(s, OrderStage.done), 'Ready');
    expect(orderStageLabel(s, OrderStage.delivered), 'Delivered');
  });
}

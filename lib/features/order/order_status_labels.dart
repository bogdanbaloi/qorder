import '../../core/i18n/app_strings.dart';
import '../../domain/models/order.dart';

/// The localized label for an order [stage], shared by the cart status stepper
/// and the menu status banner so the wording never drifts between them.
String orderStageLabel(AppStrings s, OrderStage stage) => switch (stage) {
  OrderStage.pendingAcceptance => s.stepWaiting,
  OrderStage.received => s.stepAccepted,
  OrderStage.preparing => s.stepPreparing,
  OrderStage.done => s.stepReady,
};

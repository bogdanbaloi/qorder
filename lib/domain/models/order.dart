import 'package:flutter/foundation.dart';

import '../../core/money.dart';
import 'cart.dart';
import 'table_ref.dart';

enum OrderState { draft, submitting, submitted, failed }

/// Lifecycle stages reported back while the bar processes the order.
/// Processing takes real time. The app reflects it, never assumes "instant".
enum OrderStage {
  /// waiterConfirm mode only: submitted, waiting for a waiter to accept it.
  pendingAcceptance,
  received,
  preparing,
  done,
}

/// The lifecycle stages shown to the customer as ordered steps.
const orderStepStages = <OrderStage>[
  OrderStage.pendingAcceptance,
  OrderStage.received,
  OrderStage.preparing,
  OrderStage.done,
];

/// The index of the step for [stage] (0 when unknown), for the status stepper.
/// Pure, so the stepper's progress logic is unit-tested without the UI.
int orderStepIndex(OrderStage? stage) {
  if (stage == null) return 0;
  final i = orderStepStages.indexOf(stage);
  return i < 0 ? 0 : i;
}

@immutable
class Order {
  final String id; // client-generated id
  final String venueId;
  final TableRef tableRef; // required + validated before submit
  final List<CartLine> lines; // snapshot
  final Money total;
  final int? sequence; // FIFO sequence assigned by the backend/mock
  final OrderState state;
  final String? serverOrderId;
  final String? failureReason;
  final String? note;
  final String?
  idempotencyKey; // dedupe key: a resend must not create a 2nd order
  final String? customerName;
  final String? clientId; // anonymous per-device id, for "which order is mine"

  const Order({
    required this.id,
    required this.venueId,
    required this.tableRef,
    required this.lines,
    required this.total,
    this.sequence,
    this.state = OrderState.draft,
    this.serverOrderId,
    this.failureReason,
    this.note,
    this.idempotencyKey,
    this.customerName,
    this.clientId,
  });

  Order copyWith({
    int? sequence,
    OrderState? state,
    String? serverOrderId,
    String? failureReason,
  }) => Order(
    id: id,
    venueId: venueId,
    tableRef: tableRef,
    lines: lines,
    total: total,
    sequence: sequence ?? this.sequence,
    state: state ?? this.state,
    serverOrderId: serverOrderId ?? this.serverOrderId,
    failureReason: failureReason ?? this.failureReason,
    note: note,
    idempotencyKey: idempotencyKey,
    customerName: customerName,
    clientId: clientId,
  );
}

@immutable
class OrderStatus {
  final String orderId;
  final OrderStage stage;
  const OrderStatus({required this.orderId, required this.stage});
}

/// Explicit boundary result of a submit: confirmed with a server id + FIFO
/// sequence, or clearly failed. Never a silent drop.
sealed class SubmitResult {
  const SubmitResult();
}

class SubmitConfirmed extends SubmitResult {
  final String serverOrderId;
  final int sequence;
  const SubmitConfirmed({required this.serverOrderId, required this.sequence});
}

class SubmitFailed extends SubmitResult {
  final String reason;
  final bool retryable;
  const SubmitFailed({required this.reason, this.retryable = true});
}

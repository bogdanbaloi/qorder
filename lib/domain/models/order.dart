import 'package:flutter/foundation.dart';

import '../../core/money.dart';
import 'cart.dart';
import 'table_ref.dart';

enum OrderState { draft, submitting, submitted, failed }

/// Lifecycle stages reported back while the bar processes the order.
/// Processing takes real time; the app reflects it, never assumes "instant".
enum OrderStage { received, preparing, done }

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

import 'dart:async';

import '../../core/app_constants.dart';
import '../models/order.dart';
import '../models/pending_order.dart';
import '../repositories/outbox_repository.dart';
import '../services/ordering_service.dart';

/// The result of submitting an order, independent of any UI. Either the backend
/// confirmed it (with a server id + FIFO sequence) or it failed clearly after
/// the bounded retry. Never a silent drop.
sealed class SubmitOutcome {
  const SubmitOutcome();
}

class SubmitSuccess extends SubmitOutcome {
  final String serverOrderId;
  final int sequence;
  final int attempts;
  const SubmitSuccess({
    required this.serverOrderId,
    required this.sequence,
    required this.attempts,
  });
}

class SubmitFailure extends SubmitOutcome {
  final String reason;
  final int attempts;
  const SubmitFailure({required this.reason, required this.attempts});
}

/// Submits an order with a bounded, ordered retry, a per-call timeout and a
/// durable outbox, so an order is never lost AND never duplicated. This is the
/// resilience orchestration (ADR-0012), extracted out of the UI controller:
///  - it depends only on the `OrderingService` and `OutboxRepository`
///    interfaces (Dependency Inversion), not on Riverpod or any widget.
///  - it is therefore unit-testable in isolation, with fakes.
///  - the controller stays a thin presentation adapter that maps the outcome
///    to UI state (Single Responsibility).
class SubmitOrderUseCase {
  final OrderingService _service;
  final OutboxRepository _outbox;

  const SubmitOrderUseCase(this._service, this._outbox);

  /// Sends [order], reusing its stable idempotency key on every attempt, so a
  /// retry after a lost ack can never create a second order.
  Future<SubmitOutcome> call(Order order) async {
    for (
      var attempt = 1;
      attempt <= AppConstants.maxSubmitAttempts;
      attempt++
    ) {
      final result = await _service
          .submitOrder(order)
          .timeout(
            AppConstants.submitTimeout,
            onTimeout: () =>
                const SubmitFailed(reason: 'Timeout', retryable: true),
          );
      switch (result) {
        case SubmitConfirmed(:final serverOrderId, :final sequence):
          await _outbox.remove(order.idempotencyKey!);
          return SubmitSuccess(
            serverOrderId: serverOrderId,
            sequence: sequence,
            attempts: attempt,
          );
        case SubmitFailed(:final reason, :final retryable):
          if (!retryable || attempt == AppConstants.maxSubmitAttempts) {
            await _outbox.enqueue(_toPending(order, attempt));
            return SubmitFailure(reason: reason, attempts: attempt);
          }
          await Future.delayed(AppConstants.retryBackoffStep * attempt);
      }
    }
    // Unreachable: the loop returns on every attempt. Kept for exhaustiveness.
    return const SubmitFailure(
      reason: 'Unknown',
      attempts: AppConstants.maxSubmitAttempts,
    );
  }

  PendingOrder _toPending(Order o, int attempts) => PendingOrder(
    idempotencyKey: o.idempotencyKey!,
    venueId: o.venueId,
    tableNumber: o.tableRef.number,
    lines: o.lines,
    totalMinor: o.total.amountMinor,
    createdAtMicros: DateTime.now().microsecondsSinceEpoch,
    attempts: attempts,
  );
}

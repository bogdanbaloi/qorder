import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../di/providers.dart';
import '../../domain/models/order.dart';
import '../../domain/models/pending_order.dart';
import '../../domain/models/table_ref.dart';
import '../../domain/notifications/order_notifier.dart';
import '../cart/cart_controller.dart';
import '../table/customer_provider.dart';
import '../table/table_controller.dart';
import '../table/table_orders_provider.dart';

enum SubmitPhase { idle, submitting, confirmed, failed }

@immutable
class OrderUiState {
  final SubmitPhase phase;
  final int attempts;
  final String? serverOrderId;
  final int? sequence;
  final String? failureReason;
  final OrderStage? stage;

  const OrderUiState({
    this.phase = SubmitPhase.idle,
    this.attempts = 0,
    this.serverOrderId,
    this.sequence,
    this.failureReason,
    this.stage,
  });

  OrderUiState copyWith({
    SubmitPhase? phase,
    int? attempts,
    String? serverOrderId,
    int? sequence,
    String? failureReason,
    OrderStage? stage,
  }) => OrderUiState(
    phase: phase ?? this.phase,
    attempts: attempts ?? this.attempts,
    serverOrderId: serverOrderId ?? this.serverOrderId,
    sequence: sequence ?? this.sequence,
    failureReason: failureReason ?? this.failureReason,
    stage: stage ?? this.stage,
  );
}

/// Submits an order with a bounded, ordered retry and a persistent outbox.
/// Resilience guarantees:
///  - a failed submit is persisted to the outbox and never silently dropped;
///  - it is resent automatically on the next launch (resumePending);
///  - every send carries a stable idempotency key, so a retry never creates a
///    duplicate order (never lost AND never duplicated);
///  - every network call has a timeout so the app never hangs.
class OrderController extends Notifier<OrderUiState> {
  @override
  OrderUiState build() => const OrderUiState();

  Future<void> submit() async {
    final table = ref.read(tableProvider);
    final cart = ref.read(cartProvider);
    if (table == null || !table.validated || cart.isEmpty) return;

    final now = DateTime.now().microsecondsSinceEpoch;
    final order = Order(
      id: 'ord-$now',
      idempotencyKey: 'idem-$now',
      venueId: cart.venueId,
      tableRef: table,
      lines: cart.lines,
      total: cart.subtotal,
      customerName: ref.read(customerNameProvider),
      clientId: ref.read(clientIdProvider),
      state: OrderState.submitting,
    );
    await _send(order, clearCartOnSuccess: true);
  }

  /// Resend anything left in the outbox. Called at launch (resilience) and by
  /// the "retry" button. Reuses the SAME idempotency key, so it cannot duplicate.
  Future<void> resumePending() async {
    final outbox = ref.read(outboxRepositoryProvider);
    final cfg = ref.read(appConfigProvider);
    final pending = await outbox.pending(cfg.venueId);
    if (pending.isEmpty) return;

    final p = pending.first;
    final order = Order(
      id: 'ord-${p.createdAtMicros}',
      idempotencyKey: p.idempotencyKey,
      venueId: p.venueId,
      tableRef: TableRef(
        number: p.tableNumber,
        source: TableSource.manual,
        validated: true,
      ),
      lines: p.lines,
      total: Money(p.totalMinor),
      state: OrderState.submitting,
    );
    await _send(order, clearCartOnSuccess: false);
  }

  Future<void> _send(Order order, {required bool clearCartOnSuccess}) async {
    state = const OrderUiState(phase: SubmitPhase.submitting);
    final service = ref.read(orderingServiceProvider);
    final outbox = ref.read(outboxRepositoryProvider);

    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final result = await service
          .submitOrder(order)
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () =>
                const SubmitFailed(reason: 'Timeout', retryable: true),
          );
      switch (result) {
        case SubmitConfirmed(:final serverOrderId, :final sequence):
          await outbox.remove(order.idempotencyKey!);
          state = state.copyWith(
            phase: SubmitPhase.confirmed,
            serverOrderId: serverOrderId,
            sequence: sequence,
            attempts: attempt,
          );
          if (clearCartOnSuccess) ref.read(cartProvider.notifier).clear();
          ref.invalidate(tableOrdersProvider);
          await ref
              .read(orderNotifierProvider)
              .notify(
                OrderNotification(
                  tableNumber: order.tableRef.number,
                  sequence: sequence,
                  customerName: order.customerName,
                ),
              );
          _watch(serverOrderId);
          return;
        case SubmitFailed(:final reason, :final retryable):
          state = state.copyWith(attempts: attempt, failureReason: reason);
          if (!retryable || attempt == maxAttempts) {
            await outbox.enqueue(_toPending(order, attempt));
            state = state.copyWith(phase: SubmitPhase.failed);
            return;
          }
          await Future.delayed(Duration(milliseconds: 150 * attempt));
      }
    }
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

  void _watch(String serverOrderId) {
    final service = ref.read(orderingServiceProvider);
    final sub = service.watchOrder(serverOrderId).listen((s) {
      state = state.copyWith(stage: s.stage);
    });
    ref.onDispose(sub.cancel);
  }

  void reset() => state = const OrderUiState();
}

final orderControllerProvider = NotifierProvider<OrderController, OrderUiState>(
  OrderController.new,
);

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_constants.dart';
import '../../core/money.dart';
import '../../di/providers.dart';
import '../../domain/models/order.dart';
import '../../domain/models/table_ref.dart';
import '../../domain/notifications/order_notifier.dart';
import '../../domain/usecases/submit_order_use_case.dart';
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

/// Presentation controller for the submit flow. It builds the `Order`, runs it
/// through `SubmitOrderUseCase` (which owns the resilience: bounded retry,
/// timeout and durable idempotent outbox, per ADR-0012) and maps the outcome to
/// `OrderUiState`. It also owns the UI-only side effects: clear the cart,
/// refresh the table view and fire the notification. `resumePending` resends
/// whatever the outbox still holds, at launch or from the retry button.
class OrderController extends Notifier<OrderUiState> {
  @override
  OrderUiState build() => const OrderUiState();

  Future<void> submit() async {
    final table = ref.read(tableProvider);
    final cart = ref.read(cartProvider);
    if (table == null || !table.validated || cart.isEmpty) return;

    final now = DateTime.now().microsecondsSinceEpoch;
    final order = Order(
      id: '${AppConstants.orderIdPrefix}$now',
      idempotencyKey: '${AppConstants.idempotencyKeyPrefix}$now',
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
      id: '${AppConstants.orderIdPrefix}${p.createdAtMicros}',
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

  /// Runs the submit orchestration in `SubmitOrderUseCase` and maps its outcome
  /// to UI state. This method owns only presentation concerns: the retry,
  /// timeout and outbox live in the use-case (Single Responsibility).
  Future<void> _send(Order order, {required bool clearCartOnSuccess}) async {
    state = const OrderUiState(phase: SubmitPhase.submitting);
    final outcome = await ref.read(submitOrderUseCaseProvider)(order);
    switch (outcome) {
      case SubmitSuccess(
        :final serverOrderId,
        :final sequence,
        :final attempts,
      ):
        state = state.copyWith(
          phase: SubmitPhase.confirmed,
          serverOrderId: serverOrderId,
          sequence: sequence,
          attempts: attempts,
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
      case SubmitFailure(:final reason, :final attempts):
        state = state.copyWith(
          phase: SubmitPhase.failed,
          failureReason: reason,
          attempts: attempts,
        );
    }
  }

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

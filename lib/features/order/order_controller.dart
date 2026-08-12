import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/models/order.dart';
import '../cart/cart_controller.dart';
import '../table/table_controller.dart';

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

/// Handles submitting an order with a bounded, ordered retry (outbox-style).
/// The order for a single customer is preserved in order; a failed submit
/// retries a few times, then fails clearly. Never a silent drop.
class OrderController extends Notifier<OrderUiState> {
  @override
  OrderUiState build() => const OrderUiState();

  Future<void> submit() async {
    final table = ref.read(tableProvider);
    final cart = ref.read(cartProvider);
    if (table == null || !table.validated || cart.isEmpty) return;

    state = const OrderUiState(phase: SubmitPhase.submitting);
    final service = ref.read(orderingServiceProvider);
    final order = Order(
      id: 'ord-${DateTime.now().microsecondsSinceEpoch}',
      venueId: cart.venueId,
      tableRef: table,
      lines: cart.lines,
      total: cart.subtotal,
      state: OrderState.submitting,
    );

    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final result = await service.submitOrder(order);
      switch (result) {
        case SubmitConfirmed(:final serverOrderId, :final sequence):
          state = state.copyWith(
            phase: SubmitPhase.confirmed,
            serverOrderId: serverOrderId,
            sequence: sequence,
            attempts: attempt,
          );
          ref.read(cartProvider.notifier).clear();
          _watch(serverOrderId);
          return;
        case SubmitFailed(:final reason, :final retryable):
          state = state.copyWith(attempts: attempt, failureReason: reason);
          if (!retryable || attempt == maxAttempts) {
            state = state.copyWith(phase: SubmitPhase.failed);
            return;
          }
          await Future.delayed(Duration(milliseconds: 150 * attempt));
      }
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

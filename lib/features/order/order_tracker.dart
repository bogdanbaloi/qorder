import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/models/order.dart';
import '../../domain/models/tracked_order.dart';

/// Tracks the live status of EVERY order the customer has placed, not only the
/// last. It watches each order's status stream and updates that order's stage.
/// The status still comes from the backend (single source of truth); this only
/// fans out to many orders so the customer sees each one progress.
class OrderTracker extends Notifier<List<TrackedOrder>> {
  final Map<String, StreamSubscription<OrderStatus>> _subs = {};

  @override
  List<TrackedOrder> build() {
    ref.onDispose(() {
      for (final sub in _subs.values) {
        unawaited(sub.cancel());
      }
      _subs.clear();
    });
    return const [];
  }

  /// Start tracking [serverOrderId]. Idempotent per order id, so a resend (same
  /// idempotency key, same server id) never adds a duplicate.
  void track(String serverOrderId, int? sequence) {
    if (_subs.containsKey(serverOrderId)) return;
    state = [
      ...state,
      TrackedOrder(serverOrderId: serverOrderId, sequence: sequence),
    ];
    final service = ref.read(orderingServiceProvider);
    _subs[serverOrderId] = service.watchOrder(serverOrderId).listen((status) {
      final wasDone = state.any(
        (o) => o.serverOrderId == serverOrderId && o.stage == OrderStage.done,
      );
      state = [
        for (final o in state)
          if (o.serverOrderId == serverOrderId)
            o.withStage(status.stage)
          else
            o,
      ];
      // The payoff: fire a one-shot alert when an order first becomes ready, so
      // the customer knows without watching the screen.
      if (status.stage == OrderStage.done && !wasDone) {
        unawaited(ref.read(alertSignalProvider).fire());
      }
    });
  }
}

final orderTrackerProvider = NotifierProvider<OrderTracker, List<TrackedOrder>>(
  OrderTracker.new,
);

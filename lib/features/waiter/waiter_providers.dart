import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/acceptance/order_acceptance.dart';
import '../../domain/loyalty/redemption.dart';
import '../../domain/timing/order_progress.dart';
import '../../domain/waiter/waiter_request.dart';

/// Orders waiting for a waiter to confirm, on the configured venue. Refreshed
/// via `ref.invalidate` after each accept. Read-only view over the waiter-side
/// `OrderAcceptanceService`, so the surface stays dumb.
final waiterPendingProvider = FutureProvider.autoDispose<List<AwaitingOrder>>((
  ref,
) async {
  final service = ref.watch(orderAcceptanceServiceProvider);
  final cfg = ref.watch(appConfigProvider);
  return service.pending(cfg.venueId);
});

/// Table-to-waiter requests (call waiter / bill) waiting on the venue. Read-only
/// view over `WaiterRequestBoard`, refreshed on the same poll as the orders.
final waiterRequestsProvider = FutureProvider.autoDispose<List<WaiterRequest>>((
  ref,
) async {
  final board = ref.watch(waiterRequestBoardProvider);
  final cfg = ref.watch(appConfigProvider);
  return board.requests(cfg.venueId);
});

/// Orders accepted but not yet delivered, for the waiter's in-progress view
/// (mark ready / delivered, show the timings).
final waiterInProgressProvider =
    FutureProvider.autoDispose<List<ProgressOrder>>((ref) async {
      final progress = ref.watch(orderProgressProvider);
      final cfg = ref.watch(appConfigProvider);
      return progress.inProgress(cfg.venueId);
    });

/// Reward redemptions awaiting staff validation on the venue, oldest first.
/// Read-only view over the staff-side `RedemptionBoard`.
final pendingRedemptionsProvider =
    FutureProvider.autoDispose<List<Redemption>>((ref) async {
      final board = ref.watch(redemptionBoardProvider);
      final cfg = ref.watch(appConfigProvider);
      return board.pending(cfg.venueId);
    });

/// Total things needing the waiter (pending orders + requests + redemptions to
/// validate). The surface listens to this to fire a staff alert when it grows.
final waiterAlertCountProvider = Provider.autoDispose<int>((ref) {
  final orders = ref.watch(waiterPendingProvider).value?.length ?? 0;
  final requests = ref.watch(waiterRequestsProvider).value?.length ?? 0;
  final redemptions = ref.watch(pendingRedemptionsProvider).value?.length ?? 0;
  return orders + requests + redemptions;
});

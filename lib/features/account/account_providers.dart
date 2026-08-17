import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/history/past_order.dart';
import '../../domain/loyalty/loyalty_policy.dart';
import '../../domain/loyalty/loyalty_status.dart';
import '../table/customer_provider.dart';

/// The signed-in customer's order history, from the backend (empty from the
/// in-app mock, which keeps no history). Keyed by the anonymous client id.
final orderHistoryProvider = FutureProvider.autoDispose<List<PastOrder>>((
  ref,
) async {
  final source = ref.watch(historySourceProvider);
  final cfg = ref.watch(appConfigProvider);
  final clientId = ref.watch(clientIdProvider);
  return source.orders(cfg.venueId, clientId);
});

/// The customer's loyalty standing (points + reward ladder progress), derived
/// from the same order history and the venue program. The View just renders it;
/// the earning rule lives in the pure `computeLoyalty` (Domain).
final loyaltyStatusProvider = Provider.autoDispose<AsyncValue<LoyaltyStatus>>((
  ref,
) {
  final program = ref.watch(appConfigProvider).loyaltyProgram;
  return ref
      .watch(orderHistoryProvider)
      .whenData(
        (history) => computeLoyalty(history: history, program: program),
      );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/history/past_order.dart';
import '../../domain/loyalty/loyalty_policy.dart';
import '../../domain/loyalty/loyalty_status.dart';
import '../../domain/loyalty/redemption.dart';
import '../session/session_controller.dart';
import '../table/customer_provider.dart';

/// What loyalty, history and redemptions are keyed by: the stable `customerId`
/// once the customer signs in, else the anonymous per-device `clientId`. So an
/// anonymous customer still accrues locally-visible data, and it merges to the
/// identity on sign-in (the merge itself lands with the real backend).
final loyaltyKeyProvider = Provider<String>((ref) {
  final identity = ref.watch(sessionProvider.select((s) => s.identity));
  return identity?.customerId ?? ref.watch(clientIdProvider);
});

/// The customer's order history, from the backend (empty from the in-app mock,
/// which keeps no history). Keyed by the effective loyalty key.
final orderHistoryProvider = FutureProvider.autoDispose<List<PastOrder>>((
  ref,
) async {
  final source = ref.watch(historySourceProvider);
  final cfg = ref.watch(appConfigProvider);
  final key = ref.watch(loyaltyKeyProvider);
  return source.orders(cfg.venueId, key);
});

/// The customer's redemptions (rewards already claimed with points), from the
/// backend. Keyed by the anonymous client id; empty on the in-app mock.
final redemptionsProvider = FutureProvider.autoDispose<List<Redemption>>((
  ref,
) async {
  final redeemer = ref.watch(rewardRedeemerProvider);
  final cfg = ref.watch(appConfigProvider);
  final key = ref.watch(loyaltyKeyProvider);
  return redeemer.forCustomer(cfg.venueId, key);
});

/// The customer's loyalty standing (spendable points + ladder progress), derived
/// from the order history, the venue program and the points already spent on
/// redemptions. The View just renders it; the rule lives in `computeLoyalty`.
final loyaltyStatusProvider = Provider.autoDispose<AsyncValue<LoyaltyStatus>>((
  ref,
) {
  final program = ref.watch(appConfigProvider).loyaltyProgram;
  final redeemed = ref
      .watch(redemptionsProvider)
      .maybeWhen(
        data: (list) => list.fold<int>(0, (sum, r) => sum + r.cost),
        orElse: () => 0,
      );
  return ref
      .watch(orderHistoryProvider)
      .whenData(
        (history) => computeLoyalty(
          history: history,
          program: program,
          redeemedPoints: redeemed,
        ),
      );
});

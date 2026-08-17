import '../history/past_order.dart';
import 'loyalty_program.dart';
import 'loyalty_status.dart';
import 'reward_tier.dart';

/// Bani in one leu; points are earned per whole leu spent, so partial bani do
/// not count. 100 is the allowed money constant across the app.
const int _minorPerMajor = 100;

/// Pure derivation of a customer's loyalty standing from their order history, the
/// venue program and the points already spent on rewards. Points earned come from
/// spend (floored to whole currency units) -- honest data derived from the orders
/// the backend keeps, no separate earning ledger to drift. [redeemedPoints] (the
/// cost of rewards already claimed) is subtracted, so the returned [points] are
/// what is still spendable and a reward "unlocks" only when it is affordable now.
LoyaltyStatus computeLoyalty({
  required List<PastOrder> history,
  required LoyaltyProgram program,
  int redeemedPoints = 0,
}) {
  final spentMinor = history.fold<int>(
    0,
    (sum, order) => sum + order.total.amountMinor,
  );
  final earned = (spentMinor ~/ _minorPerMajor) * program.pointsPerMajorUnit;
  final available = earned - redeemedPoints;
  final points = available < 0 ? 0 : available;

  final tiers = [...program.tiers]
    ..sort((a, b) => a.thresholdPoints.compareTo(b.thresholdPoints));
  final unlocked = tiers
      .where((tier) => points >= tier.thresholdPoints)
      .toList();

  RewardTier? next;
  for (final tier in tiers) {
    if (points < tier.thresholdPoints) {
      next = tier;
      break;
    }
  }

  if (next == null) {
    return LoyaltyStatus(
      points: points,
      unlocked: unlocked,
      nextTier: null,
      pointsToNext: 0,
      progress: 1,
    );
  }

  final floor = unlocked.isEmpty ? 0 : unlocked.last.thresholdPoints;
  final span = next.thresholdPoints - floor;
  final into = points - floor;
  return LoyaltyStatus(
    points: points,
    unlocked: unlocked,
    nextTier: next,
    pointsToNext: next.thresholdPoints - points,
    progress: span == 0 ? 0 : into / span,
  );
}

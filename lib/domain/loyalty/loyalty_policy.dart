import '../history/past_order.dart';
import 'loyalty_program.dart';
import 'loyalty_status.dart';
import 'reward_tier.dart';

/// Bani in one leu; points are earned per whole leu spent, so partial bani do
/// not count. 100 is the allowed money constant across the app.
const int _minorPerMajor = 100;

/// Pure derivation of a customer's loyalty standing from their order history and
/// the venue program. Points come from spend (floored to whole currency units),
/// so this is honest data derived from the orders the backend already keeps --
/// no separate points ledger to drift out of sync.
LoyaltyStatus computeLoyalty({
  required List<PastOrder> history,
  required LoyaltyProgram program,
}) {
  final spentMinor = history.fold<int>(
    0,
    (sum, order) => sum + order.total.amountMinor,
  );
  final points = (spentMinor ~/ _minorPerMajor) * program.pointsPerMajorUnit;

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

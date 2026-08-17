import 'package:flutter/foundation.dart';

import 'reward_tier.dart';

/// A loyal customer's standing in the program: their [points], the rewards they
/// have [unlocked], the [nextTier] still to reach (null when all are unlocked),
/// how many [pointsToNext] remain and how far along ([progress] in 0..1) they
/// are toward it.
@immutable
class LoyaltyStatus {
  final int points;
  final List<RewardTier> unlocked;
  final RewardTier? nextTier;
  final int pointsToNext;
  final double progress;

  const LoyaltyStatus({
    required this.points,
    required this.unlocked,
    required this.nextTier,
    required this.pointsToNext,
    required this.progress,
  });
}

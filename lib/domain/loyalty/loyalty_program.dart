import 'package:flutter/foundation.dart';

import 'reward_tier.dart';

/// The venue's loyalty program: how spend turns into points, and the reward
/// ladder. DATA, not code -- a new venue supplies its own (policy vs mechanism),
/// like branding or happy hours. Empty ladder = the program is off.
@immutable
class LoyaltyProgram {
  /// Points earned per whole currency unit spent (e.g. 1 point per leu).
  final int pointsPerMajorUnit;

  /// The reward ladder. Order does not matter; the policy sorts by threshold.
  final List<RewardTier> tiers;

  const LoyaltyProgram({this.pointsPerMajorUnit = 1, this.tiers = const []});

  factory LoyaltyProgram.fromJson(Map<String, dynamic> json) => LoyaltyProgram(
    pointsPerMajorUnit: (json['pointsPerMajorUnit'] as num?)?.toInt() ?? 1,
    tiers: ((json['tiers'] as List?) ?? const [])
        .map((e) => RewardTier.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'pointsPerMajorUnit': pointsPerMajorUnit,
    'tiers': [for (final tier in tiers) tier.toJson()],
  };

  bool get isActive => tiers.isNotEmpty;
}

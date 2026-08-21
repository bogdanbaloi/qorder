import 'package:flutter/foundation.dart';

/// One rung of the venue's loyalty ladder: reach [thresholdPoints] and the
/// [reward] unlocks. The reward text is venue CONTENT (like a menu item name),
/// so the RO/EN toggle leaves it as the venue wrote it.
@immutable
class RewardTier {
  final int thresholdPoints;
  final String reward;

  const RewardTier({required this.thresholdPoints, required this.reward});

  factory RewardTier.fromJson(Map<String, dynamic> json) => RewardTier(
    thresholdPoints: (json['thresholdPoints'] as num).toInt(),
    reward: json['reward'] as String,
  );

  Map<String, dynamic> toJson() => {
    'thresholdPoints': thresholdPoints,
    'reward': reward,
  };
}

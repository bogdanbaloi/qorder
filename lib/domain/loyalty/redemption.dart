import 'package:flutter/foundation.dart';

/// A reward the customer spent points on. Carries a short [code] they show the
/// staff, who then validate it ([consumed] flips true). [cost] is the points
/// spent, so the client keeps the points economy honest.
@immutable
class Redemption {
  final String id;
  final String reward;
  final int cost;
  final String code;
  final bool consumed;
  final int createdAtMs;

  const Redemption({
    required this.id,
    required this.reward,
    required this.cost,
    required this.code,
    required this.consumed,
    required this.createdAtMs,
  });

  factory Redemption.fromJson(Map<String, dynamic> j) => Redemption(
    id: j['id'] as String,
    reward: j['reward'] as String,
    cost: (j['cost'] as num).toInt(),
    code: j['code'] as String,
    consumed: j['consumed'] as bool? ?? false,
    createdAtMs: (j['createdAtMs'] as num?)?.toInt() ?? 0,
  );
}

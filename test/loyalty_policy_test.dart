import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/core/money.dart';
import 'package:qorder/domain/history/past_order.dart';
import 'package:qorder/domain/loyalty/loyalty_policy.dart';
import 'package:qorder/domain/loyalty/loyalty_program.dart';
import 'package:qorder/domain/loyalty/reward_tier.dart';

// REQ-LOYAL-004: loyalty points + reward ladder are derived from the order
// history spend (1 point per leu), so the standing never drifts from the orders.
PastOrder _order(int minor) => PastOrder(
  sequence: 1,
  tableNumber: 5,
  total: Money(minor),
  stage: 'done',
  submittedAtMs: 0,
);

const _program = LoyaltyProgram(
  tiers: [
    RewardTier(thresholdPoints: 100, reward: 'Beer'),
    RewardTier(thresholdPoints: 250, reward: 'Platter'),
  ],
);

void main() {
  test('no history means zero points and the first tier is next', () {
    final status = computeLoyalty(history: const [], program: _program);
    expect(status.points, 0);
    expect(status.unlocked, isEmpty);
    expect(status.nextTier?.thresholdPoints, 100);
    expect(status.pointsToNext, 100);
    expect(status.progress, 0);
  });

  test('points come from spend floored to whole lei', () {
    // 150.90 lei -> 150 points.
    final status = computeLoyalty(
      history: [_order(15090)],
      program: _program,
    );
    expect(status.points, 150);
    expect(status.unlocked.length, 1); // the 100 tier
    expect(status.nextTier?.thresholdPoints, 250);
    expect(status.pointsToNext, 100); // 250 - 150
    // Halfway from 100 to 250.
    expect(status.progress, closeTo(0.333, 0.01));
  });

  test('spending past the top tier unlocks all and clears the next', () {
    final status = computeLoyalty(
      history: [_order(30000), _order(30000)], // 600 points
      program: _program,
    );
    expect(status.points, 600);
    expect(status.unlocked.length, 2);
    expect(status.nextTier, isNull);
    expect(status.pointsToNext, 0);
    expect(status.progress, 1);
  });

  test('an empty program unlocks nothing and has no next tier', () {
    final status = computeLoyalty(
      history: [_order(50000)],
      program: const LoyaltyProgram(),
    );
    expect(status.points, 500);
    expect(status.unlocked, isEmpty);
    expect(status.nextTier, isNull);
  });

  test('redeemed points are spent, so a claimed reward re-locks', () {
    // Earned 150, spent 100 on the beer -> 50 spendable, beer no longer unlocked.
    final status = computeLoyalty(
      history: [_order(15000)],
      program: _program,
      redeemedPoints: 100,
    );
    expect(status.points, 50);
    expect(status.unlocked, isEmpty);
    expect(status.nextTier?.thresholdPoints, 100);
  });

  test('spendable points never go negative', () {
    final status = computeLoyalty(
      history: [_order(5000)], // 50 earned
      program: _program,
      redeemedPoints: 100, // spent more than earned (defensive)
    );
    expect(status.points, 0);
  });
}

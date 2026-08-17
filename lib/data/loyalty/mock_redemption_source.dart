import '../../domain/loyalty/redemption.dart';
import '../../domain/loyalty/redemption_source.dart';

/// The in-app mock keeps no history, so a customer never accrues points and the
/// redeem button never appears; these are here to satisfy the ports. The demo
/// runs against the BFF, which does record redemptions.
class MockRedemptionSource implements RewardRedeemer, RedemptionBoard {
  const MockRedemptionSource();

  @override
  Future<Redemption> redeem(
    String venueId,
    String clientId, {
    required String reward,
    required int cost,
  }) async => Redemption(
    id: 'mock',
    reward: reward,
    cost: cost,
    code: '------',
    consumed: false,
    createdAtMs: 0,
  );

  @override
  Future<List<Redemption>> forCustomer(String venueId, String clientId) async =>
      const [];

  @override
  Future<List<Redemption>> pending(String venueId) async => const [];

  @override
  Future<void> consume(String code) => Future<void>.value();
}

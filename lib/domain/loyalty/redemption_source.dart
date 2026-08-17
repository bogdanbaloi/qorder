import 'redemption.dart';

/// Customer side of redemptions (Interface Segregation): spend points on a
/// reward and read your own redemptions. The staff side is [RedemptionBoard].
abstract interface class RewardRedeemer {
  /// Spend [cost] points on [reward]; the returned [Redemption] carries the code
  /// to show the staff. Throws when the backend rejects it.
  Future<Redemption> redeem(
    String venueId,
    String clientId, {
    required String reward,
    required int cost,
  });

  /// The customer's redemptions on the venue, newest first.
  Future<List<Redemption>> forCustomer(String venueId, String clientId);
}

/// Staff side of redemptions: list the ones awaiting validation and validate a
/// code. Kept separate from [RewardRedeemer] so neither role sees the other's
/// operations.
abstract interface class RedemptionBoard {
  Future<List<Redemption>> pending(String venueId);

  /// Validate a customer's code. Throws when the backend rejects it.
  Future<void> consume(String code);
}

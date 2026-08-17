import 'dart:math';

import 'models.dart';

/// The reward-redemption store PORT (Dependency Inversion), separate from orders:
/// spending loyalty points is not an order and never touches the POS. A
/// persistent implementation drops in behind this same interface later.
abstract interface class RedemptionStore {
  /// Record a customer spending points on a reward. Returns the redemption with
  /// its generated [BffRedemption.code], which the customer shows the staff.
  BffRedemption create({
    required String venueId,
    required String clientId,
    required String reward,
    required int cost,
  });

  /// A customer's redemptions on the venue, newest first (for their history).
  List<BffRedemption> forCustomer(String venueId, String clientId);

  /// Redemptions awaiting staff validation on the venue, oldest first.
  List<BffRedemption> pending(String venueId);

  /// Validate a redemption by its code (a staff action). Returns whether a
  /// pending redemption with that code existed.
  bool consume(String code);

  /// Re-key redemptions from an anonymous [oldClientId] to [newClientId], so a
  /// customer's pre-sign-in redemptions follow them. Idempotent.
  void relink(String oldClientId, String newClientId);
}

/// A short, human-readable code without ambiguous characters (no O/0, I/1), so a
/// customer can read it out to the staff without confusion.
String defaultRedemptionCode(int sequence) {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final rng = Random();
  const length = 6;
  return List.generate(
    length,
    (_) => alphabet[rng.nextInt(alphabet.length)],
  ).join();
}

class InMemoryRedemptionStore implements RedemptionStore {
  /// Injectable so tests get deterministic codes; production uses the random one.
  final String Function(int sequence) codeFor;

  InMemoryRedemptionStore({this.codeFor = defaultRedemptionCode});

  int _sequence = 0;
  final Map<String, BffRedemption> _byId = {};

  @override
  BffRedemption create({
    required String venueId,
    required String clientId,
    required String reward,
    required int cost,
  }) {
    _sequence += 1;
    final redemption = BffRedemption(
      id: 'RDM-$_sequence',
      venueId: venueId,
      clientId: clientId,
      reward: reward,
      cost: cost,
      code: codeFor(_sequence),
      createdAtMs: _sequence,
    );
    _byId[redemption.id] = redemption;
    return redemption;
  }

  @override
  List<BffRedemption> forCustomer(String venueId, String clientId) => _byId
      .values
      .where((r) => r.venueId == venueId && r.clientId == clientId)
      .toList()
    ..sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));

  @override
  List<BffRedemption> pending(String venueId) => _byId.values
      .where((r) => r.venueId == venueId && !r.consumed)
      .toList()
    ..sort((a, b) => a.createdAtMs.compareTo(b.createdAtMs));

  @override
  bool consume(String code) {
    for (final r in _byId.values) {
      if (r.code == code && !r.consumed) {
        r.consumed = true;
        return true;
      }
    }
    return false;
  }

  @override
  void relink(String oldClientId, String newClientId) {
    for (final r in _byId.values) {
      if (r.clientId == oldClientId) r.clientId = newClientId;
    }
  }
}

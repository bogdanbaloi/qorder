import 'package:flutter/foundation.dart';

/// What a customer can consent to, per purpose. Loyalty (process my orders for
/// points/history) is separate from marketing (send me offers), so each is an
/// explicit, independent choice.
enum ConsentPurpose { loyalty, marketing }

/// One recorded consent choice. A fact, not a hidden flag: captured explicitly at
/// sign-in and, in the real slice, stored per (customer, venue, purpose) with a
/// timestamp and terms version so it is auditable and withdrawable.
@immutable
class Consent {
  final ConsentPurpose purpose;
  final bool granted;

  const Consent({required this.purpose, required this.granted});

  Map<String, dynamic> toJson() => {'purpose': purpose.name, 'granted': granted};

  factory Consent.fromJson(Map<String, dynamic> j) => Consent(
    purpose: ConsentPurpose.values.firstWhere(
      (p) => p.name == j['purpose'],
      orElse: () => ConsentPurpose.loyalty,
    ),
    granted: j['granted'] as bool? ?? false,
  );
}

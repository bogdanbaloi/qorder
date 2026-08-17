import 'package:flutter/foundation.dart';

/// A customer's platform identity, proven once (phone + OTP) and portable across
/// devices. Distinct from the anonymous per-device `clientId`: the [customerId]
/// is what loyalty follows, the [phone] is the venue's first-party record, and
/// the [token] authenticates requests (enforced from the BFF in a later slice).
@immutable
class CustomerIdentity {
  final String customerId;
  final String phone;
  final String token;

  const CustomerIdentity({
    required this.customerId,
    required this.phone,
    required this.token,
  });

  Map<String, dynamic> toJson() => {
    'customerId': customerId,
    'phone': phone,
    'token': token,
  };

  factory CustomerIdentity.fromJson(Map<String, dynamic> j) => CustomerIdentity(
    customerId: j['customerId'] as String,
    phone: j['phone'] as String? ?? '',
    token: j['token'] as String? ?? '',
  );

  @override
  bool operator ==(Object other) =>
      other is CustomerIdentity &&
      other.customerId == customerId &&
      other.phone == phone &&
      other.token == token;

  @override
  int get hashCode => Object.hash(customerId, phone, token);
}

import 'package:flutter/foundation.dart';

import 'customer_identity.dart';

/// Who is using the app. Customer is the default (anonymous). Staff (waiter and
/// barman share one account, as agreed with the owner) and owner sign in with an
/// access code. Real staff/owner auth (ideally Ebriza users) comes later.
enum AppRole { customer, staff, owner }

/// The current session: a role, plus the customer's identity once they sign in
/// with their phone. A loyal customer is simply an identified one, so the
/// identity subsumes the old normal/loyal flag. Immutable value, read across the
/// surfaces.
@immutable
class Session {
  final AppRole role;

  /// The signed-in customer's identity, or null when anonymous.
  final CustomerIdentity? identity;

  const Session({this.role = AppRole.customer, this.identity});

  bool get isStaff => role == AppRole.staff;
  bool get isOwner => role == AppRole.owner;
  bool get isSignedIn => identity != null;

  /// A loyal (identified) customer: signed in AND acting as a customer.
  bool get isLoyalCustomer => role == AppRole.customer && isSignedIn;

  /// Maps a persisted role name back to a role, defaulting to customer.
  static AppRole roleFromCode(String? code) => AppRole.values.firstWhere(
    (r) => r.name == code,
    orElse: () => AppRole.customer,
  );
}

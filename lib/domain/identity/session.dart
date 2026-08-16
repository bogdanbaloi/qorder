import 'package:flutter/foundation.dart';

/// Who is using the app. Customer is the default (anonymous). Staff (waiter and
/// barman share one account, as agreed with the owner) and owner sign in. Real
/// auth (ideally the Ebriza users) comes in a later step.
enum AppRole { customer, staff, owner }

/// Sub-kind of a customer: a normal QR walk-up vs a loyal, identified customer.
/// Only `normal` is reached in the flow today; `loyal` is the identity seam for
/// the installed-app features (in-app QR table scan, history, points).
enum CustomerKind { normal, loyal }

/// The current session: a role, plus the customer sub-kind. Immutable value, so
/// the identity is a single source of truth read across the surfaces.
@immutable
class Session {
  final AppRole role;
  final CustomerKind customerKind;

  const Session({
    this.role = AppRole.customer,
    this.customerKind = CustomerKind.normal,
  });

  bool get isStaff => role == AppRole.staff;
  bool get isOwner => role == AppRole.owner;
  bool get isLoyalCustomer =>
      role == AppRole.customer && customerKind == CustomerKind.loyal;

  Session copyWith({AppRole? role, CustomerKind? customerKind}) => Session(
    role: role ?? this.role,
    customerKind: customerKind ?? this.customerKind,
  );

  /// Maps a persisted role name back to a role, defaulting to customer.
  static AppRole roleFromCode(String? code) => AppRole.values.firstWhere(
    (r) => r.name == code,
    orElse: () => AppRole.customer,
  );
}

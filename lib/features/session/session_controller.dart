import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/identity/session.dart';

/// Holds the current [Session] (role + customer kind). Defaults to an anonymous
/// customer. Staff sign in through the access gate; the role is persisted through
/// the `LocalStore` port so a dedicated waiter tablet stays signed in across
/// restarts. Real staff/owner auth (Ebriza) replaces the code later.
class SessionController extends Notifier<Session> {
  static const _box = 'settings';
  static const _key = 'sessionRole';

  @override
  Session build() {
    unawaited(_restore());
    return const Session();
  }

  Future<void> _restore() async {
    final stored = await ref.read(localStoreProvider).get(_box, _key);
    final role = Session.roleFromCode(stored?['role'] as String?);
    if (role != AppRole.customer) state = state.copyWith(role: role);
  }

  void signInAsStaff() => _setRole(AppRole.staff);
  void signOut() => _setRole(AppRole.customer);

  void _setRole(AppRole role) {
    state = state.copyWith(role: role);
    unawaited(
      ref.read(localStoreProvider).put(_box, _key, {'role': role.name}),
    );
  }

  /// Marks the customer as loyal (installed / enrolled). The gate for the
  /// loyal-only features, filled in when enrollment lands.
  void setCustomerKind(CustomerKind kind) =>
      state = state.copyWith(customerKind: kind);
}

final sessionProvider = NotifierProvider<SessionController, Session>(
  SessionController.new,
);

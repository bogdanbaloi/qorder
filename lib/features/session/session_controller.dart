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
    if (stored == null) return;
    state = state.copyWith(
      role: Session.roleFromCode(stored['role'] as String?),
      customerKind: Session.kindFromCode(stored['kind'] as String?),
    );
  }

  void signInAs(AppRole role) => _update(state.copyWith(role: role));
  void signInAsStaff() => signInAs(AppRole.staff);
  void signOut() => signInAs(AppRole.customer);

  /// The customer becomes loyal (installed / enrolled), unlocking the loyal-only
  /// features (in-app table pick, history, offers). Persisted so they stay loyal.
  void enrollLoyal() =>
      _update(state.copyWith(customerKind: CustomerKind.loyal));

  void leaveLoyal() =>
      _update(state.copyWith(customerKind: CustomerKind.normal));

  void _update(Session next) {
    state = next;
    unawaited(
      ref.read(localStoreProvider).put(_box, _key, {
        'role': next.role.name,
        'kind': next.customerKind.name,
      }),
    );
  }
}

final sessionProvider = NotifierProvider<SessionController, Session>(
  SessionController.new,
);

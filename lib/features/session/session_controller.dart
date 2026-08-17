import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/identity/customer_identity.dart';
import '../../domain/identity/session.dart';

/// Holds the current [Session] (role + customer identity). Defaults to an
/// anonymous customer. Staff/owner sign in through the access gate; a customer
/// signs in with their phone. The session is persisted through the `LocalStore`
/// port, so a dedicated tablet stays signed in and a customer stays identified
/// across restarts.
class SessionController extends Notifier<Session> {
  static const _box = 'settings';
  static const _key = 'session';

  @override
  Session build() {
    unawaited(_restore());
    return const Session();
  }

  Future<void> _restore() async {
    final stored = await ref.read(localStoreProvider).get(_box, _key);
    if (stored == null) return;
    final identityJson = stored['identity'];
    state = Session(
      role: Session.roleFromCode(stored['role'] as String?),
      identity: identityJson is Map<String, dynamic>
          ? CustomerIdentity.fromJson(identityJson)
          : null,
    );
  }

  void signInAs(AppRole role) => _update(Session(role: role));
  void signInAsStaff() => signInAs(AppRole.staff);
  void signOut() => _update(const Session());

  /// The customer completed phone sign-in: they become an identified (loyal)
  /// customer, persisted so they stay signed in and their loyalty follows them.
  void signInCustomer(CustomerIdentity identity) =>
      _update(Session(identity: identity));

  void _update(Session next) {
    state = next;
    unawaited(
      ref.read(localStoreProvider).put(_box, _key, {
        'role': next.role.name,
        if (next.identity != null) 'identity': next.identity!.toJson(),
      }),
    );
  }
}

final sessionProvider = NotifierProvider<SessionController, Session>(
  SessionController.new,
);

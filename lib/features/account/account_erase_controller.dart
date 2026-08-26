import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../session/session_controller.dart';
import '../table/customer_provider.dart';

/// The state of the "delete my data" action. Immutable, so the View rebuilds
/// from a new value (MVVM).
@immutable
class AccountEraseState {
  final bool deleting;
  final bool failed;

  const AccountEraseState({this.deleting = false, this.failed = false});

  AccountEraseState copyWith({bool? deleting, bool? failed}) =>
      AccountEraseState(
        deleting: deleting ?? this.deleting,
        failed: failed ?? this.failed,
      );
}

/// The "delete my data" ViewModel (GDPR right to erasure). It erases the customer
/// on the backend, then signs the session out and clears the local name, so both
/// the server and the device are cleared (REQ-GDPR-002).
class AccountEraseController extends Notifier<AccountEraseState> {
  @override
  AccountEraseState build() => const AccountEraseState();

  /// Returns true when the data was erased and the session cleared.
  Future<bool> delete() async {
    final customerId = ref.read(sessionProvider).identity?.customerId;
    if (customerId == null) return false;
    state = state.copyWith(deleting: true, failed: false);
    try {
      await ref.read(accountEraserProvider).erase(customerId);
      // Local erasure: drop the identity (and loyal status) and the saved name.
      ref.read(sessionProvider.notifier).signOut();
      ref.read(customerNameProvider.notifier).set('');
      state = state.copyWith(deleting: false);
      return true;
    } on Object catch (_) {
      state = state.copyWith(deleting: false, failed: true);
      return false;
    }
  }
}

final accountEraseControllerProvider =
    NotifierProvider.autoDispose<AccountEraseController, AccountEraseState>(
      AccountEraseController.new,
    );

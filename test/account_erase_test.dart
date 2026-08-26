import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/di/providers.dart';
import 'package:qorder/domain/identity/account_eraser.dart';
import 'package:qorder/domain/identity/customer_identity.dart';
import 'package:qorder/features/account/account_erase_controller.dart';
import 'package:qorder/features/session/session_controller.dart';
import 'package:qorder/features/table/customer_provider.dart';

/// Records the erase call, so the test proves the ViewModel hits the backend.
class _FakeEraser implements AccountEraser {
  String? erasedId;

  @override
  Future<void> erase(String customerId) async {
    erasedId = customerId;
  }
}

/// REQ-GDPR-002: "delete my data" erases on the backend, then signs out and
/// clears the local name, so both the server and the device are cleared.
void main() {
  test('delete erases on the backend and clears the local session', () async {
    final eraser = _FakeEraser();
    final container = ProviderContainer(
      overrides: [accountEraserProvider.overrideWithValue(eraser)],
    );
    addTearDown(container.dispose);

    container.read(sessionProvider.notifier).signInCustomer(
          CustomerIdentity(
            customerId: 'c1',
            phone: '0712345678',
            token: 't1',
          ),
        );
    container.read(customerNameProvider.notifier).set('Alice');

    final ok =
        await container.read(accountEraseControllerProvider.notifier).delete();

    expect(ok, isTrue);
    expect(eraser.erasedId, 'c1'); // erased on the backend
    expect(container.read(sessionProvider).identity, isNull); // signed out
    expect(container.read(customerNameProvider), ''); // name cleared
  });

  test('delete does nothing when not signed in', () async {
    final eraser = _FakeEraser();
    final container = ProviderContainer(
      overrides: [accountEraserProvider.overrideWithValue(eraser)],
    );
    addTearDown(container.dispose);

    final ok =
        await container.read(accountEraseControllerProvider.notifier).delete();

    expect(ok, isFalse);
    expect(eraser.erasedId, isNull);
  });
}

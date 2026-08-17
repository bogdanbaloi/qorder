import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/core/storage/local_store.dart';
import 'package:qorder/di/providers.dart';
import 'package:qorder/domain/identity/customer_identity.dart';
import 'package:qorder/domain/identity/session.dart';
import 'package:qorder/features/session/role_guard.dart';
import 'package:qorder/features/session/session_controller.dart';

// REQ-STAFF-001: a role/identity seam; staff sign in behind an access code and
// the role persists. REQ-IDENT-001: a customer signs in with their phone and the
// identity persists, so loyalty follows them (a loyal customer is an identified
// one).
const _identity = CustomerIdentity(
  customerId: 'cust:0740',
  phone: '0740123456',
  token: 'mock',
);

void main() {
  test('defaults to an anonymous customer', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final session = container.read(sessionProvider);
    expect(session.role, AppRole.customer);
    expect(session.isStaff, false);
    expect(session.isSignedIn, false);
    expect(session.isLoyalCustomer, false);
  });

  test('signInAsStaff and signOut flip the role', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(sessionProvider.notifier).signInAsStaff();
    expect(container.read(sessionProvider).isStaff, true);
    container.read(sessionProvider.notifier).signOut();
    expect(container.read(sessionProvider).isStaff, false);
  });

  test('the staff role persists across sessions', () async {
    final store = InMemoryLocalStore();
    final first = ProviderContainer(
      overrides: [localStoreProvider.overrideWithValue(store)],
    );
    first.read(sessionProvider.notifier).signInAsStaff();
    await pumpEventQueue();
    first.dispose();

    final second = ProviderContainer(
      overrides: [localStoreProvider.overrideWithValue(store)],
    );
    addTearDown(second.dispose);
    expect(second.read(sessionProvider).role, AppRole.customer); // sync default
    await pumpEventQueue(); // async restore
    expect(second.read(sessionProvider).role, AppRole.staff);
  });

  test('a customer sign-in persists the identity, sign-out clears it', () async {
    final store = InMemoryLocalStore();
    final first = ProviderContainer(
      overrides: [localStoreProvider.overrideWithValue(store)],
    );
    first.read(sessionProvider.notifier).signInCustomer(_identity);
    expect(first.read(sessionProvider).isLoyalCustomer, true);
    await pumpEventQueue();
    first.dispose();

    final second = ProviderContainer(
      overrides: [localStoreProvider.overrideWithValue(store)],
    );
    addTearDown(second.dispose);
    // Read builds the notifier and starts the async restore, then flush it.
    expect(second.read(sessionProvider).isSignedIn, false);
    await pumpEventQueue();
    final restored = second.read(sessionProvider);
    expect(restored.isLoyalCustomer, true);
    expect(restored.identity?.customerId, 'cust:0740');

    second.read(sessionProvider.notifier).signOut();
    expect(second.read(sessionProvider).isSignedIn, false);
  });

  test('roleFromCode falls back to customer for an unknown code', () {
    expect(Session.roleFromCode('staff'), AppRole.staff);
    expect(Session.roleFromCode('owner'), AppRole.owner);
    expect(Session.roleFromCode('bogus'), AppRole.customer);
    expect(Session.roleFromCode(null), AppRole.customer);
  });

  testWidgets('the staff gate blocks the surface until the code is entered', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: RoleGuard(role: AppRole.staff, child: Text('SURFACE')),
        ),
      ),
    );

    expect(find.text('SURFACE'), findsNothing);
    expect(find.text('Intră'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '0000'); // wrong code
    await tester.tap(find.text('Intră'));
    await tester.pumpAndSettle();
    expect(find.text('SURFACE'), findsNothing);

    await tester.enterText(find.byType(TextField), '2468'); // demo code
    await tester.tap(find.text('Intră'));
    await tester.pumpAndSettle();
    expect(find.text('SURFACE'), findsOneWidget);
  });
}

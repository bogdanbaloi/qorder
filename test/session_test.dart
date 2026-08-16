import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/core/storage/local_store.dart';
import 'package:qorder/di/providers.dart';
import 'package:qorder/domain/identity/session.dart';
import 'package:qorder/features/session/role_guard.dart';
import 'package:qorder/features/session/session_controller.dart';

// REQ-STAFF-001: a role/identity seam; staff sign in behind an access code and
// the role persists, so the staff surface is not open to anyone with the URL.
void main() {
  test('defaults to an anonymous customer', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final session = container.read(sessionProvider);
    expect(session.role, AppRole.customer);
    expect(session.isStaff, false);
    expect(session.customerKind, CustomerKind.normal);
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

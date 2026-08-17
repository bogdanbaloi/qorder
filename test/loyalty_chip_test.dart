import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/domain/identity/customer_identity.dart';
import 'package:qorder/features/account/loyalty_chip.dart';
import 'package:qorder/features/session/session_controller.dart';

// REQ-LOYAL-005: a loyal customer sees their points during ordering (an app-bar
// chip), so the payoff is visible in the flow; a normal customer sees nothing.
void main() {
  testWidgets('the points chip shows for a loyal customer, hidden for normal', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(appBar: null, body: LoyaltyChip()),
        ),
      ),
    );

    // A normal customer: no chip.
    expect(find.byType(ActionChip), findsNothing);

    // Sign in as a customer: the chip appears, showing zero points (no spend).
    container.read(sessionProvider.notifier).signInCustomer(
      const CustomerIdentity(customerId: 'c', phone: 'p', token: 't'),
    );
    await tester.pump();
    expect(find.byType(ActionChip), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });
}

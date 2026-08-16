import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:qorder/app/app.dart';

// REQ-FLOW-001: full happy path - browse -> add -> set table -> submit.
// Runs on a device/emulator: `flutter test integration_test`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('scan(menu) -> add item -> set table -> submit -> confirmed', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: QorderApp()));
    await tester.pumpAndSettle();

    // Add the first tappable menu item.
    final firstItem = find.byType(ListTile).first;
    await tester.tap(firstItem);
    await tester.pumpAndSettle();

    // Tapping an item opens its detail sheet; add from there.
    await tester.tap(find.text('Adaugă în coș'));
    await tester.pumpAndSettle();

    // Open the cart via the floating button.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Submit must be disabled until a valid table is entered.
    final submit = find.widgetWithText(FilledButton, 'Trimite comanda');
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);

    // The order form has a name field then a table field. The demo requires a
    // name, so submit stays disabled until both are filled.
    await tester.enterText(find.byType(TextField).at(0), 'Andrei');
    await tester.enterText(find.byType(TextField).at(1), '12');
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);

    await tester.tap(submit);
    await tester.pumpAndSettle();

    // Confirm in the review dialog.
    await tester.tap(find.widgetWithText(FilledButton, 'Trimite'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Comandă #'), findsOneWidget);
  });
}

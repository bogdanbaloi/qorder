import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/di/providers.dart';
import 'package:qorder/domain/platform/client_log_entry.dart';
import 'package:qorder/domain/platform/operator_logs_source.dart';
import 'package:qorder/domain/platform/platform_metrics.dart';
import 'package:qorder/domain/platform/platform_metrics_source.dart';
import 'package:qorder/features/admin/admin_screen.dart';

class _FakeSource implements PlatformMetricsSource {
  final PlatformMetrics result;

  _FakeSource(this.result);

  @override
  Future<PlatformMetrics> snapshot(String operatorToken) async => result;
}

class _FakeLogs implements OperatorLogsSource {
  final List<ClientLogEntry> result;

  _FakeLogs(this.result);

  @override
  Future<List<ClientLogEntry>> recent(String operatorToken) async => result;
}

Future<void> _pumpScreen(
  WidgetTester tester,
  PlatformMetricsSource source, {
  OperatorLogsSource? logs,
}) => tester.pumpWidget(
  ProviderScope(
    overrides: [
      platformMetricsSourceProvider.overrideWithValue(source),
      if (logs != null) operatorLogsSourceProvider.overrideWithValue(logs),
    ],
    child: const MaterialApp(home: AdminScreen()),
  ),
);

void main() {
  // REQ-OPS-002: the operator sees cross-venue usage after entering the token.
  testWidgets('shows cross-venue usage after entering the token', (
    tester,
  ) async {
    final source = _FakeSource(
      const PlatformMetrics(
        venueCount: 2,
        venues: [
          VenueUsage(venueId: 'demo', orders: 5, users: 3),
          VenueUsage(venueId: 'other', orders: 1, users: 1),
        ],
      ),
    );
    await _pumpScreen(tester, source);

    // Nothing shown until a token is entered.
    expect(find.text('2 localuri active'), findsNothing);

    await tester.enterText(find.byType(TextField), 'op-secret');
    await tester.tap(find.text('Încarcă'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.text('2 localuri active'), findsOneWidget);
    expect(find.text('demo'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  // REQ-OBS-003: the operator sees recent client errors after entering the token.
  testWidgets('shows recent client errors after entering the token', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      _FakeSource(const PlatformMetrics.empty()),
      logs: _FakeLogs(const [
        ClientLogEntry(
          level: 'error',
          message: 'menu load failed',
          venueId: 'demo',
        ),
      ]),
    );

    await tester.enterText(find.byType(TextField), 'op-secret');
    await tester.tap(find.text('Încarcă'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.text('menu load failed'), findsOneWidget);
  });
}

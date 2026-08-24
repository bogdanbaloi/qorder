import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/platform/client_log_entry.dart';
import '../../domain/platform/platform_metrics.dart';

/// The operator token entered on the admin screen (a platform secret, not the
/// session token). Empty until the operator types it and loads.
class OperatorToken extends Notifier<String> {
  @override
  String build() => '';

  void set(String token) => state = token;
}

final operatorTokenProvider = NotifierProvider<OperatorToken, String>(
  OperatorToken.new,
);

/// The cross-venue snapshot for the entered operator token. Empty until a token
/// is set, then fetched from the source (an error surfaces a wrong token).
final platformMetricsProvider = FutureProvider.autoDispose<PlatformMetrics>((
  ref,
) async {
  final token = ref.watch(operatorTokenProvider);
  if (token.isEmpty) return const PlatformMetrics.empty();
  return ref.watch(platformMetricsSourceProvider).snapshot(token);
});

/// Recent client diagnostics for the entered operator token. Empty until a token
/// is set, then fetched (an error surfaces a wrong token).
final operatorLogsProvider = FutureProvider.autoDispose<List<ClientLogEntry>>((
  ref,
) async {
  final token = ref.watch(operatorTokenProvider);
  if (token.isEmpty) return const [];
  return ref.watch(operatorLogsSourceProvider).recent(token);
});

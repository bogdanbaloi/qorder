import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/config/remote_venue_config_api.dart';
import '../../di/providers.dart';
import '../../domain/config/venue_config_api.dart';
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

/// The venue-config writer for operator actions (setting a venue's palette). It
/// authenticates with the operator token, not a session token, since the operator
/// is a superadmin over every venue. Offline it shares the same mock as the owner
/// writer, so the demo still round-trips. On the backend the write is authorized
/// as operator (the config PUT accepts owner or operator).
final adminVenueConfigApiProvider = Provider<VenueConfigApi>((ref) {
  final cfg = ref.watch(appConfigProvider);
  if (!cfg.useRemoteBackend) return ref.watch(venueConfigApiProvider);
  return RemoteVenueConfigApi(
    baseUrl: cfg.backendBaseUrl,
    client: ref.watch(httpClientProvider),
    authToken: ref.watch(operatorTokenProvider),
    logger: ref.watch(loggerProvider),
  );
});

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

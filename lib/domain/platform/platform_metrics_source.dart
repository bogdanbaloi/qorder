import 'platform_metrics.dart';

/// The operator-metrics PORT (Dependency Inversion). The remote adapter reads the
/// BFF's cross-venue `GET /platform/metrics`, authenticated by the operator token.
/// The token is entered by the operator (a platform secret), not the session
/// token, since the operator view spans every venue.
abstract interface class PlatformMetricsSource {
  Future<PlatformMetrics> snapshot(String operatorToken);
}

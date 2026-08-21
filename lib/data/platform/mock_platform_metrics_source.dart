import '../../domain/platform/platform_metrics.dart';
import '../../domain/platform/platform_metrics_source.dart';

/// Used with no backend: operator evidence needs the durable cross-venue data, so
/// the in-app mock reports nothing.
class MockPlatformMetricsSource implements PlatformMetricsSource {
  @override
  Future<PlatformMetrics> snapshot(String operatorToken) async =>
      const PlatformMetrics.empty();
}

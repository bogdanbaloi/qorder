import '../../domain/metrics/metrics_source.dart';
import '../../domain/metrics/sales_metrics.dart';

/// The in-app mock keeps no order history, so it reports empty sales metrics.
/// The demo runs against the BFF, which does keep the history.
class MockMetricsSource implements MetricsSource {
  const MockMetricsSource();

  @override
  Future<SalesMetrics> salesMetrics(String venueId) async =>
      const SalesMetrics.empty();
}

import 'sales_metrics.dart';

/// The owner sales-metrics PORT (Dependency Inversion). The remote adapter reads
/// the BFF's metrics endpoint; the mock returns empty (no persisted history).
/// An Ebriza-backed source drops in behind this same interface later.
abstract interface class MetricsSource {
  Future<SalesMetrics> salesMetrics(String venueId);
}

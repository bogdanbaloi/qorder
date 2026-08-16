import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/domain/metrics/venue_metrics.dart';
import 'package:qorder/domain/timing/order_timings.dart';

// REQ-OWNER-001: the owner snapshot counts what waits and averages the
// acceptance and delivery times from the in-progress orders' stamps; a leg with
// no data is left out of the average.
void main() {
  test('counts and averages the in-progress timings', () {
    const timings = [
      OrderTimings({
        'submitted': 0,
        'accepted': 4000,
        'ready': 10000,
        'delivered': 16000,
      }),
      OrderTimings({
        'submitted': 0,
        'accepted': 8000,
        'ready': 10000,
        'delivered': 14000,
      }),
    ];
    final metrics = computeVenueMetrics(
      pending: 3,
      openRequests: 1,
      inProgressTimings: timings,
    );
    expect(metrics.pending, 3);
    expect(metrics.inProgress, 2);
    expect(metrics.openRequests, 1);
    expect(metrics.avgAcceptance, const Duration(seconds: 6)); // (4 + 8) / 2
    expect(metrics.avgDelivery, const Duration(seconds: 5)); // (6 + 4) / 2
  });

  test('a leg with no data is ignored in its average', () {
    const timings = [
      OrderTimings({'submitted': 0, 'accepted': 4000}), // no ready/delivered
      OrderTimings({
        'submitted': 0,
        'accepted': 6000,
        'ready': 1000,
        'delivered': 3000,
      }),
    ];
    final metrics = computeVenueMetrics(
      pending: 0,
      openRequests: 0,
      inProgressTimings: timings,
    );
    expect(metrics.avgAcceptance, const Duration(seconds: 5)); // (4 + 6) / 2
    expect(metrics.avgDelivery, const Duration(seconds: 2)); // only the second
  });

  test('no in-progress orders gives null averages', () {
    final metrics = computeVenueMetrics(
      pending: 0,
      openRequests: 0,
      inProgressTimings: const [],
    );
    expect(metrics.inProgress, 0);
    expect(metrics.avgAcceptance, isNull);
    expect(metrics.avgDelivery, isNull);
  });
}

import '../../domain/history/history_source.dart';
import '../../domain/history/past_order.dart';

/// The in-app mock keeps no order history, so it reports none. The demo runs
/// against the BFF, which does keep the history.
class MockHistorySource implements HistorySource {
  const MockHistorySource();

  @override
  Future<List<PastOrder>> orders(String venueId, String clientId) async =>
      const [];
}

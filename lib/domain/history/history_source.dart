import 'past_order.dart';

/// The customer order-history PORT (Dependency Inversion). The remote adapter
/// reads the BFF; the mock returns none (the in-app backend keeps no history).
abstract interface class HistorySource {
  Future<List<PastOrder>> orders(String venueId, String clientId);
}

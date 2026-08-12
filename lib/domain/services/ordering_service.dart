import '../models/order.dart';

/// The ordering backend, behind an interface. Phase 0: an in-memory mock.
/// Phase 1: an Ebriza adapter (`Open bill` on a table) reached via our thin
/// backend. Swapping one for the other must not change the app.
abstract interface class OrderingService {
  /// Submit an order. Returns confirmed (with server id + FIFO sequence) or
  /// clearly failed. Must never silently drop an order.
  Future<SubmitResult> submitOrder(Order order);

  /// Watch the processing status of a submitted order (received -> preparing
  /// -> done). Drives the customer's progress UI.
  Stream<OrderStatus> watchOrder(String orderId);
}

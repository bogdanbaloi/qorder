import 'package:flutter/foundation.dart';

/// How a submitted order is accepted by the bar. Config-driven, per venue.
enum AcceptanceMode {
  /// The order goes straight through (injected to the POS immediately).
  auto,

  /// A waiter must confirm the order before the bar starts processing it.
  waiterConfirm,
}

/// Strategy for the acceptance behavior. A named domain seam, so a new mode
/// (manager-confirm, time-based auto-accept, ...) is a new class, not an `if`
/// scattered through the backend (Open/Closed).
abstract interface class OrderAcceptancePolicy {
  /// Whether a waiter must confirm before processing starts.
  bool get requiresWaiter;
}

class AutoAcceptPolicy implements OrderAcceptancePolicy {
  const AutoAcceptPolicy();

  @override
  bool get requiresWaiter => false;
}

class WaiterConfirmationPolicy implements OrderAcceptancePolicy {
  const WaiterConfirmationPolicy();

  @override
  bool get requiresWaiter => true;
}

OrderAcceptancePolicy acceptancePolicyFor(AcceptanceMode mode) =>
    switch (mode) {
      AcceptanceMode.auto => const AutoAcceptPolicy(),
      AcceptanceMode.waiterConfirm => const WaiterConfirmationPolicy(),
    };

/// An order waiting for a waiter to accept it. The waiter surface lists these.
@immutable
class AwaitingOrder {
  final String serverOrderId;
  final int tableNumber;
  final int sequence;
  final String? customerName;

  const AwaitingOrder({
    required this.serverOrderId,
    required this.tableNumber,
    required this.sequence,
    this.customerName,
  });
}

/// The waiter-side view of orders awaiting confirmation. Segregated from
/// `OrderingService` (customer-side): a waiter surface accepts orders, it never
/// submits them (Interface Segregation). Phase 1 backs this with the BFF/Ebriza.
abstract interface class OrderAcceptanceService {
  /// Orders currently waiting for a waiter, on this venue, oldest first.
  Future<List<AwaitingOrder>> pending(String venueId);

  /// Accept an order, releasing it into normal processing.
  Future<void> accept(String serverOrderId);
}

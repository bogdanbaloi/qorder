import 'dart:async';

import '../../domain/models/order.dart';
import '../../domain/services/ordering_service.dart';

/// In-memory OrderingService for Phase 0. It:
///  - assigns a MONOTONIC sequence number (demonstrates FIFO ordering),
///  - simulates network latency,
///  - can be forced to fail (to prove degrade-open + retry),
///  - streams timed status updates (processing takes real time).
class MockOrderingService implements OrderingService {
  int _sequence = 0;
  final bool forceFailure;
  final Duration latency;
  final Duration stageGap;

  MockOrderingService({
    this.forceFailure = false,
    this.latency = const Duration(milliseconds: 400),
    this.stageGap = const Duration(seconds: 1),
  });

  int get lastSequence => _sequence;

  @override
  Future<SubmitResult> submitOrder(Order order) async {
    if (latency > Duration.zero) await Future.delayed(latency);
    if (forceFailure) {
      return const SubmitFailed(reason: 'Rețea indisponibilă', retryable: true);
    }
    _sequence += 1;
    final id = order.id;
    final shortId = id.length >= 6 ? id.substring(id.length - 6) : id;
    return SubmitConfirmed(serverOrderId: 'MOCK-$shortId', sequence: _sequence);
  }

  @override
  Stream<OrderStatus> watchOrder(String orderId) async* {
    yield OrderStatus(orderId: orderId, stage: OrderStage.received);
    if (stageGap > Duration.zero) await Future.delayed(stageGap);
    yield OrderStatus(orderId: orderId, stage: OrderStage.preparing);
    if (stageGap > Duration.zero) await Future.delayed(stageGap);
    yield OrderStatus(orderId: orderId, stage: OrderStage.done);
  }
}

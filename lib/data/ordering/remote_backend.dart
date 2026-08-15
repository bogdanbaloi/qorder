import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/app_constants.dart';
import '../../domain/acceptance/order_acceptance.dart';
import '../../domain/models/order.dart';
import '../../domain/models/table_orders.dart';
import '../../domain/services/ordering_service.dart';
import '../../domain/timing/order_progress.dart';
import '../../domain/waiter/waiter_request.dart';

/// Talks to the BFF over HTTP. It implements BOTH the customer-side
/// [OrderingService] and the waiter-side [OrderAcceptanceService] (the BFF
/// serves both), so the same contract the mock fulfils in-memory is fulfilled
/// by a real server here. Swapping mock -> remote is a config change in the
/// composition root (Open/Closed): no consumer changes. The [http.Client] is
/// injected (Dependency Inversion), so it is unit-testable with a fake client.
class RemoteBackend
    implements
        OrderingService,
        OrderAcceptanceService,
        WaiterCaller,
        WaiterRequestBoard,
        OrderProgress {
  final String baseUrl;
  final http.Client client;
  final Duration pollInterval;

  RemoteBackend({
    required this.baseUrl,
    required this.client,
    this.pollInterval = AppConstants.statusPollInterval,
  });

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  @override
  Future<SubmitResult> submitOrder(Order order) async {
    try {
      final response = await client
          .post(
            _uri('/venues/${order.venueId}/orders'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode({
              'tableNumber': order.tableRef.number,
              'idempotencyKey': order.idempotencyKey,
              'customerName': order.customerName,
              'clientId': order.clientId,
              'totalMinor': order.total.amountMinor,
              'lines': order.lines
                  .map((l) => {'name': l.nameSnapshot, 'qty': l.qty})
                  .toList(),
            }),
          )
          .timeout(AppConstants.submitTimeout);
      if (response.statusCode != AppConstants.httpOk) {
        return SubmitFailed(
          reason: 'Server ${response.statusCode}',
          retryable: true,
        );
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return SubmitConfirmed(
        serverOrderId: json['serverOrderId'] as String,
        sequence: (json['sequence'] as num).toInt(),
      );
    } on TimeoutException {
      return const SubmitFailed(reason: 'Timeout', retryable: true);
    } catch (_) {
      return const SubmitFailed(reason: 'Rețea indisponibilă', retryable: true);
    }
  }

  @override
  Stream<OrderStatus> watchOrder(String serverOrderId) async* {
    OrderStage? last;
    while (true) {
      final stage = await _fetchStage(serverOrderId);
      if (stage != null && stage != last) {
        last = stage;
        yield OrderStatus(orderId: serverOrderId, stage: stage);
        if (stage == OrderStage.done) return;
      }
      await Future.delayed(pollInterval);
    }
  }

  Future<OrderStage?> _fetchStage(String serverOrderId) async {
    try {
      final response = await client.get(_uri('/orders/$serverOrderId/status'));
      if (response.statusCode != AppConstants.httpOk) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return _stageFrom(json['stage'] as String?);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<TableOrders> tableOrders(
    String venueId,
    int tableNumber, {
    required String myClientId,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/venues/$venueId/tables/$tableNumber/orders',
    ).replace(queryParameters: {'clientId': myClientId});
    final response = await client.get(uri);
    if (response.statusCode != AppConstants.httpOk) {
      return TableOrders(tableNumber: tableNumber, entries: const []);
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final entries = (json['entries'] as List)
        .map((e) => e as Map<String, dynamic>)
        .map(
          (j) => TableEntry(
            name: j['name'] as String,
            clientId: j['clientId'] as String,
            isMine: j['isMine'] as bool,
            lines: (j['lines'] as List)
                .map((l) => l as Map<String, dynamic>)
                .map(
                  (m) => TableLine(
                    name: m['name'] as String,
                    qty: (m['qty'] as num).toInt(),
                  ),
                )
                .toList(),
          ),
        )
        .toList();
    return TableOrders(tableNumber: tableNumber, entries: entries);
  }

  @override
  Future<List<AwaitingOrder>> pending(String venueId) async {
    final response = await client.get(_uri('/venues/$venueId/orders/pending'));
    if (response.statusCode != AppConstants.httpOk) return const [];
    final list = jsonDecode(response.body) as List;
    return list
        .map((e) => e as Map<String, dynamic>)
        .map(
          (j) => AwaitingOrder(
            serverOrderId: j['serverOrderId'] as String,
            venueId: j['venueId'] as String,
            tableNumber: (j['tableNumber'] as num).toInt(),
            sequence: (j['sequence'] as num).toInt(),
            customerName: j['customerName'] as String?,
          ),
        )
        .toList();
  }

  @override
  Future<void> accept(String serverOrderId) async {
    await client.post(_uri('/orders/$serverOrderId/accept'));
  }

  @override
  Future<void> raise({
    required String venueId,
    required int tableNumber,
    required WaiterRequestKind kind,
    String? customerName,
  }) async {
    await client.post(
      _uri('/venues/$venueId/tables/$tableNumber/requests'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({'kind': kind.name, 'customerName': customerName}),
    );
  }

  @override
  Future<List<WaiterRequest>> requests(String venueId) async {
    final response = await client.get(_uri('/venues/$venueId/requests'));
    if (response.statusCode != AppConstants.httpOk) return const [];
    final list = jsonDecode(response.body) as List;
    return list
        .map((e) => e as Map<String, dynamic>)
        .map(WaiterRequest.fromJson)
        .toList();
  }

  @override
  Future<void> resolve(String requestId) async {
    await client.post(_uri('/requests/$requestId/resolve'));
  }

  @override
  Future<List<ProgressOrder>> inProgress(String venueId) async {
    final response = await client.get(
      _uri('/venues/$venueId/orders/inprogress'),
    );
    if (response.statusCode != AppConstants.httpOk) return const [];
    final list = jsonDecode(response.body) as List;
    return list
        .map((e) => e as Map<String, dynamic>)
        .map(ProgressOrder.fromJson)
        .toList();
  }

  @override
  Future<void> markReady(String serverOrderId) async {
    await client.post(_uri('/orders/$serverOrderId/ready'));
  }

  @override
  Future<void> markDelivered(String serverOrderId) async {
    await client.post(_uri('/orders/$serverOrderId/delivered'));
  }
}

OrderStage? _stageFrom(String? name) => switch (name) {
  'pendingAcceptance' => OrderStage.pendingAcceptance,
  'received' => OrderStage.received,
  'preparing' => OrderStage.preparing,
  'done' => OrderStage.done,
  _ => null,
};

import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'order_store.dart';
import 'request_store.dart';

/// The HTTP surface of the BFF. Maps REST routes to the [OrderStore] and the
/// [WaiterRequestStore]. The apps talk only to this contract (JSON), never to a
/// store directly, so the stores (in-memory now, Ebriza/persistent later) are
/// swappable without touching the clients.
class OrderApi {
  final OrderStore store;
  final WaiterRequestStore requests;

  OrderApi(this.store, this.requests);

  Handler get handler {
    final router = Router()
      ..get('/health', (Request _) => Response.ok('ok'))
      ..post('/venues/<venueId>/orders', _submit)
      ..get('/venues/<venueId>/orders/pending', _pending)
      ..get('/venues/<venueId>/tables/<tableNumber>/orders', _tableOrders)
      ..post('/venues/<venueId>/tables/<tableNumber>/requests', _raiseRequest)
      ..get('/venues/<venueId>/requests', _listRequests)
      ..post('/requests/<requestId>/resolve', _resolveRequest)
      ..post('/orders/<orderId>/accept', _accept)
      ..get('/orders/<orderId>/status', _status);

    return const Pipeline()
        .addMiddleware(_cors())
        .addMiddleware(logRequests())
        .addHandler(router.call);
  }

  Future<Response> _submit(Request request, String venueId) async {
    final body = jsonDecode(await request.readAsString());
    if (body is! Map<String, dynamic>) {
      return _json({'error': 'expected a JSON object'}, status: 400);
    }
    final placed = store.submit(venueId: venueId, order: body);
    return _json(placed.toJson());
  }

  Future<Response> _pending(Request request, String venueId) async {
    final orders = store.pending(venueId).map((o) => o.toJson()).toList();
    return _json(orders);
  }

  Future<Response> _tableOrders(
    Request request,
    String venueId,
    String tableNumber,
  ) async {
    final myClientId = request.url.queryParameters['clientId'] ?? '';
    final table = int.tryParse(tableNumber) ?? -1;
    final entries = store.forTable(venueId, table).map((o) {
      final name = (o.customerName == null || o.customerName!.trim().isEmpty)
          ? 'Client'
          : o.customerName!.trim();
      return {
        'name': name,
        'clientId': o.clientId ?? 'unknown',
        'isMine': o.clientId == myClientId,
        'lines': o.lines,
      };
    }).toList();
    return _json({'tableNumber': table, 'entries': entries});
  }

  Future<Response> _accept(Request request, String orderId) async {
    final order = store.accept(orderId);
    if (order == null) return _json({'error': 'unknown order'}, status: 404);
    return _json(order.toJson());
  }

  Future<Response> _status(Request request, String orderId) async {
    final order = store.status(orderId);
    if (order == null) return _json({'error': 'unknown order'}, status: 404);
    return _json(order.toJson());
  }

  Future<Response> _raiseRequest(
    Request request,
    String venueId,
    String tableNumber,
  ) async {
    final body = jsonDecode(await request.readAsString());
    if (body is! Map<String, dynamic>) {
      return _json({'error': 'expected a JSON object'}, status: 400);
    }
    final table = int.tryParse(tableNumber) ?? -1;
    final raised = requests.raise(
      venueId: venueId,
      tableNumber: table,
      kind: (body['kind'] as String?) ?? 'callWaiter',
      customerName: body['customerName'] as String?,
    );
    return _json(raised.toJson());
  }

  Future<Response> _listRequests(Request request, String venueId) async {
    final list = requests.list(venueId).map((r) => r.toJson()).toList();
    return _json(list);
  }

  Future<Response> _resolveRequest(Request request, String requestId) async {
    final existed = requests.resolve(requestId);
    if (!existed) return _json({'error': 'unknown request'}, status: 404);
    return _json({'resolved': requestId});
  }
}

Response _json(Object? data, {int status = 200}) => Response(
      status,
      body: jsonEncode(data),
      headers: {'content-type': 'application/json'},
    );

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

/// Allow the Flutter web app (a different origin/port) to call the BFF.
Middleware _cors() => (innerHandler) => (request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaders);
      }
      final response = await innerHandler(request);
      return response.change(headers: _corsHeaders);
    };

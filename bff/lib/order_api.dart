import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'consent_store.dart';
import 'identity_store.dart';
import 'metrics.dart';
import 'order_store.dart';
import 'redemption_store.dart';
import 'request_store.dart';

/// The HTTP surface of the BFF. Maps REST routes to the stores. The apps talk
/// only to this contract (JSON), never to a store directly, so the stores
/// (in-memory now, POS/persistent later) are swappable without touching clients.
class OrderApi {
  final OrderStore store;
  final WaiterRequestStore requests;
  final RedemptionStore redemptions;
  final IdentityStore identity;
  final ConsentStore consent;

  OrderApi(
    this.store,
    this.requests,
    this.redemptions,
    this.identity,
    this.consent,
  );

  Handler get handler {
    final router = Router()
      ..get('/health', (Request _) => Response.ok('ok'))
      ..post('/venues/<venueId>/orders', _submit)
      ..get('/venues/<venueId>/orders/pending', _pending)
      ..get('/venues/<venueId>/orders/inprogress', _inProgress)
      ..get('/venues/<venueId>/tables/<tableNumber>/orders', _tableOrders)
      ..post('/venues/<venueId>/tables/<tableNumber>/requests', _raiseRequest)
      ..get('/venues/<venueId>/requests', _listRequests)
      ..get('/venues/<venueId>/metrics', _metrics)
      ..get('/venues/<venueId>/customers/<clientId>/orders', _customerOrders)
      ..post(
        '/venues/<venueId>/customers/<clientId>/redemptions',
        _createRedemption,
      )
      ..get(
        '/venues/<venueId>/customers/<clientId>/redemptions',
        _customerRedemptions,
      )
      ..get('/venues/<venueId>/redemptions/pending', _pendingRedemptions)
      ..post('/redemptions/<code>/consume', _consumeRedemption)
      ..post('/auth/otp/start', _otpStart)
      ..post('/auth/otp/verify', _otpVerify)
      ..post(
        '/venues/<venueId>/customers/<clientId>/consent',
        _setConsent,
      )
      ..get('/venues/<venueId>/customers/<clientId>/consent', _getConsent)
      ..post('/requests/<requestId>/resolve', _resolveRequest)
      ..post('/orders/<orderId>/accept', _accept)
      ..post('/orders/<orderId>/ready', _ready)
      ..post('/orders/<orderId>/delivered', _delivered)
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

  Future<Response> _metrics(Request request, String venueId) async {
    final data = computeMetrics(
      store.forVenue(venueId),
      nowMs: DateTime.now().millisecondsSinceEpoch,
    );
    return _json(data);
  }

  /// A customer-scoped read is allowed when the key is anonymous (self-scoped by
  /// its random device id) or when a bearer token matches that customerId. This
  /// stops anyone from reading a customer's data by guessing their id.
  bool _authorized(Request request, String key) {
    if (!identity.isKnownCustomer(key)) return true;
    final header = request.headers['authorization'] ?? '';
    const scheme = 'Bearer ';
    final token = header.startsWith(scheme) ? header.substring(scheme.length) : '';
    return identity.customerForToken(token) == key;
  }

  Response _forbidden() => _json({'error': 'forbidden'}, status: 403);

  Future<Response> _customerOrders(
    Request request,
    String venueId,
    String clientId,
  ) async {
    if (!_authorized(request, clientId)) return _forbidden();
    final orders =
        store.forCustomer(venueId, clientId).map((o) => o.toJson()).toList();
    return _json(orders);
  }

  Future<Response> _createRedemption(
    Request request,
    String venueId,
    String clientId,
  ) async {
    final body = jsonDecode(await request.readAsString());
    if (body is! Map<String, dynamic>) {
      return _json({'error': 'expected a JSON object'}, status: 400);
    }
    if (!_authorized(request, clientId)) return _forbidden();
    final reward = body['reward'] as String?;
    final cost = (body['cost'] as num?)?.toInt();
    if (reward == null || cost == null) {
      return _json({'error': 'reward and cost are required'}, status: 400);
    }
    final created = redemptions.create(
      venueId: venueId,
      clientId: clientId,
      reward: reward,
      cost: cost,
    );
    return _json(created.toJson());
  }

  Future<Response> _customerRedemptions(
    Request request,
    String venueId,
    String clientId,
  ) async {
    if (!_authorized(request, clientId)) return _forbidden();
    final list = redemptions
        .forCustomer(venueId, clientId)
        .map((r) => r.toJson())
        .toList();
    return _json(list);
  }

  Future<Response> _pendingRedemptions(Request request, String venueId) async {
    final list = redemptions.pending(venueId).map((r) => r.toJson()).toList();
    return _json(list);
  }

  Future<Response> _consumeRedemption(Request request, String code) async {
    final existed = redemptions.consume(code);
    if (!existed) return _json({'error': 'unknown code'}, status: 404);
    return _json({'consumed': code});
  }

  Future<Response> _otpStart(Request request) async {
    final body = jsonDecode(await request.readAsString());
    if (body is! Map<String, dynamic> || body['phone'] is! String) {
      return _json({'error': 'phone is required'}, status: 400);
    }
    final started = identity.startChallenge(
      body['phone'] as String,
      nowMs: DateTime.now().millisecondsSinceEpoch,
    );
    // devCode is a dev shortcut (no SMS). A real SMS adapter would omit it.
    return _json({
      'challengeId': started.challengeId,
      'devCode': started.code,
    });
  }

  Future<Response> _otpVerify(Request request) async {
    final body = jsonDecode(await request.readAsString());
    if (body is! Map<String, dynamic>) {
      return _json({'error': 'expected a JSON object'}, status: 400);
    }
    final session = identity.verify(
      body['challengeId'] as String? ?? '',
      body['code'] as String? ?? '',
      nowMs: DateTime.now().millisecondsSinceEpoch,
    );
    if (session == null) {
      return _json({'error': 'invalid or expired code'}, status: 401);
    }
    // Merge: move the anonymous device's orders/redemptions to the identity.
    final clientId = body['clientId'] as String?;
    if (clientId != null && clientId.isNotEmpty) {
      store.relink(clientId, session.customerId);
      redemptions.relink(clientId, session.customerId);
    }
    return _json({
      'customerId': session.customerId,
      'phone': session.phone,
      'token': session.token,
    });
  }

  Future<Response> _setConsent(
    Request request,
    String venueId,
    String clientId,
  ) async {
    if (!_authorized(request, clientId)) return _forbidden();
    final body = jsonDecode(await request.readAsString());
    if (body is! Map<String, dynamic> || body['choices'] is! List) {
      return _json({'error': 'choices are required'}, status: 400);
    }
    final choices = (body['choices'] as List)
        .whereType<Map<String, dynamic>>()
        .toList();
    consent.setConsent(venueId, clientId, choices);
    return _json({'ok': true});
  }

  Future<Response> _getConsent(
    Request request,
    String venueId,
    String clientId,
  ) async {
    if (!_authorized(request, clientId)) return _forbidden();
    return _json(consent.forCustomer(venueId, clientId));
  }

  Future<Response> _resolveRequest(Request request, String requestId) async {
    final existed = requests.resolve(requestId);
    if (!existed) return _json({'error': 'unknown request'}, status: 404);
    return _json({'resolved': requestId});
  }

  Future<Response> _inProgress(Request request, String venueId) async {
    final orders = store.inProgress(venueId).map((o) => o.toJson()).toList();
    return _json(orders);
  }

  Future<Response> _ready(Request request, String orderId) async {
    final order = store.markReady(orderId);
    if (order == null) return _json({'error': 'unknown order'}, status: 404);
    return _json(order.toJson());
  }

  Future<Response> _delivered(Request request, String orderId) async {
    final order = store.markDelivered(orderId);
    if (order == null) return _json({'error': 'unknown order'}, status: 404);
    return _json(order.toJson());
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

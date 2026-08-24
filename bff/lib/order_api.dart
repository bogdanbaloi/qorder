import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'consent_store.dart';
import 'identity_store.dart';
import 'log_store.dart';
import 'logging.dart';
import 'metrics.dart';
import 'order_store.dart';
import 'platform_metrics.dart';
import 'redemption_store.dart';
import 'request_store.dart';
import 'sms_sender.dart';
import 'staff_auth_store.dart';
import 'venue_config_store.dart';

/// The HTTP surface of the BFF. Maps REST routes to the stores. The apps talk
/// only to this contract (JSON), never to a store directly, so the stores
/// (in-memory now, POS/persistent later) are swappable without touching clients.
class OrderApi {
  final OrderStore store;
  final WaiterRequestStore requests;
  final RedemptionStore redemptions;
  final IdentityStore identity;
  final ConsentStore consent;
  final StaffAuthStore staffAuth;

  /// Delivers the OTP. Defaults to the dev sender (logs the code); a real SMS
  /// adapter drops in here.
  final SmsSender sms;

  /// Whether `POST /auth/otp/start` echoes the code as `devCode` in the response
  /// (for the no-SMS demo). Set false in production once SMS is live.
  final bool exposeDevCode;

  /// Cross-venue operator evidence (venues + usage). Empty with no database.
  final PlatformMetricsStore platformMetrics;

  /// The bearer token that unlocks the platform (operator) routes. Null disables
  /// them, so the operator surface is off until a token is configured.
  final String? operatorToken;

  /// Per-venue configuration document (owner Settings). In-memory by default.
  final VenueConfigStore venueConfig;

  /// Structured logging. A refused auth logs its reason, so a 403 is not silent.
  final BffLog log;

  /// Durable client diagnostics (apps ship their warnings/errors here).
  final LogStore logs;

  OrderApi(
    this.store,
    this.requests,
    this.redemptions,
    this.identity,
    this.consent,
    this.staffAuth, {
    SmsSender? sms,
    this.exposeDevCode = true,
    PlatformMetricsStore? platformMetrics,
    this.operatorToken,
    VenueConfigStore? venueConfig,
    BffLog? log,
    LogStore? logs,
  })  : sms = sms ?? const DevSmsSender(),
        platformMetrics = platformMetrics ?? EmptyPlatformMetricsStore(),
        venueConfig = venueConfig ?? InMemoryVenueConfigStore(),
        log = log ?? BffLog(),
        logs = logs ?? InMemoryLogStore();

  Handler get handler {
    final router = Router()
      ..get('/health', (Request _) => Response.ok('ok'))
      ..post('/logs', _clientLogs)
      ..get('/logs', _operatorLogs)
      ..get('/platform/metrics', _platformMetrics)
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
      ..post('/venues/<venueId>/staff/auth', _staffAuth)
      ..post(
        '/venues/<venueId>/customers/<clientId>/consent',
        _setConsent,
      )
      ..get('/venues/<venueId>/customers/<clientId>/consent', _getConsent)
      ..get('/venues/<venueId>/config', _getVenueConfig)
      ..put('/venues/<venueId>/config', _putVenueConfig)
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
    final placed = await store.submit(venueId: venueId, order: body);
    return _json(placed.toJson());
  }

  Future<Response> _pending(Request request, String venueId) async {
    if (!_staffOk(request, venueId: venueId)) return _forbidden();
    final orders =
        (await store.pending(venueId)).map((o) => o.toJson()).toList();
    return _json(orders);
  }

  Future<Response> _tableOrders(
    Request request,
    String venueId,
    String tableNumber,
  ) async {
    final myClientId = request.url.queryParameters['clientId'] ?? '';
    final table = int.tryParse(tableNumber) ?? -1;
    final entries = (await store.forTable(venueId, table)).map((o) {
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
    if (!_staffOk(request)) return _forbidden();
    final order = await store.accept(orderId);
    if (order == null) return _json({'error': 'unknown order'}, status: 404);
    return _json(order.toJson());
  }

  Future<Response> _status(Request request, String orderId) async {
    final order = await store.status(orderId);
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
    if (!_staffOk(request, venueId: venueId)) return _forbidden();
    final list = requests.list(venueId).map((r) => r.toJson()).toList();
    return _json(list);
  }

  Future<Response> _metrics(Request request, String venueId) async {
    if (!_staffOk(request, venueId: venueId, ownerOnly: true)) {
      return _forbidden();
    }
    final data = computeMetrics(
      await store.forVenue(venueId),
      nowMs: DateTime.now().millisecondsSinceEpoch,
    );
    return _json(data);
  }

  /// A customer-scoped read is allowed when the key is anonymous (self-scoped by
  /// its random device id) or when a bearer token matches that customerId. This
  /// stops anyone from reading a customer's data by guessing their id.
  Future<bool> _authorized(Request request, String key) async {
    if (!await identity.isKnownCustomer(key)) return true;
    final header = request.headers['authorization'] ?? '';
    const scheme = 'Bearer ';
    final token =
        header.startsWith(scheme) ? header.substring(scheme.length) : '';
    return await identity.customerForToken(token) == key;
  }

  Response _forbidden() => _json({'error': 'forbidden'}, status: 403);

  /// The operator (platform) routes require the configured operator token. With no
  /// token configured the routes are off (403), so the surface is opt-in.
  bool _operatorOk(Request request) {
    final token = operatorToken;
    return token != null && token.isNotEmpty && _bearer(request) == token;
  }

  Future<Response> _platformMetrics(Request request) async {
    if (!_operatorOk(request)) return _forbidden();
    return _json((await platformMetrics.snapshot()).toJson());
  }

  /// Apps ship their warning/error records here. Public, so a client can report
  /// even when signed out; bounded (batch and message length) so it cannot be
  /// used to flood the store. Records persist AND echo to the live log stream.
  Future<Response> _clientLogs(Request request) async {
    const maxRecords = 50;
    const maxMessageLen = 500;
    final body = jsonDecode(await request.readAsString());
    if (body is! Map<String, dynamic>) {
      return _json({'error': 'expected a JSON object'}, status: 400);
    }
    final incoming = (body['records'] as List?) ?? const [];
    final records = <ClientLogRecord>[];
    for (final raw in incoming.take(maxRecords)) {
      if (raw is! Map) continue;
      final message = (raw['message'] as String? ?? '').trim();
      if (message.isEmpty) continue;
      final capped = message.length > maxMessageLen
          ? message.substring(0, maxMessageLen)
          : message;
      final level = raw['level'] as String? ?? 'warning';
      final venueId = raw['venueId'] as String?;
      records.add(
        ClientLogRecord(level: level, message: capped, venueId: venueId),
      );
      log.warning(
          '[client:$level${venueId == null ? '' : ':$venueId'}] $capped');
    }
    await logs.add(records);
    return _json({'stored': records.length});
  }

  /// The operator reads the most recent client diagnostics (cross-venue).
  Future<Response> _operatorLogs(Request request) async {
    if (!_operatorOk(request)) return _forbidden();
    const defaultLimit = 100;
    final limit = int.tryParse(request.url.queryParameters['limit'] ?? '') ??
        defaultLimit;
    final recent = await logs.recent(limit: limit);
    return _json([for (final record in recent) record.toJson()]);
  }

  String _bearer(Request request) {
    final header = request.headers['authorization'] ?? '';
    const scheme = 'Bearer ';
    return header.startsWith(scheme) ? header.substring(scheme.length) : '';
  }

  /// A staff/owner route is allowed when the bearer token carries staff claims
  /// for [venueId] (per-tenant). [ownerOnly] requires the owner role; otherwise
  /// staff or owner passes. When [venueId] is null (id-based mutation) only a
  /// valid staff/owner token is required.
  bool _staffOk(Request request, {String? venueId, bool ownerOnly = false}) {
    final claims = staffAuth.claims(_bearer(request));
    if (claims == null) {
      log.warning('auth refused: no valid token (venue=${venueId ?? "-"})');
      return false;
    }
    if (venueId != null && claims.venueId != venueId) {
      log.warning('auth refused: token venue ${claims.venueId} != $venueId');
      return false;
    }
    if (ownerOnly && claims.role != 'owner') {
      log.warning('auth refused: role ${claims.role} is not owner');
      return false;
    }
    return true;
  }

  Future<Response> _staffAuth(Request request, String venueId) async {
    final body = jsonDecode(await request.readAsString());
    if (body is! Map<String, dynamic>) {
      return _json({'error': 'expected a JSON object'}, status: 400);
    }
    final role = body['role'] as String? ?? 'staff';
    final code = body['code'] as String? ?? '';
    final token = staffAuth.authenticate(venueId, role, code);
    if (token == null) return _json({'error': 'wrong code'}, status: 401);
    return _json({'token': token, 'role': role});
  }

  Future<Response> _customerOrders(
    Request request,
    String venueId,
    String clientId,
  ) async {
    if (!await _authorized(request, clientId)) return _forbidden();
    final orders = (await store.forCustomer(
      venueId,
      clientId,
    ))
        .map((o) => o.toJson())
        .toList();
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
    if (!await _authorized(request, clientId)) return _forbidden();
    final reward = body['reward'] as String?;
    final cost = (body['cost'] as num?)?.toInt();
    if (reward == null || cost == null) {
      return _json({'error': 'reward and cost are required'}, status: 400);
    }
    final created = await redemptions.create(
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
    if (!await _authorized(request, clientId)) return _forbidden();
    final list = (await redemptions.forCustomer(venueId, clientId))
        .map((r) => r.toJson())
        .toList();
    return _json(list);
  }

  Future<Response> _pendingRedemptions(Request request, String venueId) async {
    if (!_staffOk(request, venueId: venueId)) return _forbidden();
    final list =
        (await redemptions.pending(venueId)).map((r) => r.toJson()).toList();
    return _json(list);
  }

  Future<Response> _consumeRedemption(Request request, String code) async {
    if (!_staffOk(request)) return _forbidden();
    final existed = await redemptions.consume(code);
    if (!existed) return _json({'error': 'unknown code'}, status: 404);
    return _json({'consumed': code});
  }

  Future<Response> _otpStart(Request request) async {
    final body = jsonDecode(await request.readAsString());
    if (body is! Map<String, dynamic> || body['phone'] is! String) {
      return _json({'error': 'phone is required'}, status: 400);
    }
    final phone = body['phone'] as String;
    final started = await identity.startChallenge(
      phone,
      nowMs: DateTime.now().millisecondsSinceEpoch,
    );
    if (started == null) {
      return _json({'error': 'too many requests'}, status: 429);
    }
    sms.send(phone, started.code);
    return _json({
      'challengeId': started.challengeId,
      // Dev shortcut (no SMS): echo the code. Off in production.
      if (exposeDevCode) 'devCode': started.code,
    });
  }

  Future<Response> _otpVerify(Request request) async {
    final body = jsonDecode(await request.readAsString());
    if (body is! Map<String, dynamic>) {
      return _json({'error': 'expected a JSON object'}, status: 400);
    }
    final session = await identity.verify(
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
      await store.relink(clientId, session.customerId);
      await redemptions.relink(clientId, session.customerId);
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
    if (!await _authorized(request, clientId)) return _forbidden();
    final body = jsonDecode(await request.readAsString());
    if (body is! Map<String, dynamic> || body['choices'] is! List) {
      return _json({'error': 'choices are required'}, status: 400);
    }
    final choices =
        (body['choices'] as List).whereType<Map<String, dynamic>>().toList();
    await consent.setConsent(venueId, clientId, choices);
    return _json({'ok': true});
  }

  Future<Response> _getConsent(
    Request request,
    String venueId,
    String clientId,
  ) async {
    if (!await _authorized(request, clientId)) return _forbidden();
    return _json(await consent.forCustomer(venueId, clientId));
  }

  /// Reads the venue's saved config document. Open (the customer app will read it
  /// to render the venue), returning 404 when nothing has been saved yet so the
  /// client falls back to its bundled asset.
  Future<Response> _getVenueConfig(Request request, String venueId) async {
    final doc = await venueConfig.get(venueId);
    if (doc == null) return _json({'error': 'no config'}, status: 404);
    return _json(doc);
  }

  /// Writes the venue's config document. Owner-only, since it changes what every
  /// customer sees. The document is stored opaque, so the client owns its shape.
  Future<Response> _putVenueConfig(Request request, String venueId) async {
    if (!_staffOk(request, venueId: venueId, ownerOnly: true)) {
      return _forbidden();
    }
    final body = jsonDecode(await request.readAsString());
    if (body is! Map<String, dynamic>) {
      return _json({'error': 'expected a JSON object'}, status: 400);
    }
    await venueConfig.put(venueId, body);
    return _json(body);
  }

  Future<Response> _resolveRequest(Request request, String requestId) async {
    if (!_staffOk(request)) return _forbidden();
    final existed = requests.resolve(requestId);
    if (!existed) return _json({'error': 'unknown request'}, status: 404);
    return _json({'resolved': requestId});
  }

  Future<Response> _inProgress(Request request, String venueId) async {
    if (!_staffOk(request, venueId: venueId)) return _forbidden();
    final orders =
        (await store.inProgress(venueId)).map((o) => o.toJson()).toList();
    return _json(orders);
  }

  Future<Response> _ready(Request request, String orderId) async {
    if (!_staffOk(request)) return _forbidden();
    final order = await store.markReady(orderId);
    if (order == null) return _json({'error': 'unknown order'}, status: 404);
    return _json(order.toJson());
  }

  Future<Response> _delivered(Request request, String orderId) async {
    if (!_staffOk(request)) return _forbidden();
    final order = await store.markDelivered(orderId);
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
  'Access-Control-Allow-Methods': 'GET, POST, PUT, OPTIONS',
  // Authorization is required: authenticated requests (consent, history,
  // redemptions, staff/owner actions) carry a Bearer token, and without it here
  // the browser's CORS preflight blocks them before they reach the server.
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

/// Allow the Flutter web app (a different origin/port) to call the BFF.
Middleware _cors() => (innerHandler) => (request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaders);
      }
      final response = await innerHandler(request);
      return response.change(headers: _corsHeaders);
    };

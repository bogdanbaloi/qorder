import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'consent_store.dart';
import 'identity_store.dart';
import 'log_store.dart';
import 'logging.dart';
import 'metrics.dart';
import 'rate_limiter.dart';
import 'order_store.dart';
import 'platform_metrics.dart';
import 'redemption_store.dart';
import 'request_store.dart';
import 'sms_sender.dart';
import 'staff_auth_store.dart';
import 'venue_config_store.dart';

/// The default per-IP budget for the public log endpoint.
const int _logRateMaxPerWindow = 60;
const Duration _logRateWindow = Duration(minutes: 1);

/// The default per-IP budget for staff/owner sign-in. Tight, since the access
/// code is short and this is the brute-force surface (REQ-SEC-002). A real staff
/// member signs in rarely, so this leaves ample headroom while it slows an
/// attacker to a crawl.
const int _authRateMaxPerWindow = 10;
const Duration _authRateWindow = Duration(minutes: 1);

/// The default per-IP budget for the public write routes (order submit, waiter
/// request), so they cannot be spammed (REQ-SEC-006). Loose, since a busy venue's
/// patrons share one NAT IP, while it still bounds a single abuser.
const int _writeRateMaxPerWindow = 60;
const Duration _writeRateWindow = Duration(minutes: 1);

/// The largest request body accepted on any route, so a huge payload cannot
/// exhaust memory (REQ-SEC-005). Generous for our small JSON (orders, config, a
/// bounded log batch), all a few KB.
const int _maxBodyBytes = 64 * 1024;

/// Keys redacted from the public venue-config response. They are auth secrets,
/// not customer-facing config, so the open GET must never return them (ADR-0067).
/// The codes the backend actually checks live in the staff auth store, not here.
const _secretConfigKeys = {'staffAccessCode', 'ownerAccessCode'};

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
  /// (for the no-SMS demo). Off by default, so a deployment is safe unless it
  /// opts in. The demo turns it on through `QORDER_EXPOSE_DEV_CODE` (REQ-SEC-001).
  final bool exposeDevCode;

  /// The CORS allowed origin. `*` by default (dev and the demo); a production
  /// deploy locks it to the app's origin via `QORDER_ALLOWED_ORIGIN` (REQ-SEC-009).
  final String allowedOrigin;

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

  /// Per-IP rate limit for the public `POST /logs`, so it cannot be flooded.
  final RateLimiter clientLogLimiter;

  /// Per-IP rate limit for staff/owner sign-in, so the short access code cannot
  /// be brute-forced.
  final RateLimiter staffAuthLimiter;

  /// Per-IP rate limit for the public write routes (order submit, waiter request),
  /// so they cannot be spammed.
  final RateLimiter publicWriteLimiter;

  OrderApi(
    this.store,
    this.requests,
    this.redemptions,
    this.identity,
    this.consent,
    this.staffAuth, {
    SmsSender? sms,
    this.exposeDevCode = false,
    this.allowedOrigin = '*',
    PlatformMetricsStore? platformMetrics,
    this.operatorToken,
    VenueConfigStore? venueConfig,
    BffLog? log,
    LogStore? logs,
    RateLimiter? clientLogLimiter,
    RateLimiter? staffAuthLimiter,
    RateLimiter? publicWriteLimiter,
  })  : sms = sms ?? const DevSmsSender(),
        platformMetrics = platformMetrics ?? EmptyPlatformMetricsStore(),
        venueConfig = venueConfig ?? InMemoryVenueConfigStore(),
        log = log ?? BffLog(),
        logs = logs ?? InMemoryLogStore(),
        clientLogLimiter = clientLogLimiter ??
            RateLimiter(
              maxPerWindow: _logRateMaxPerWindow,
              window: _logRateWindow,
            ),
        staffAuthLimiter = staffAuthLimiter ??
            RateLimiter(
              maxPerWindow: _authRateMaxPerWindow,
              window: _authRateWindow,
            ),
        publicWriteLimiter = publicWriteLimiter ??
            RateLimiter(
              maxPerWindow: _writeRateMaxPerWindow,
              window: _writeRateWindow,
            );

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
        .addMiddleware(_cors(allowedOrigin))
        .addMiddleware(_catchErrors(log))
        .addMiddleware(logRequests())
        .addMiddleware(_bodyLimit())
        .addHandler(router.call);
  }

  Future<Response> _submit(Request request, String venueId) async {
    // Public route: bound submits per caller IP, so orders cannot be spammed
    // (REQ-SEC-006).
    if (!publicWriteLimiter.allow(_clientIp(request), DateTime.now())) {
      return _json({'error': 'too many requests'}, status: 429);
    }
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
    final orders = await store.forTable(venueId, table);
    // You may see a table only if you are on it: your device must have an order
    // here. This keeps the shared-table view for its patrons but stops an outsider
    // from enumerating tables to scrape names and orders (REQ-SEC-004). The
    // clientId is self-asserted, but a real one for the table is not guessable.
    final onTable =
        myClientId.isNotEmpty && orders.any((o) => o.clientId == myClientId);
    if (!onTable) {
      return _json({'tableNumber': table, 'entries': const []});
    }
    final entries = orders.map((o) {
      final name = (o.customerName == null || o.customerName!.trim().isEmpty)
          ? 'Client'
          : o.customerName!.trim();
      // `isMine` is computed here, so the raw clientId of each patron is not
      // exposed to the others at the table (REQ-SEC-013).
      return {
        'name': name,
        'isMine': o.clientId == myClientId,
        'lines': o.lines,
      };
    }).toList();
    return _json({'tableNumber': table, 'entries': entries});
  }

  Future<Response> _accept(Request request, String orderId) async {
    if (!_staffOk(request)) return _forbidden();
    final order = await store.accept(_claimsVenue(request), orderId);
    if (order == null) return _json({'error': 'unknown order'}, status: 404);
    return _json(order.toJson());
  }

  Future<Response> _status(Request request, String orderId) async {
    final order = await store.status(orderId);
    if (order == null) return _json({'error': 'unknown order'}, status: 404);
    // The status poll is public, so it returns a projection: the stage and the
    // timings the customer needs, not the customer name, id or line items. So a
    // status read leaks no order PII, even to whoever holds the id (REQ-SEC-012).
    return _json({
      'serverOrderId': order.serverOrderId,
      'sequence': order.sequence,
      'stage': order.stage.name,
      'stamps': order.stamps,
    });
  }

  Future<Response> _raiseRequest(
    Request request,
    String venueId,
    String tableNumber,
  ) async {
    // Public route: bound waiter requests per caller IP (REQ-SEC-006).
    if (!publicWriteLimiter.allow(_clientIp(request), DateTime.now())) {
      return _json({'error': 'too many requests'}, status: 429);
    }
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
    // Constant-time compare, so the high-value operator token is not leaked
    // through response timing (REQ-SEC-010).
    return token != null &&
        token.isNotEmpty &&
        _constantTimeEquals(_bearer(request), token);
  }

  Future<Response> _platformMetrics(Request request) async {
    if (!_operatorOk(request)) return _forbidden();
    return _json((await platformMetrics.snapshot()).toJson());
  }

  /// Apps ship their warning/error records here. Public, so a client can report
  /// even when signed out. Bounded (batch and message length) and rate limited,
  /// so it cannot flood the store. Records persist AND echo to the live stream.
  Future<Response> _clientLogs(Request request) async {
    const maxRecords = 50;
    const maxMessageLen = 500;
    if (!clientLogLimiter.allow(_clientIp(request), DateTime.now())) {
      return _json({'error': 'too many requests'}, status: 429);
    }
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

  /// The venue the request's staff token is scoped to, so an order mutation runs
  /// under that venue (RLS refuses another venue's order). Empty when unscoped,
  /// which only follows a passed `_staffOk`, so a real token is present.
  String _claimsVenue(Request request) =>
      staffAuth.claims(_bearer(request))?.venueId ?? '';

  /// The caller IP for rate limiting: the proxy's `x-forwarded-for` when present
  /// (behind a load balancer), else the direct connection address.
  String _clientIp(Request request) {
    final forwarded = request.headers['x-forwarded-for'];
    if (forwarded != null && forwarded.isNotEmpty) {
      return forwarded.split(',').first.trim();
    }
    final info = request.context['shelf.io.connection_info'];
    if (info is HttpConnectionInfo) return info.remoteAddress.address;
    return 'unknown';
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
    // Brute-force guard: the access code is short, so bound sign-in attempts per
    // caller IP (REQ-SEC-002). A refused attempt is logged, so a burst is visible.
    if (!staffAuthLimiter.allow(_clientIp(request), DateTime.now())) {
      log.warning('staff auth rate limited (venue=$venueId)');
      return _json({'error': 'too many requests'}, status: 429);
    }
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
  /// The venue's public config, read by the customer app (branding, menu, table
  /// policy, loyalty). Open by design, so it must not leak secrets: the staff and
  /// owner access codes are redacted from the response, even if the stored
  /// document still carries them (ADR-0067). A copy is redacted, so the stored
  /// document is untouched.
  Future<Response> _getVenueConfig(Request request, String venueId) async {
    final doc = await venueConfig.get(venueId);
    if (doc == null) return _json({'error': 'no config'}, status: 404);
    final public = Map<String, dynamic>.of(doc)
      ..removeWhere((key, _) => _secretConfigKeys.contains(key));
    return _json(public);
  }

  /// Writes the venue's config document. The venue owner (their own venue) or the
  /// platform operator (a superadmin over every venue, e.g. to set the palette
  /// from the Admin screen) may write it, since it changes what every customer
  /// sees. The document is stored opaque, so the client owns its shape.
  Future<Response> _putVenueConfig(Request request, String venueId) async {
    final ownerWrite = _staffOk(request, venueId: venueId, ownerOnly: true);
    if (!ownerWrite && !_operatorOk(request)) {
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
    final order = await store.markReady(_claimsVenue(request), orderId);
    if (order == null) return _json({'error': 'unknown order'}, status: 404);
    return _json(order.toJson());
  }

  Future<Response> _delivered(Request request, String orderId) async {
    if (!_staffOk(request)) return _forbidden();
    final order = await store.markDelivered(_claimsVenue(request), orderId);
    if (order == null) return _json({'error': 'unknown order'}, status: 404);
    return _json(order.toJson());
  }
}

Response _json(Object? data, {int status = 200}) => Response(
      status,
      body: jsonEncode(data),
      headers: {'content-type': 'application/json'},
    );

/// A content-constant-time string compare, so verifying the operator token does
/// not leak it through response timing. The length check is not secret (the token
/// length is fixed), the content comparison runs in constant time.
bool _constantTimeEquals(String a, String b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return diff == 0;
}

const _staticCorsHeaders = {
  'Access-Control-Allow-Methods': 'GET, POST, PUT, OPTIONS',
  // Authorization is required: authenticated requests (consent, history,
  // redemptions, staff/owner actions) carry a Bearer token, and without it here
  // the browser's CORS preflight blocks them before they reach the server.
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

/// Allow the Flutter web app (a different origin/port) to call the BFF. The
/// allowed origin is configurable: `*` for dev and the demo, a locked origin in
/// production (REQ-SEC-009).
Middleware _cors(String allowedOrigin) {
  final headers = {
    'Access-Control-Allow-Origin': allowedOrigin,
    ..._staticCorsHeaders,
  };
  return (innerHandler) => (request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: headers);
        }
        final response = await innerHandler(request);
        return response.change(headers: headers);
      };
}

/// Catches any uncaught error from a handler (e.g. a malformed JSON body), logs
/// it server-side without echoing the request body, and returns a generic 500, so
/// an exception never leaks internals or a stack trace to the client (REQ-SEC-011).
Middleware _catchErrors(BffLog log) => (innerHandler) => (request) async {
      try {
        return await innerHandler(request);
      } catch (error) {
        log.error(
          'unhandled ${error.runtimeType} on '
          '${request.method} ${request.requestedUri.path}',
        );
        return _json({'error': 'internal error'}, status: 500);
      }
    };

/// Rejects a request whose declared body exceeds [_maxBodyBytes] with 413, so a
/// huge payload cannot exhaust memory (REQ-SEC-005). A chunked request with no
/// declared length is not bounded here, a later hardening.
Middleware _bodyLimit() => (innerHandler) => (request) {
      final length = request.contentLength;
      if (length != null && length > _maxBodyBytes) {
        return _json({'error': 'payload too large'}, status: 413);
      }
      return innerHandler(request);
    };

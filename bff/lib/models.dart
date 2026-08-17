/// Processing stages, mirrored from the app so the JSON contract matches.
enum OrderStage { pendingAcceptance, received, preparing, done }

/// An order as the BFF holds it. Line snapshots are kept opaque (the client
/// owns their shape), the BFF only needs the routing fields.
class BffOrder {
  final String serverOrderId;
  final String venueId;
  final int tableNumber;
  final int sequence;
  final String? customerName;
  final String? clientId;
  final String? idempotencyKey;
  final List<dynamic> lines;
  final int totalMinor; // order total in bani, for owner revenue metrics
  OrderStage stage;

  /// Operational timestamps (epoch millis) keyed by event: 'submitted',
  /// 'accepted', 'ready', 'delivered'. The client derives the durations.
  final Map<String, int> stamps;

  BffOrder({
    required this.serverOrderId,
    required this.venueId,
    required this.tableNumber,
    required this.sequence,
    required this.stage,
    required this.lines,
    this.customerName,
    this.clientId,
    this.idempotencyKey,
    this.totalMinor = 0,
    Map<String, int>? stamps,
  }) : stamps = stamps ?? {};

  Map<String, dynamic> toJson() => {
        'serverOrderId': serverOrderId,
        'venueId': venueId,
        'tableNumber': tableNumber,
        'sequence': sequence,
        'stage': stage.name,
        'customerName': customerName,
        'clientId': clientId,
        'lines': lines,
        'totalMinor': totalMinor,
        'stamps': stamps,
      };
}

/// A loyalty reward the customer chose to spend points on. Holds a short [code]
/// the customer shows the staff, who then validate it (set [consumed]). The
/// [cost] is the points spent, so the client can keep the points economy honest.
class BffRedemption {
  final String id;
  final String venueId;
  final String clientId;
  final String reward;
  final int cost;
  final String code;
  final int createdAtMs;
  bool consumed;

  BffRedemption({
    required this.id,
    required this.venueId,
    required this.clientId,
    required this.reward,
    required this.cost,
    required this.code,
    required this.createdAtMs,
    this.consumed = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'venueId': venueId,
        'clientId': clientId,
        'reward': reward,
        'cost': cost,
        'code': code,
        'consumed': consumed,
        'createdAtMs': createdAtMs,
      };
}

/// A table-to-waiter request (call waiter / bill). Independent of orders and of
/// the POS. `kind` is kept as an opaque string, the client owns its meaning.
class BffWaiterRequest {
  final String id;
  final String venueId;
  final int tableNumber;
  final String kind;
  final String? customerName;
  final int createdAtMs;

  BffWaiterRequest({
    required this.id,
    required this.venueId,
    required this.tableNumber,
    required this.kind,
    required this.createdAtMs,
    this.customerName,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'venueId': venueId,
        'tableNumber': tableNumber,
        'kind': kind,
        'customerName': customerName,
        'createdAtMs': createdAtMs,
      };
}

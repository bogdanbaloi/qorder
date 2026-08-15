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
  OrderStage stage;

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
  });

  Map<String, dynamic> toJson() => {
        'serverOrderId': serverOrderId,
        'venueId': venueId,
        'tableNumber': tableNumber,
        'sequence': sequence,
        'stage': stage.name,
        'customerName': customerName,
        'clientId': clientId,
        'lines': lines,
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

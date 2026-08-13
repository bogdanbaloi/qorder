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
    this.idempotencyKey,
  });

  Map<String, dynamic> toJson() => {
        'serverOrderId': serverOrderId,
        'venueId': venueId,
        'tableNumber': tableNumber,
        'sequence': sequence,
        'stage': stage.name,
        'customerName': customerName,
        'lines': lines,
      };
}

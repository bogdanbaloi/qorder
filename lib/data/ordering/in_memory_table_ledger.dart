import '../../domain/models/table_orders.dart';

/// One recorded order on a table (in-memory demo data for Phase 0).
class _Recorded {
  final int table;
  final String name;
  final String clientId;
  final List<TableLine> lines;
  const _Recorded(this.table, this.name, this.clientId, this.lines);
}

/// In-memory record of what has been ordered per table. The mock ordering
/// service delegates the shared "table view" here (Single Responsibility), so
/// the service itself only does submit + status. Phase 1 replaces this with
/// Ebriza's table bill, behind the same `OrderingService.tableOrders` seam.
class InMemoryTableLedger {
  final List<_Recorded> _recorded = [];

  /// Pretend other customers already ordered at a couple of tables (demo).
  InMemoryTableLedger({bool seedDemo = true}) {
    if (seedDemo) _recorded.addAll(_demoSeed);
  }

  void record({
    required int table,
    required String name,
    required String clientId,
    required List<TableLine> lines,
  }) => _recorded.add(_Recorded(table, name, clientId, lines));

  TableOrders ordersFor(int tableNumber, {required String myClientId}) {
    final entries = _recorded
        .where((r) => r.table == tableNumber)
        .map(
          (r) => TableEntry(
            name: r.name,
            clientId: r.clientId,
            lines: r.lines,
            isMine: r.clientId == myClientId,
          ),
        )
        .toList();
    return TableOrders(tableNumber: tableNumber, entries: entries);
  }

  static const _demoSeed = <_Recorded>[
    _Recorded(7, 'Maria', 'seed-maria', [
      TableLine(name: 'Cappuccino 160ml', qty: 1),
    ]),
    _Recorded(12, 'Ana', 'seed-ana', [
      TableLine(name: 'Pilsner Urquell 0.5L', qty: 2),
    ]),
    _Recorded(12, 'Radu', 'seed-radu', [
      TableLine(name: 'Nachos 160g + sos 40g', qty: 1),
    ]),
  ];
}

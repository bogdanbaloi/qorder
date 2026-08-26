import 'package:flutter/foundation.dart';

/// A single line in the table view (name + quantity), summarized for display.
@immutable
class TableLine {
  final String name;
  final int qty;
  const TableLine({required this.name, required this.qty});
}

/// One person's contribution to a shared table. `isMine` is decided by the
/// backend (from the caller's clientId), so no patron's raw clientId is carried
/// here (REQ-SEC-013).
@immutable
class TableEntry {
  final String name;
  final List<TableLine> lines;
  final bool isMine;
  const TableEntry({
    required this.name,
    required this.lines,
    required this.isMine,
  });
}

/// Everything currently ordered on a table (multiple phones, one table). The
/// source of truth is the table's bill in the backend (Ebriza in Phase 1).
@immutable
class TableOrders {
  final int tableNumber;
  final List<TableEntry> entries;
  const TableOrders({required this.tableNumber, required this.entries});

  bool get isEmpty => entries.isEmpty;
}

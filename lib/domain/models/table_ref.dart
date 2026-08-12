import 'package:flutter/foundation.dart';

/// Where the table number came from. The QR happy path needs no typing, but
/// manual entry is the guaranteed fallback (a deferred install can lose the
/// URL parameter).
enum TableSource { qr, manual }

@immutable
class TableRef {
  final int number;
  final TableSource source;
  final bool validated;

  const TableRef({
    required this.number,
    required this.source,
    this.validated = false,
  });

  TableRef copyWith({int? number, TableSource? source, bool? validated}) =>
      TableRef(
        number: number ?? this.number,
        source: source ?? this.source,
        validated: validated ?? this.validated,
      );

  @override
  bool operator ==(Object other) =>
      other is TableRef &&
      other.number == number &&
      other.source == source &&
      other.validated == validated;

  @override
  int get hashCode => Object.hash(number, source, validated);
}

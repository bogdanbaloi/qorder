import 'package:flutter/foundation.dart';

import '../../core/money.dart';
import 'menu.dart';

/// A cart line SNAPSHOTS the name and unit price at add-time, so a later menu
/// edit cannot change what was ordered or its price (correctness).
@immutable
class CartLine {
  final String id; // unique per line
  final String itemId;
  final String nameSnapshot;
  final Money unitPriceSnapshot;
  final int qty;
  final List<OptionChoice> selectedOptions;

  const CartLine({
    required this.id,
    required this.itemId,
    required this.nameSnapshot,
    required this.unitPriceSnapshot,
    required this.qty,
    this.selectedOptions = const [],
  });

  Money get unitWithOptions {
    var unit = unitPriceSnapshot;
    for (final o in selectedOptions) {
      unit = unit + o.priceDelta;
    }
    return unit;
  }

  Money get lineTotal => unitWithOptions * qty;

  CartLine copyWith({int? qty}) => CartLine(
    id: id,
    itemId: itemId,
    nameSnapshot: nameSnapshot,
    unitPriceSnapshot: unitPriceSnapshot,
    qty: qty ?? this.qty,
    selectedOptions: selectedOptions,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'itemId': itemId,
    'nameSnapshot': nameSnapshot,
    'unitPriceMinor': unitPriceSnapshot.amountMinor,
    'currency': unitPriceSnapshot.currency,
    'qty': qty,
    'options': selectedOptions
        .map(
          (o) => {
            'id': o.id,
            'name': o.name,
            'deltaMinor': o.priceDelta.amountMinor,
          },
        )
        .toList(),
  };

  factory CartLine.fromJson(Map<String, dynamic> j) => CartLine(
    id: j['id'] as String,
    itemId: j['itemId'] as String,
    nameSnapshot: j['nameSnapshot'] as String,
    unitPriceSnapshot: Money(
      (j['unitPriceMinor'] as num).toInt(),
      currency: j['currency'] as String? ?? 'RON',
    ),
    qty: (j['qty'] as num).toInt(),
    selectedOptions: (((j['options'] as List?) ?? const []))
        .map(
          (e) => OptionChoice(
            id: e['id'] as String,
            name: e['name'] as String,
            priceDelta: Money((e['deltaMinor'] as num).toInt()),
          ),
        )
        .toList(),
  );
}

@immutable
class Cart {
  final String venueId;
  final List<CartLine> lines;

  const Cart({required this.venueId, this.lines = const []});

  Money get subtotal {
    var sum = const Money(0);
    for (final l in lines) {
      sum = sum + l.lineTotal;
    }
    return sum;
  }

  int get itemCount => lines.fold(0, (a, l) => a + l.qty);
  bool get isEmpty => lines.isEmpty;

  Cart copyWith({List<CartLine>? lines}) =>
      Cart(venueId: venueId, lines: lines ?? this.lines);
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/models/cart.dart';
import '../../domain/models/menu.dart';

/// Presentation logic for the cart. No widgets here; this is testable in pure
/// Dart via a ProviderContainer.
class CartController extends Notifier<Cart> {
  @override
  Cart build() {
    final cfg = ref.watch(appConfigProvider);
    return Cart(venueId: cfg.venueId);
  }

  void addItem(
    MenuItem item, {
    List<OptionChoice> options = const [],
    int qty = 1,
  }) {
    final line = CartLine(
      id: '${item.id}-${DateTime.now().microsecondsSinceEpoch}',
      itemId: item.id,
      nameSnapshot: item.name,
      unitPriceSnapshot: item.basePrice,
      qty: qty,
      selectedOptions: options,
    );
    state = state.copyWith(lines: [...state.lines, line]);
  }

  void changeQty(String lineId, int qty) {
    if (qty <= 0) {
      state = state.copyWith(
        lines: state.lines.where((l) => l.id != lineId).toList(),
      );
      return;
    }
    state = state.copyWith(
      lines: [
        for (final l in state.lines)
          if (l.id == lineId) l.copyWith(qty: qty) else l,
      ],
    );
  }

  void clear() => state = Cart(venueId: state.venueId);
}

final cartProvider = NotifierProvider<CartController, Cart>(CartController.new);

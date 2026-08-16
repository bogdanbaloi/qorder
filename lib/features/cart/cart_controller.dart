import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/models/cart.dart';
import '../../domain/models/menu.dart';
import '../../domain/pricing/menu_pricing.dart';
import '../../domain/pricing/promotion.dart';
import '../menu/menu_view_model.dart';

/// Presentation logic for the cart. No widgets here. This is testable in pure
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
    // Snapshot the price AFTER any active promotion (happy hour), so the cart
    // total matches what the menu showed. The pricing rule lives in the domain.
    final promotions =
        ref.read(menuProvider).value?.promotions ?? const <Promotion>[];
    final unitPrice = priceItem(item, promotions, DateTime.now()).effective;
    final line = CartLine(
      id: '${item.id}-${DateTime.now().microsecondsSinceEpoch}',
      itemId: item.id,
      nameSnapshot: item.name,
      unitPriceSnapshot: unitPrice,
      qty: qty,
      selectedOptions: options,
    );
    state = state.copyWith(lines: [...state.lines, line]);
  }

  /// Adds an item straight from a menu tap, auto-selecting its required options
  /// (Phase 0 has no options sheet). The default-option rule lives on the domain
  /// model, so the widget stays dumb (Single Responsibility).
  void addMenuItem(MenuItem item) =>
      addItem(item, options: item.defaultSelectedOptions());

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

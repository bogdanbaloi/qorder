import 'package:flutter/foundation.dart';

import '../../core/money.dart';
import '../models/menu.dart';
import 'promotion.dart';

/// The price of an item after promotions: the [base], the [effective] price and
/// the [promotion] that won (null when none applies).
@immutable
class PricedItem {
  final Money base;
  final Money effective;
  final Promotion? promotion;

  const PricedItem({
    required this.base,
    required this.effective,
    this.promotion,
  });

  bool get discounted =>
      promotion != null && effective.amountMinor < base.amountMinor;
}

/// Prices [item] at [now] against [promotions], picking the one that gives the
/// lowest price (best for the customer). Pure, so pricing is unit-tested with
/// explicit times. The View and the cart both call this, so the menu and the
/// total never disagree.
PricedItem priceItem(MenuItem item, List<Promotion> promotions, DateTime now) {
  final base = item.basePrice;
  Promotion? best;
  var bestPrice = base;
  for (final p in promotions) {
    if (!p.isActiveAt(now)) continue;
    if (!p.covers(categoryId: item.categoryId, tags: item.tags)) continue;
    final candidate = p.discount.apply(base);
    if (candidate.amountMinor < bestPrice.amountMinor) {
      bestPrice = candidate;
      best = p;
    }
  }
  return PricedItem(base: base, effective: bestPrice, promotion: best);
}

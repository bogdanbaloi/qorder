import '../../core/money.dart';

const int _percentScale = 100;

/// How a promotion reduces a base price. Pure value objects, so pricing is
/// unit-tested independently of the UI. Extend with a new subtype, no edits to
/// callers (Open/Closed).
sealed class Discount {
  const Discount();

  /// The price after the discount, never below zero, same currency as [base].
  Money apply(Money base);

  factory Discount.fromJson(Map<String, dynamic> j) {
    final type = j['type'] as String;
    return switch (type) {
      'percentage' => PercentageDiscount((j['percent'] as num).toInt()),
      'fixed' => FixedAmountDiscount(Money((j['offMinor'] as num).toInt())),
      _ => throw ArgumentError('Unknown discount type: $type'),
    };
  }
}

/// A percentage off, e.g. 20% off. Rounded to the nearest bani.
class PercentageDiscount extends Discount {
  final int percent; // 0..100
  const PercentageDiscount(this.percent);

  @override
  Money apply(Money base) => Money(
    ((base.amountMinor * (_percentScale - percent)) / _percentScale).round(),
    currency: base.currency,
  );
}

/// A fixed amount off, clamped so the price never goes negative.
class FixedAmountDiscount extends Discount {
  final Money off;
  const FixedAmountDiscount(this.off);

  @override
  Money apply(Money base) {
    final reduced = base.amountMinor - off.amountMinor;
    return Money(reduced < 0 ? 0 : reduced, currency: base.currency);
  }
}

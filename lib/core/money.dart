import 'package:flutter/foundation.dart';

import 'app_constants.dart';

/// Money stored as integer minor units (bani for RON).
///
/// We never use floating point for money: a bill must add up to the bani.
/// This mirrors the "no float for currency" rule from the HMI platform.
@immutable
class Money {
  final int amountMinor; // e.g. 15.90 lei -> 1590
  final String currency;

  const Money(this.amountMinor, {this.currency = AppConstants.currency});

  /// Parse from a major-unit value like 15.9 -> 1590 bani.
  factory Money.fromMajor(
    num major, {
    String currency = AppConstants.currency,
  }) => Money((major * 100).round(), currency: currency);

  double get major => amountMinor / 100.0;

  Money operator +(Money other) {
    _assertSameCurrency(other);
    return Money(amountMinor + other.amountMinor, currency: currency);
  }

  Money operator *(int qty) => Money(amountMinor * qty, currency: currency);

  void _assertSameCurrency(Money other) {
    if (other.currency != currency) {
      throw ArgumentError('Currency mismatch: $currency vs ${other.currency}');
    }
  }

  String format() {
    final symbol = currency == AppConstants.currency ? 'lei' : currency;
    final sign = amountMinor < 0 ? '-' : '';
    final abs = amountMinor.abs();
    final whole = abs ~/ 100;
    final frac = abs % 100;
    return '$sign$whole.${frac.toString().padLeft(2, '0')} $symbol';
  }

  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.amountMinor == amountMinor &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(amountMinor, currency);

  @override
  String toString() => format();
}

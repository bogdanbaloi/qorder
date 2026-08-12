import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/core/money.dart';

// REQ-MONEY-001: money is exact (minor units), never floating point.
void main() {
  group('Money', () {
    test('fromMajor converts to minor units', () {
      expect(Money.fromMajor(15.9).amountMinor, 1590);
      expect(Money.fromMajor(8.9).amountMinor, 890);
    });

    test('addition and multiplication', () {
      expect((const Money(1000) + const Money(590)).amountMinor, 1590);
      expect((const Money(1290) * 2).amountMinor, 2580);
    });

    test('format renders lei with two decimals', () {
      expect(const Money(1590).format(), '15.90 lei');
      expect(const Money(900).format(), '9.00 lei');
    });

    test('currency mismatch throws', () {
      expect(
        () => const Money(100, currency: 'EUR') + const Money(100),
        throwsArgumentError,
      );
    });
  });
}

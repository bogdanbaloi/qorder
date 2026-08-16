import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/core/money.dart';
import 'package:qorder/domain/models/menu.dart';
import 'package:qorder/domain/pricing/discount.dart';
import 'package:qorder/domain/pricing/menu_pricing.dart';
import 'package:qorder/domain/pricing/promotion.dart';

// REQ-PRICE-001: time-boxed promotions (happy hour) reduce an item's price.
// Pure pricing, so the menu and the cart never disagree.
void main() {
  const allDay = TimeWindow(
    daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
    startMinutes: 0,
    endMinutes: 1439,
  );
  const evening = TimeWindow(
    daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
    startMinutes: 1020, // 17:00
    endMinutes: 1140, // 19:00
  );
  const beer = MenuItem(
    id: 'b',
    categoryId: 'live-beers',
    name: 'Ursus',
    basePrice: Money(1000),
  );
  final aMonday = DateTime(2026, 1, 5, 18); // Monday 18:00

  group('discounts', () {
    test('percentage off, rounded to bani', () {
      expect(
        const PercentageDiscount(20).apply(const Money(1000)).amountMinor,
        800,
      );
      expect(
        const PercentageDiscount(10).apply(const Money(1595)).amountMinor,
        1436, // 1435.5 rounds up
      );
    });

    test('fixed off clamps at zero', () {
      expect(
        const FixedAmountDiscount(
          Money(300),
        ).apply(const Money(1000)).amountMinor,
        700,
      );
      expect(
        const FixedAmountDiscount(
          Money(1500),
        ).apply(const Money(1000)).amountMinor,
        0,
      );
    });
  });

  test('promotion is active in its window and covers by category', () {
    const p = Promotion(
      id: 'hh',
      name: 'Happy Hour',
      window: allDay,
      discount: PercentageDiscount(20),
      categoryIds: {'live-beers'},
    );
    expect(p.isActiveAt(aMonday), true);
    expect(p.covers(categoryId: 'live-beers', tags: const []), true);
    expect(p.covers(categoryId: 'coffee', tags: const []), false);
  });

  test('empty scope means any item', () {
    const p = Promotion(
      id: 'all',
      name: 'All',
      window: allDay,
      discount: PercentageDiscount(50),
    );
    expect(p.covers(categoryId: 'anything', tags: const []), true);
  });

  test('priceItem applies the best active promotion', () {
    const promos = [
      Promotion(
        id: 'a',
        name: '10%',
        window: allDay,
        discount: PercentageDiscount(10),
        categoryIds: {'live-beers'},
      ),
      Promotion(
        id: 'b',
        name: '20%',
        window: allDay,
        discount: PercentageDiscount(20),
        categoryIds: {'live-beers'},
      ),
    ];
    final priced = priceItem(beer, promos, aMonday);
    expect(priced.discounted, true);
    expect(priced.effective.amountMinor, 800); // best = 20% off
    expect(priced.promotion!.name, '20%');
  });

  test('priceItem leaves an uncovered item at base price', () {
    const coffee = MenuItem(
      id: 'c',
      categoryId: 'coffee',
      name: 'Espresso',
      basePrice: Money(890),
    );
    const promos = [
      Promotion(
        id: 'hh',
        name: 'HH',
        window: allDay,
        discount: PercentageDiscount(20),
        categoryIds: {'live-beers'},
      ),
    ];
    final priced = priceItem(coffee, promos, aMonday);
    expect(priced.discounted, false);
    expect(priced.effective.amountMinor, 890);
  });

  test('a promotion outside its window does not apply', () {
    const promos = [
      Promotion(
        id: 'hh',
        name: 'HH',
        window: evening,
        discount: PercentageDiscount(20),
        categoryIds: {'live-beers'},
      ),
    ];
    final noon = DateTime(2026, 1, 5, 12);
    expect(priceItem(beer, promos, noon).discounted, false);
  });

  test('parses promotions from the menu JSON', () {
    final json = <String, dynamic>{
      'venueId': 'v',
      'version': 1,
      'promotions': [
        {
          'id': 'hh',
          'name': 'Happy Hour',
          'window': {
            'daysOfWeek': [1, 2, 3, 4, 5, 6, 7],
            'startMinutes': 960,
            'endMinutes': 1200,
          },
          'discount': {'type': 'percentage', 'percent': 20},
          'categoryIds': ['live-beers'],
        },
      ],
      'categories': [],
    };
    final menu = Menu.fromJson(json);
    expect(menu.promotions.length, 1);
    expect(menu.promotions.first.name, 'Happy Hour');
    expect(menu.promotions.first.discount, isA<PercentageDiscount>());
  });
}

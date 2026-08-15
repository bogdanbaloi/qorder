import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/core/money.dart';
import 'package:qorder/domain/models/menu.dart';

Menu _menu() => const Menu(
  venueId: 'demo',
  version: 1,
  categories: [
    Category(
      id: 'beers',
      name: 'Beri',
      sortOrder: 0,
      items: [
        MenuItem(
          id: 'b1',
          categoryId: 'beers',
          name: 'Bere blondă',
          basePrice: Money(1000),
        ),
        MenuItem(
          id: 'b2',
          categoryId: 'beers',
          name: 'Bere neagră',
          basePrice: Money(1200),
          tags: ['amară'],
        ),
      ],
    ),
    Category(
      id: 'food',
      name: 'Mâncare',
      sortOrder: 1,
      items: [
        MenuItem(
          id: 'f1',
          categoryId: 'food',
          name: 'Nachos',
          basePrice: Money(1500),
          description: 'cu brânză',
        ),
      ],
    ),
  ],
);

void main() {
  // REQ-MENU-002: search filters items by name / description / tag, drops empty
  // categories, and a blank query returns the whole menu.
  test('blank query returns the menu unchanged', () {
    expect(_menu().filtered('').categories.length, 2);
    expect(_menu().filtered('   ').categories.length, 2);
  });

  test('filters by item name, dropping empty categories', () {
    final r = _menu().filtered('nachos');
    expect(r.categories.length, 1);
    expect(r.categories.single.id, 'food');
    expect(r.categories.single.items.single.name, 'Nachos');
  });

  test('matches case-insensitively, by tag and by description', () {
    expect(_menu().filtered('BERE').categories.single.items.length, 2);
    expect(_menu().filtered('amară').categories.single.items.single.id, 'b2');
    expect(_menu().filtered('brânză').categories.single.items.single.id, 'f1');
  });
}

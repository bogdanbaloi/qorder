import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/domain/models/menu.dart';

// REQ-MENU-001: the menu is a structured model, parsed from JSON (not HTML).
void main() {
  final json = <String, dynamic>{
    'venueId': 'v',
    'version': 1,
    'categories': [
      {
        'id': 'md',
        'name': 'MORNING DEAL',
        'sortOrder': 0,
        'availability': {
          'daysOfWeek': [1, 2, 3, 4, 5],
          'startMinutes': 540,
          'endMinutes': 960,
        },
        'items': [
          {
            'id': 'i1',
            'categoryId': 'md',
            'name': 'Combo',
            'basePriceMinor': 1500,
          },
        ],
      },
      {
        'id': 'lb',
        'name': 'LIVE BEERS',
        'sortOrder': 1,
        'items': [
          {
            'id': 'b',
            'categoryId': 'lb',
            'name': 'Ursus',
            'basePriceMinor': 1290,
            'options': [
              {
                'id': 'sz',
                'name': 'size',
                'minSelect': 1,
                'maxSelect': 1,
                'choices': [
                  {'id': '04', 'name': '0.4L', 'priceDeltaMinor': 0},
                  {'id': '1l', 'name': '1L', 'priceDeltaMinor': 1200},
                ],
              },
            ],
          },
        ],
      },
    ],
  };

  test('parses categories, items, options and prices', () {
    final menu = Menu.fromJson(json);
    expect(menu.categories.length, 2);
    final beer = menu.categories[1].items.first;
    expect(beer.basePrice.amountMinor, 1290);
    expect(beer.options.first.choices.length, 2);
    expect(beer.options.first.isRequired, true);
    expect(beer.options.first.choices[1].priceDelta.amountMinor, 1200);
  });

  test('time-windowed category availability', () {
    final menu = Menu.fromJson(json);
    final tw = menu.categories.first.availability!;

    DateTime dayAt(int weekday, int h, int m) {
      var d = DateTime(2026, 1, 1, h, m);
      while (d.weekday != weekday) {
        d = d.add(const Duration(days: 1));
      }
      return DateTime(d.year, d.month, d.day, h, m);
    }

    expect(tw.isAvailableAt(dayAt(DateTime.monday, 10, 0)), true);
    expect(tw.isAvailableAt(dayAt(DateTime.monday, 17, 0)), false);
    expect(tw.isAvailableAt(dayAt(DateTime.sunday, 10, 0)), false);
  });
}

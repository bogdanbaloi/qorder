import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/core/money.dart';
import 'package:qorder/domain/models/menu.dart';

// REQ-MENU-004: an item can carry its own time window, so the menu is smart
// about the hour and only offers what is available now. Pure model logic.
void main() {
  MenuItem item({bool available = true, TimeWindow? window}) => MenuItem(
    id: 'i',
    categoryId: 'c',
    name: 'Happy Combo',
    basePrice: const Money(1500),
    available: available,
    availability: window,
  );

  const morning = TimeWindow(
    daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
    startMinutes: 360, // 06:00
    endMinutes: 720, // 12:00
  );

  test('no window means always available', () {
    final it = item();
    expect(it.isAvailableAt(DateTime(2026, 1, 1, 3)), true);
    expect(it.isAvailableAt(DateTime(2026, 1, 1, 23)), true);
  });

  test('window gates the item by hour', () {
    final it = item(window: morning);
    expect(it.isAvailableAt(DateTime(2026, 1, 1, 9)), true); // inside
    expect(it.isAvailableAt(DateTime(2026, 1, 1, 15)), false); // after
  });

  test('the manual flag still wins over the window', () {
    final it = item(available: false, window: morning);
    expect(it.isAvailableAt(DateTime(2026, 1, 1, 9)), false);
  });

  test('hoursLabel renders zero-padded HH:MM-HH:MM', () {
    expect(morning.hoursLabel, '06:00-12:00');
    const evening = TimeWindow(
      daysOfWeek: [5],
      startMinutes: 1020, // 17:00
      endMinutes: 1140, // 19:00
    );
    expect(evening.hoursLabel, '17:00-19:00');
  });

  test('parses an item-level availability window from JSON', () {
    final json = <String, dynamic>{
      'id': 'i',
      'categoryId': 'c',
      'name': 'Combo',
      'basePriceMinor': 1500,
      'availability': {
        'daysOfWeek': [1, 2, 3],
        'startMinutes': 360,
        'endMinutes': 720,
      },
    };
    final it = MenuItem.fromJson(json);
    expect(it.availability, isNotNull);
    expect(it.availability!.hoursLabel, '06:00-12:00');
  });
}

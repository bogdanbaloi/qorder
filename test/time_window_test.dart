import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/domain/models/time_window.dart';

void main() {
  // The owner writes clock times ("16:00"), the code converts to minutes, so
  // nobody hand-computes minutes-from-midnight.
  test('parses owner-friendly HH:MM times', () {
    final window = TimeWindow.fromJson(const {
      'daysOfWeek': [1, 2, 3, 4, 5],
      'start': '16:00',
      'end': '20:30',
    });
    expect(window.startMinutes, 960);
    expect(window.endMinutes, 1230);
    expect(window.hoursLabel, '16:00-20:30');
  });

  test('still accepts raw minutes (back-compat)', () {
    final window = TimeWindow.fromJson(const {
      'daysOfWeek': [1],
      'startMinutes': 540,
      'endMinutes': 960,
    });
    expect(window.startMinutes, 540);
    expect(window.endMinutes, 960);
  });
}

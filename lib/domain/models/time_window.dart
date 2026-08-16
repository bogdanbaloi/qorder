import 'package:flutter/foundation.dart';

const int _minutesPerHour = 60;
const int _timePadWidth = 2;

/// A time window during which a category, item or promotion is active (e.g.
/// Morning Deal Mon-Fri 09:00-16:00). Days are 1=Mon..7=Sun. Minutes are from
/// midnight. Pure, so time-of-day rules are unit-tested with explicit times.
@immutable
class TimeWindow {
  final List<int> daysOfWeek;
  final int startMinutes;
  final int endMinutes;

  const TimeWindow({
    required this.daysOfWeek,
    required this.startMinutes,
    required this.endMinutes,
  });

  bool isAvailableAt(DateTime dt) {
    if (!daysOfWeek.contains(dt.weekday)) return false;
    final m = dt.hour * _minutesPerHour + dt.minute;
    return m >= startMinutes && m <= endMinutes;
  }

  /// A short "HH:MM-HH:MM" label for the daily hours, for a "disponibil ..." note.
  String get hoursLabel => '${_hhmm(startMinutes)}-${_hhmm(endMinutes)}';

  static String _hhmm(int minutes) {
    final h = (minutes ~/ _minutesPerHour).toString().padLeft(
      _timePadWidth,
      '0',
    );
    final m = (minutes % _minutesPerHour).toString().padLeft(
      _timePadWidth,
      '0',
    );
    return '$h:$m';
  }

  factory TimeWindow.fromJson(Map<String, dynamic> j) => TimeWindow(
    daysOfWeek: (j['daysOfWeek'] as List)
        .map((e) => (e as num).toInt())
        .toList(),
    startMinutes: (j['startMinutes'] as num).toInt(),
    endMinutes: (j['endMinutes'] as num).toInt(),
  );
}

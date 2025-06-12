import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the currently selected date on the calendar UI.
/// Defaults to the current day (ignoring time component).
final selectedCalendarDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  // Normalize to midnight UTC to ensure consistency, similar to other date handling.
  // Or just year, month, day in local timezone if all date comparisons are consistent.
  // Let's use local timezone's year, month, day for simplicity with TableCalendar's defaults.
  return DateTime(now.year, now.month, now.day);
});

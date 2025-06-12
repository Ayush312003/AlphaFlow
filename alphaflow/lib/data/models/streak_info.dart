import 'package:alphaflow/data/models/frequency.dart'; // Added import for Frequency

class TaskStreakInfo {
  final int streakCount;
  final Frequency frequency;

  TaskStreakInfo({required this.streakCount, required this.frequency});
}

DateTime startOfWeek(DateTime date) {
  // Changed from _startOfWeek to startOfWeek (public)
  final utcDate = DateTime.utc(date.year, date.month, date.day);
  // Monday is 1, Sunday is 7. For UTC, weekday returns 1 (Monday) to 7 (Sunday).
  // If date.weekday is 1 (Monday), we subtract 0.
  // If date.weekday is 7 (Sunday), we subtract 6.
  return utcDate.subtract(Duration(days: utcDate.weekday - 1));
}

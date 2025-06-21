import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphaflow/data/models/streak_info.dart';
import 'package:alphaflow/data/models/custom_task.dart';
import 'package:alphaflow/data/models/task_completion.dart';
import 'package:alphaflow/data/models/frequency.dart';
import 'package:alphaflow/providers/custom_tasks_provider.dart';
import 'package:alphaflow/providers/task_completions_provider.dart'; // Now includes combinedCompletionsProvider

// Helper function to get the start of the week (Monday UTC)
DateTime _startOfWeek(DateTime date) {
  final utcDate = DateTime.utc(date.year, date.month, date.day);
  return utcDate.subtract(Duration(days: utcDate.weekday - 1));
}

int _calculateDailyStreak(String taskId, List<TaskCompletion> allCompletions) {
  final taskCompletions =
      allCompletions
          .where((c) => c.taskId == taskId)
          .map((c) => DateTime.utc(c.date.year, c.date.month, c.date.day))
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a)); // Descending

  if (taskCompletions.isEmpty) return 0;

  int currentStreak = 0;
  DateTime today = DateTime.utc(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  DateTime yesterday = today.subtract(const Duration(days: 1));

  if (taskCompletions.contains(today)) {
    currentStreak = 1;
    DateTime dayToCheck = yesterday;
    // Start looking from the completion *after* today in the sorted list
    int todayIndex = taskCompletions.indexOf(today);
    for (int i = todayIndex + 1; i < taskCompletions.length; i++) {
      if (taskCompletions[i] == dayToCheck) {
        currentStreak++;
        dayToCheck = dayToCheck.subtract(const Duration(days: 1));
      } else if (taskCompletions[i].isBefore(dayToCheck)) {
        // Gap in completions, streak broken earlier than dayToCheck
        break;
      }
    }
  } else if (taskCompletions.contains(yesterday)) {
    currentStreak = 1;
    DateTime dayToCheck = yesterday.subtract(const Duration(days: 1));
    // Start looking from the completion *after* yesterday in the sorted list
    int yesterdayIndex = taskCompletions.indexOf(yesterday);
    for (int i = yesterdayIndex + 1; i < taskCompletions.length; i++) {
      if (taskCompletions[i] == dayToCheck) {
        currentStreak++;
        dayToCheck = dayToCheck.subtract(const Duration(days: 1));
      } else if (taskCompletions[i].isBefore(dayToCheck)) {
        break;
      }
    }
  }
  return currentStreak;
}

int _calculateWeeklyStreak(String taskId, List<TaskCompletion> allCompletions) {
  final taskCompletionsOnFirstDayOfWeek =
      allCompletions
          .where((c) => c.taskId == taskId)
          .map((c) => _startOfWeek(c.date)) // Use local _startOfWeek
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a)); // Descending

  if (taskCompletionsOnFirstDayOfWeek.isEmpty) return 0;

  int currentStreak = 0;
  DateTime startOfCurrentWeek = _startOfWeek(DateTime.now());
  DateTime startOfLastWeek = startOfCurrentWeek.subtract(
    const Duration(days: 7),
  );

  if (taskCompletionsOnFirstDayOfWeek.contains(startOfCurrentWeek)) {
    currentStreak = 1;
    DateTime weekToCheck = startOfLastWeek;
    int currentWeekIndex = taskCompletionsOnFirstDayOfWeek.indexOf(
      startOfCurrentWeek,
    );
    for (
      int i = currentWeekIndex + 1;
      i < taskCompletionsOnFirstDayOfWeek.length;
      i++
    ) {
      if (taskCompletionsOnFirstDayOfWeek[i] == weekToCheck) {
        currentStreak++;
        weekToCheck = weekToCheck.subtract(const Duration(days: 7));
      } else if (taskCompletionsOnFirstDayOfWeek[i].isBefore(weekToCheck)) {
        break;
      }
    }
  } else if (taskCompletionsOnFirstDayOfWeek.contains(startOfLastWeek)) {
    currentStreak = 1;
    DateTime weekToCheck = startOfLastWeek.subtract(const Duration(days: 7));
    int lastWeekIndex = taskCompletionsOnFirstDayOfWeek.indexOf(
      startOfLastWeek,
    );
    for (
      int i = lastWeekIndex + 1;
      i < taskCompletionsOnFirstDayOfWeek.length;
      i++
    ) {
      if (taskCompletionsOnFirstDayOfWeek[i] == weekToCheck) {
        currentStreak++;
        weekToCheck = weekToCheck.subtract(const Duration(days: 7));
      } else if (taskCompletionsOnFirstDayOfWeek[i].isBefore(weekToCheck)) {
        break;
      }
    }
  }
  return currentStreak;
}

final customTaskStreaksProvider = Provider<Map<String, TaskStreakInfo>>((ref) {
  final allCustomTasks = ref.watch(customTasksProvider);
  final allCompletions = ref.watch(combinedCompletionsProvider); // Use combined provider for immediate updates

  final streaksMap = <String, TaskStreakInfo>{};

  for (final task in allCustomTasks) {
    if (task.frequency == Frequency.daily) {
      streaksMap[task.id] = TaskStreakInfo(
        streakCount: _calculateDailyStreak(task.id, allCompletions),
        frequency: Frequency.daily,
      );
    } else if (task.frequency == Frequency.weekly) {
      streaksMap[task.id] = TaskStreakInfo(
        streakCount: _calculateWeeklyStreak(task.id, allCompletions),
        frequency: Frequency.weekly,
      );
    }
    // 'oneTime' tasks don't have streaks and are not added to the map
  }
  return streaksMap;
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphaflow/data/models/streak_info.dart';
import 'package:alphaflow/data/models/task_completion.dart';
import 'package:alphaflow/data/models/frequency.dart';
import 'package:alphaflow/data/models/guided_task.dart';
import 'package:alphaflow/data/models/level_definition.dart'; // Required for currentGuidedLevelProvider's return type
import 'package:alphaflow/providers/task_completions_provider.dart';
import 'package:alphaflow/providers/guided_level_provider.dart';
import 'package:alphaflow/providers/selected_track_provider.dart'; // To ensure provider rebuilds if track changes

// Copied from custom_task_streaks_provider.dart and made public for potential reuse or testing
// OR keep them private (_calculateDailyStreak, _calculateWeeklyStreak) if only used here.
// For now, keeping them private to this file.

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
    int todayIndex = taskCompletions.indexOf(today);
    for (int i = todayIndex + 1; i < taskCompletions.length; i++) {
      if (taskCompletions[i] == dayToCheck) {
        currentStreak++;
        dayToCheck = dayToCheck.subtract(const Duration(days: 1));
      } else if (taskCompletions[i].isBefore(dayToCheck)) {
        break;
      }
    }
  } else if (taskCompletions.contains(yesterday)) {
    currentStreak = 1;
    DateTime dayToCheck = yesterday.subtract(const Duration(days: 1));
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
          .map((c) => startOfWeek(c.date)) // Uses imported startOfWeek
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a)); // Descending

  if (taskCompletionsOnFirstDayOfWeek.isEmpty) return 0;

  int currentStreak = 0;
  DateTime startOfCurrentWeek = startOfWeek(DateTime.now());
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

final guidedTaskStreaksProvider = Provider<Map<String, TaskStreakInfo>>((ref) {
  final allCompletions = ref.watch(completionsProvider);
  final LevelDefinition? currentLevel = ref.watch(currentGuidedLevelProvider);

  // Watch selectedTrackProvider to ensure this provider rebuilds when the track changes.
  // The actual task list is derived from currentLevel, which itself depends on selectedTrackProvider.
  ref.watch(selectedTrackProvider);

  final streaksMap = <String, TaskStreakInfo>{};

  if (currentLevel == null) {
    return streaksMap; // Return empty map if no current level
  }

  final List<GuidedTask> currentLevelTasks = currentLevel.unlockTasks;

  for (final task in currentLevelTasks) {
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
    // 'oneTime' tasks do not have streaks and are not added to the map
  }

  return streaksMap;
});

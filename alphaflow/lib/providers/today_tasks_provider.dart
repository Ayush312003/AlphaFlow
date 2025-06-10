import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphaflow/data/models/app_mode.dart';
import 'package:alphaflow/data/models/custom_task.dart';
import 'package:alphaflow/data/models/guided_task.dart';
// import 'package:alphaflow/data/models/guided_track.dart'; // Not directly used
import 'package:alphaflow/data/models/task_completion.dart';
import 'package:alphaflow/data/models/today_task.dart';
import 'package:alphaflow/data/models/frequency.dart';
import 'package:alphaflow/data/models/task_priority.dart';
import 'package:alphaflow/data/models/level_definition.dart';
import 'package:alphaflow/providers/app_mode_provider.dart';
import 'package:alphaflow/providers/calendar_providers.dart';
import 'package:alphaflow/providers/selected_track_provider.dart';
// import 'package:alphaflow/features/guided/providers/guided_tracks_provider.dart'; // Not directly used
import 'package:alphaflow/providers/custom_tasks_provider.dart';
import 'package:alphaflow/providers/task_completions_provider.dart';
import 'package:alphaflow/providers/guided_level_provider.dart';
import 'package:table_calendar/table_calendar.dart'; // For isSameDay

// Helper to get the start of the week (Monday UTC) for a given DateTime
DateTime _startOfWeek(DateTime date) {
  final utcDate = DateTime.utc(date.year, date.month, date.day);
  return utcDate.subtract(Duration(days: utcDate.weekday - 1));
}

final displayedDateTasksProvider = Provider<List<TodayTask>>((ref) {
  final DateTime currentDisplayDate = ref.watch(selectedCalendarDateProvider);
  final appMode = ref.watch(appModeProvider);
  final completions = ref.watch(completionsProvider);

  final List<TodayTask> tasksForDisplay = [];
  final DateTime startOfThisWeek = _startOfWeek(currentDisplayDate);

  bool isTaskCompletedOnSelectedDate(String taskId) {
    return completions.any(
      (comp) =>
          comp.taskId == taskId &&
          comp.date.year == currentDisplayDate.year &&
          comp.date.month == currentDisplayDate.month &&
          comp.date.day == currentDisplayDate.day,
    );
  }

  bool isTaskCompletedThisWeek(String taskId) {
    return completions.any(
      (comp) =>
          comp.taskId == taskId && _startOfWeek(comp.date) == startOfThisWeek,
    );
  }

  if (appMode == AppMode.guided) {
    final DateTime nowDateNormalized = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    if (!isSameDay(currentDisplayDate, nowDateNormalized)) {
      // For past/future dates, show no guided tasks in Phase 1
    } else {
      // Existing logic for today's guided tasks
      final selectedTrackId = ref.watch(selectedTrackProvider);
      if (selectedTrackId != null) {
        final LevelDefinition? currentLevel = ref.watch(
          currentGuidedLevelProvider,
        );
        if (currentLevel != null) {
          final List<GuidedTask> levelTasks = currentLevel.unlockTasks;
          for (final guidedTask in levelTasks) {
            bool shouldDisplay = false;
            bool isCompleted = false;

            if (guidedTask.frequency == Frequency.daily) {
              shouldDisplay = true;
              isCompleted = isTaskCompletedOnSelectedDate(guidedTask.id);
            } else if (guidedTask.frequency == Frequency.weekly) {
              isCompleted = isTaskCompletedThisWeek(guidedTask.id);
              if (guidedTask.dayOfWeek != null) {
                if (currentDisplayDate.weekday == guidedTask.dayOfWeek) {
                  shouldDisplay = true;
                } else {
                  shouldDisplay = false;
                }
              } else {
                shouldDisplay = true;
              }
            } else if (guidedTask.frequency == Frequency.oneTime) {
              isCompleted = completions.any(
                (c) =>
                    c.taskId == guidedTask.id && c.trackId == selectedTrackId,
              );
              shouldDisplay = !isCompleted;
            }

            if (shouldDisplay) {
              tasksForDisplay.add(
                TodayTask.fromGuidedTask(guidedTask, isCompleted),
              );
            }
          }
        } else {
          print(
            "displayedDateTasksProvider: No current level determined for track $selectedTrackId.",
          );
        }
      } else {
        print("displayedDateTasksProvider: No track selected for guided mode.");
      }
    }
  } else if (appMode == AppMode.custom) {
    final allCustomTasks = ref.watch(customTasksProvider);
    for (final customTask in allCustomTasks) {
      bool shouldDisplay = false;
      bool isCompleted = false;

      if (customTask.frequency == Frequency.daily) {
        shouldDisplay = true;
        isCompleted = isTaskCompletedOnSelectedDate(customTask.id);
      } else if (customTask.frequency == Frequency.weekly) {
        shouldDisplay =
            true; // Custom weekly tasks always "available" on the list for the week
        isCompleted = isTaskCompletedThisWeek(customTask.id);
      } else if (customTask.frequency == Frequency.oneTime) {
        final firstCompletionDate = completions
            .where((c) => c.taskId == customTask.id)
            .map((c) => c.date)
            .fold<DateTime?>(
              null,
              (prev, current) =>
                  (prev == null || current.isBefore(prev)) ? current : prev,
            );

        if (firstCompletionDate != null &&
            !firstCompletionDate.isAfter(currentDisplayDate)) {
          isCompleted = true;
        } else {
          isCompleted = false;
        }
        shouldDisplay = !isCompleted;
      }

      if (shouldDisplay) {
        tasksForDisplay.add(TodayTask.fromCustomTask(customTask, isCompleted));
      }
    }
  }

  tasksForDisplay.sort((a, b) {
    if (a.isCompleted != b.isCompleted) {
      return a.isCompleted ? 1 : -1;
    }
    if (a.type == TodayTaskType.custom && b.type == TodayTaskType.custom) {
      final priorityA = a.priority ?? TaskPriority.none;
      final priorityB = b.priority ?? TaskPriority.none;
      if (priorityA != priorityB) {
        return priorityB.index.compareTo(priorityA.index);
      }
    }
    final titleA = a.title.toLowerCase();
    final titleB = b.title.toLowerCase();
    if (titleA != titleB) {
      return titleA.compareTo(titleB);
    }
    return 0;
  });

  return tasksForDisplay;
});

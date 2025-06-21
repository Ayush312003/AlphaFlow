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
// Removed old appModeProvider and selectedTrackProvider imports
// import 'package:alphaflow/providers/app_mode_provider.dart';
import 'package:alphaflow/providers/calendar_providers.dart';
// import 'package:alphaflow/providers/selected_track_provider.dart';
import 'package:alphaflow/features/user_profile/application/user_data_providers.dart'; // Added for new providers
// import 'package:alphaflow/features/guided/providers/guided_tracks_provider.dart'; // Not directly used
import 'package:alphaflow/providers/custom_tasks_provider.dart';
import 'package:alphaflow/providers/task_completions_provider.dart'; // Now includes combinedCompletionsProvider
import 'package:alphaflow/providers/guided_level_provider.dart';
import 'package:table_calendar/table_calendar.dart'; // For isSameDay
import 'package:alphaflow/features/guided/providers/guided_tracks_provider.dart';
import 'package:alphaflow/providers/guided_level_provider.dart';
import 'package:alphaflow/providers/app_mode_provider.dart';
import 'package:alphaflow/providers/selected_track_provider.dart';

// Helper to get the start of the week (Monday UTC) for a given DateTime
DateTime _startOfWeek(DateTime date) {
  final utcDate = DateTime.utc(date.year, date.month, date.day);
  return utcDate.subtract(Duration(days: utcDate.weekday - 1));
}

final displayedDateTasksProvider = Provider<List<TodayTask>>((ref) {
  final DateTime currentDisplayDate = ref.watch(selectedCalendarDateProvider);
  final appMode = ref.watch(localAppModeProvider); // Changed to local provider
  final completions = ref.watch(combinedCompletionsProvider); // Use combined provider for immediate updates

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
    final selectedTrackId = ref.watch(localSelectedTrackProvider); // Changed to local provider
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
            final firstCompletionForTrack = completions
                .where((c) => c.taskId == guidedTask.id && c.trackId == selectedTrackId)
                .map((c) => c.date)
                .fold<DateTime?>(
                  null,
                  (prev, current) => (prev == null || current.isBefore(prev)) ? current : prev,
                );

            if (firstCompletionForTrack != null && !firstCompletionForTrack.isAfter(currentDisplayDate)) {
              isCompleted = true;
              shouldDisplay = false; // If completed on or before this date, don't display again
            } else {
              isCompleted = false;
              shouldDisplay = true; // If not completed by this date, or completed after, display as to-do
            }
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
  } else if (appMode == AppMode.custom) {
    final allCustomTasks = ref.watch(customTasksProvider);
    for (final customTask in allCustomTasks) {
      bool shouldDisplay = false;
      bool isCompleted = false;

      if (customTask.frequency == Frequency.daily) {
        shouldDisplay = true;
        isCompleted = isTaskCompletedOnSelectedDate(customTask.id);
      } else if (customTask.frequency == Frequency.weekly) {
        shouldDisplay = true;
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

        if (firstCompletionDate != null && !firstCompletionDate.isAfter(currentDisplayDate)) {
          isCompleted = true;
          shouldDisplay = false; // Do not display if completed by this date
        } else {
          isCompleted = false;
          shouldDisplay = true; // Display if not completed by this date
        }
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

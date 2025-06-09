import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphaflow/data/models/app_mode.dart';
import 'package:alphaflow/data/models/custom_task.dart';
import 'package:alphaflow/data/models/guided_task.dart';
import 'package:alphaflow/data/models/guided_track.dart';
import 'package:alphaflow/data/models/task_completion.dart';
import 'package:alphaflow/data/models/today_task.dart';
import 'package:alphaflow/data/models/frequency.dart';
import 'package:alphaflow/data/models/task_priority.dart'; // Added missing import
import 'package:alphaflow/data/models/level_definition.dart'; // Added import
import 'package:alphaflow/providers/app_mode_provider.dart';
import 'package:alphaflow/providers/selected_track_provider.dart';
import 'package:alphaflow/features/guided/providers/guided_tracks_provider.dart';
import 'package:alphaflow/providers/custom_tasks_provider.dart';
import 'package:alphaflow/providers/task_completions_provider.dart';
import 'package:alphaflow/providers/guided_level_provider.dart'; // Added import

// Helper to get the start of the week (Monday UTC) for a given DateTime
DateTime _startOfWeek(DateTime date) {
  final utcDate = DateTime.utc(date.year, date.month, date.day);
  return utcDate.subtract(Duration(days: utcDate.weekday - 1));
}

final todayTasksProvider = Provider<List<TodayTask>>((ref) {
  final appMode = ref.watch(appModeProvider);
  final completions = ref.watch(completionsProvider);

  final List<TodayTask> tasksForToday = [];
  final DateTime today = DateTime.utc(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  final DateTime startOfThisWeek = _startOfWeek(today);

  bool isTaskCompletedToday(String taskId) {
    return completions.any(
      (comp) =>
          comp.taskId == taskId &&
          comp.date.year == today.year &&
          comp.date.month == today.month &&
          comp.date.day == today.day,
    );
  }

  bool isTaskCompletedThisWeek(String taskId) {
    return completions.any(
      (comp) =>
          comp.taskId == taskId && _startOfWeek(comp.date) == startOfThisWeek,
    );
  }

  if (appMode == AppMode.guided) {
    final selectedTrackId = ref.watch(selectedTrackProvider);
    // guidedTracksProvider is watched by currentGuidedLevelProvider indirectly.
    // We only need currentGuidedLevelProvider here.

    if (selectedTrackId != null) {
      // Ensure a track is selected
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
            isCompleted = isTaskCompletedToday(guidedTask.id);
          } else if (guidedTask.frequency == Frequency.weekly) {
            isCompleted = isTaskCompletedThisWeek(
              guidedTask.id,
            ); // Completion check is for the whole week

            // The 'today' variable (DateTime.utc(...)) is defined earlier in the provider.
            // We need to ensure it's accessible or re-fetch its weekday component if necessary.
            // Assuming 'today' is accessible:
            if (guidedTask.dayOfWeek != null) {
              if (today.weekday == guidedTask.dayOfWeek) {
                // today.weekday (1=Mon, 7=Sun)
                shouldDisplay = true;
              } else {
                shouldDisplay = false;
              }
            } else {
              // No specific day (dayOfWeek is null), so display it throughout the week
              shouldDisplay = true;
            }
          } else if (guidedTask.frequency == Frequency.oneTime) {
            // Check completion specifically for this trackId, as task ID might not be globally unique for one-time tasks
            // if they are defined per level but could have same ID if not careful in data definition.
            // TaskCompletion for guided tasks should have trackId set.
            isCompleted = completions.any(
              (c) => c.taskId == guidedTask.id && c.trackId == selectedTrackId,
            );
            shouldDisplay = !isCompleted;
          }

          if (shouldDisplay) {
            tasksForToday.add(
              TodayTask.fromGuidedTask(guidedTask, isCompleted),
            );
          }
        }
      } else {
        // No current level determined (e.g., track has no levels, or error in level provider)
        // tasksForToday remains empty for guided mode.
        print(
          "todayTasksProvider: No current level determined for track $selectedTrackId.",
        );
      }
    } else {
      print("todayTasksProvider: No track selected for guided mode.");
    }
  } else if (appMode == AppMode.custom) {
    final allCustomTasks = ref.watch(customTasksProvider);
    for (final customTask in allCustomTasks) {
      bool shouldDisplay = false;
      bool isCompleted = false;

      if (customTask.frequency == Frequency.daily) {
        shouldDisplay = true;
        isCompleted = isTaskCompletedToday(customTask.id);
      } else if (customTask.frequency == Frequency.weekly) {
        shouldDisplay = true;
        isCompleted = isTaskCompletedThisWeek(customTask.id);
      } else if (customTask.frequency == Frequency.oneTime) {
        isCompleted = completions.any((c) => c.taskId == customTask.id);
        shouldDisplay = !isCompleted;
      }

      if (shouldDisplay) {
        tasksForToday.add(TodayTask.fromCustomTask(customTask, isCompleted));
      }
    }
  }

  tasksForToday.sort((a, b) {
    // Primary sort: Incomplete tasks first
    if (a.isCompleted != b.isCompleted) {
      return a.isCompleted ? 1 : -1;
    }

    // Secondary sort: By priority for custom tasks (High > Medium > Low > None)
    // This applies only if completion status is the same.
    if (a.type == TodayTaskType.custom && b.type == TodayTaskType.custom) {
      // Access priority from TodayTask's new field
      final priorityA = a.priority ?? TaskPriority.none;
      final priorityB = b.priority ?? TaskPriority.none;

      if (priorityA != priorityB) {
        return priorityB.index.compareTo(
          priorityA.index,
        ); // Descending order of index
      }
    }
    // Add further sorting if needed (e.g. by title) or return 0
    // For now, if priorities are same or types differ (and completion is same), keep current relative order or sort by title

    // Optional Tertiary sort: by title alphabetically (case-insensitive)
    // This will apply if completion is same, and if custom tasks, priority is also same.
    final titleA = a.title.toLowerCase();
    final titleB = b.title.toLowerCase();
    if (titleA != titleB) {
      return titleA.compareTo(titleB);
    }

    return 0;
  });

  return tasksForToday;
});

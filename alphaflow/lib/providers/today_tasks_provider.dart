import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphaflow/data/models/app_mode.dart';
import 'package:alphaflow/data/models/custom_task.dart';
import 'package:alphaflow/data/models/guided_task.dart';
import 'package:alphaflow/data/models/guided_track.dart';
import 'package:alphaflow/data/models/task_completion.dart';
import 'package:alphaflow/data/models/today_task.dart';
import 'package:alphaflow/data/models/frequency.dart';
import 'package:alphaflow/providers/app_mode_provider.dart';
import 'package:alphaflow/providers/selected_track_provider.dart';
import 'package:alphaflow/features/guided/providers/guided_tracks_provider.dart';
import 'package:alphaflow/providers/custom_tasks_provider.dart';
import 'package:alphaflow/providers/task_completions_provider.dart';

// Helper to get the start of the week (Monday UTC) for a given DateTime
DateTime _startOfWeek(DateTime date) {
  final utcDate = DateTime.utc(date.year, date.month, date.day);
  // DateTime.weekday returns 1 for Monday and 7 for Sunday.
  // To get Monday, subtract (weekday - 1) days.
  return utcDate.subtract(Duration(days: utcDate.weekday - 1));
}

final todayTasksProvider = Provider<List<TodayTask>>((ref) {
  final appMode = ref.watch(appModeProvider);
  final completions = ref.watch(completionsProvider);

  final List<TodayTask> tasksForToday = [];
  final DateTime today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  final DateTime startOfThisWeek = _startOfWeek(today);

  bool isTaskCompletedToday(String taskId) {
    return completions.any((comp) =>
        comp.taskId == taskId &&
        comp.date.year == today.year &&
        comp.date.month == today.month &&
        comp.date.day == today.day
    );
  }

  bool isTaskCompletedThisWeek(String taskId) {
    return completions.any((comp) =>
        comp.taskId == taskId &&
        _startOfWeek(comp.date) == startOfThisWeek
    );
  }

  if (appMode == AppMode.guided) {
    final selectedTrackId = ref.watch(selectedTrackProvider);
    // guidedTracksProvider provides List<GuidedTrack>, not nullable
    final allGuidedTracks = ref.watch(guidedTracksProvider);

    if (selectedTrackId != null) {
      GuidedTrack? track;
      try {
        track = allGuidedTracks.firstWhere((t) => t.id == selectedTrackId);
      } catch (e) {
        track = null; // Not found
      }

      if (track != null) {
        // For now, assume Level 1 tasks. Level progression is a future feature.
        final List<GuidedTask> levelTasks = track.levels.isNotEmpty ? track.levels[0].unlockTasks : [];

        for (final guidedTask in levelTasks) {
          bool shouldDisplay = false;
          bool isCompleted = false;

          if (guidedTask.frequency == Frequency.daily) {
            shouldDisplay = true;
            isCompleted = isTaskCompletedToday(guidedTask.id);
          } else if (guidedTask.frequency == Frequency.weekly) {
            shouldDisplay = true;
            isCompleted = isTaskCompletedThisWeek(guidedTask.id);
          }
          // 'oneTime' guided tasks are not explicitly handled for display here yet.
          // They would typically be part of level unlocks or specific conditions.

          if (shouldDisplay) {
            tasksForToday.add(TodayTask.fromGuidedTask(guidedTask, isCompleted));
          }
        }
      }
    }
  } else if (appMode == AppMode.custom) {
    // customTasksProvider provides List<CustomTask>, not nullable
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
        shouldDisplay = !isCompleted; // Only show one-time tasks if they are not yet completed
      }

      if (shouldDisplay) {
        tasksForToday.add(TodayTask.fromCustomTask(customTask, isCompleted));
      }
    }
  }

  tasksForToday.sort((a, b) {
    if (a.isCompleted != b.isCompleted) {
      return a.isCompleted ? 1 : -1; // Incomplete tasks first
    }
    // Optional: Add secondary sort criteria, e.g., by title
    // return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    return 0;
  });

  return tasksForToday;
});

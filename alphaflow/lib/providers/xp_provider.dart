import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphaflow/data/models/app_mode.dart';
import 'package:alphaflow/data/models/guided_task.dart';
import 'package:alphaflow/data/models/guided_track.dart';
import 'package:alphaflow/data/models/task_completion.dart';
import 'package:alphaflow/providers/app_mode_provider.dart';
import 'package:alphaflow/providers/selected_track_provider.dart';
import 'package:alphaflow/features/guided/providers/guided_tracks_provider.dart';
import 'package:alphaflow/providers/task_completions_provider.dart'; // Now a StreamProvider

final xpProvider = Provider<int>((ref) {
  final appMode = ref.watch(appModeProvider);
  final selectedTrackId = ref.watch(selectedTrackProvider);
  final completionsAsyncValue = ref.watch(completionsProvider); // AsyncValue<List<TaskCompletion>>
  final allGuidedTracks = ref.watch(guidedTracksProvider);

  return completionsAsyncValue.when(
    data: (completions) { // completions is List<TaskCompletion>
      if (appMode != AppMode.guided || selectedTrackId == null) {
        return 0;
      }

      GuidedTrack? currentTrack;
      try {
        currentTrack = allGuidedTracks.firstWhere((track) => track.id == selectedTrackId);
      } catch (e) {
        // print("Error: Could not find selected track with ID $selectedTrackId in xpProvider. $e");
        return 0;
      }

      final Map<String, GuidedTask> allTasksInCurrentTrackMap = {};
      for (var level in currentTrack.levels) {
        for (var task in level.unlockTasks) {
          allTasksInCurrentTrackMap[task.id] = task;
        }
      }

      int currentDayXp = 0;
      final DateTime today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);

      for (final completion in completions) {
        final completionDate = DateTime.utc(completion.date.year, completion.date.month, completion.date.day);
        // Only count XP for today's completions that belong to the selected guided track
        if (completionDate == today && completion.trackId == selectedTrackId) {
          // Use the xpAwarded stored at the time of completion for accuracy
          currentDayXp += completion.xpAwarded;
        }
      }
      return currentDayXp;
    },
    loading: () => 0, // Default to 0 while loading completions
    error: (err, stack) {
      print("Error in completionsProvider stream for xpProvider: $err");
      print(stack);
      return 0; // Default to 0 on error
    },
  );
});

// This is Step 9, but since totalTrackXpProvider is in the same file and needs similar changes,
// it's being updated here. The plan was to update it to read from Firestore user doc.
// For now, let's make it also consume completionsProvider correctly.
// The definitive update to read from users/{userID}.trackProgress.totalXP will be in the next dedicated step for totalTrackXpProvider.
final totalTrackXpProvider = Provider<int>((ref) {
  final selectedTrackId = ref.watch(selectedTrackProvider);
  final completionsAsyncValue = ref.watch(completionsProvider); // AsyncValue<List<TaskCompletion>>
  final allGuidedTracks = ref.watch(guidedTracksProvider);

  return completionsAsyncValue.when(
    data: (completions) { // completions is List<TaskCompletion>
      if (selectedTrackId == null) {
        return 0;
      }

      GuidedTrack? currentTrack;
      try {
        currentTrack = allGuidedTracks.firstWhere((track) => track.id == selectedTrackId);
      } catch (e) {
        // print("Error: Could not find selected track with ID $selectedTrackId in totalTrackXpProvider. $e");
        return 0;
      }

      // Create a quick lookup for task XP values for the current track
      // This is not strictly needed if we rely on completion.xpAwarded, but original code used it.
      // Let's switch to completion.xpAwarded for consistency and because it's now stored.
      // final Map<String, int> taskXpMap = {};
      // for (var level in currentTrack.levels) {
      //   for (var task in level.unlockTasks) {
      //     taskXpMap[task.id] = task.xp;
      //   }
      // }
      // if (taskXpMap.isEmpty && currentTrack.levels.any((l) => l.unlockTasks.isNotEmpty)) {
      //    // This case implies tasks exist but somehow taskXpMap is empty - should not happen if tasks have XP
      //    // print("Warning: taskXpMap is empty for track $selectedTrackId but tasks exist.");
      // }


      int totalAccumulatedXp = 0;
      for (final completion in completions) {
        // Only sum XP for completions belonging to the selected guided track
        if (completion.trackId == selectedTrackId) {
          totalAccumulatedXp += completion.xpAwarded;
        }
      }
      return totalAccumulatedXp;
    },
    loading: () => 0, // Default to 0 while loading
    error: (err, stack) {
      print("Error in completionsProvider stream for totalTrackXpProvider: $err");
      print(stack);
      return 0; // Default to 0 on error
    },
  );
});

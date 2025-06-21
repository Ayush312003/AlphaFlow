import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphaflow/features/user_profile/application/user_data_providers.dart';
import 'package:alphaflow/data/models/app_mode.dart';
import 'package:alphaflow/data/models/guided_task.dart';
import 'package:alphaflow/data/models/guided_track.dart';
import 'package:alphaflow/data/models/task_completion.dart';
import 'package:alphaflow/providers/app_mode_provider.dart';
import 'package:alphaflow/providers/selected_track_provider.dart';
import 'package:alphaflow/features/guided/providers/guided_tracks_provider.dart';
import 'package:alphaflow/providers/task_completions_provider.dart'; // Now includes combinedCompletionsProvider

final xpProvider = Provider<int>((ref) {
  final appMode = ref.watch(localAppModeProvider);
  final selectedTrackId = ref.watch(localSelectedTrackProvider);
  final completions = ref.watch(combinedCompletionsProvider); // Use combined provider for immediate updates
  final guidedTracksAsync = ref.watch(guidedTracksProvider);

  if (appMode != AppMode.guided || selectedTrackId == null) {
    return 0;
  }

  // Handle async loading of guided tracks
  return guidedTracksAsync.when(
    data: (allGuidedTracks) {
      GuidedTrack? currentTrack;
      try {
        currentTrack = allGuidedTracks.firstWhere((track) => track.id == selectedTrackId);
      } catch (e) {
        print("Error: Could not find selected track with ID $selectedTrackId in xpProvider. $e");
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
    loading: () => 0,
    error: (error, stack) {
      print("Error loading guided tracks in xpProvider: $error");
      return 0;
    },
  );
});

// This is Step 9, but since totalTrackXpProvider is in the same file and needs similar changes,
// it's being updated here. The plan was to update it to read from Firestore user doc.
// For now, let's make it also consume combinedCompletionsProvider correctly.
// The definitive update to read from users/{userID}.trackProgress.totalXP will be in the next dedicated step for totalTrackXpProvider.
final totalTrackXpProvider = Provider<int>((ref) {
  final selectedTrackId = ref.watch(localSelectedTrackProvider);
  final completions = ref.watch(combinedCompletionsProvider); // Use combined provider for immediate updates
  final guidedTracksAsync = ref.watch(guidedTracksProvider);

  if (selectedTrackId == null) {
    return 0;
  }

  // Handle async loading of guided tracks
  return guidedTracksAsync.when(
    data: (allGuidedTracks) {
      GuidedTrack? currentTrack;
      try {
        currentTrack = allGuidedTracks.firstWhere((track) => track.id == selectedTrackId);
      } catch (e) {
        print("Error: Could not find selected track with ID $selectedTrackId in totalTrackXpProvider. $e");
        return 0;
      }

      int totalAccumulatedXp = 0;
      for (final completion in completions) {
        // Only sum XP for completions belonging to the selected guided track
        if (completion.trackId == selectedTrackId) {
          totalAccumulatedXp += completion.xpAwarded;
        }
      }
      
      return totalAccumulatedXp;
    },
    loading: () => 0,
    error: (error, stack) {
      print("Error loading guided tracks in totalTrackXpProvider: $error");
      return 0;
    },
  );
});

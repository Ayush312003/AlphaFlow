import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphaflow/data/models/app_mode.dart';
import 'package:alphaflow/data/models/guided_task.dart';
import 'package:alphaflow/data/models/guided_track.dart';
import 'package:alphaflow/data/models/task_completion.dart';
import 'package:alphaflow/providers/app_mode_provider.dart';
import 'package:alphaflow/providers/selected_track_provider.dart';
import 'package:alphaflow/features/guided/providers/guided_tracks_provider.dart';
import 'package:alphaflow/providers/task_completions_provider.dart';

final xpProvider = Provider<int>((ref) {
  final appMode = ref.watch(appModeProvider);
  final selectedTrackId = ref.watch(selectedTrackProvider);
  final completions = ref.watch(completionsProvider); // List<TaskCompletion>
  final allGuidedTracks = ref.watch(guidedTracksProvider); // List<GuidedTrack>

  if (appMode != AppMode.guided || selectedTrackId == null) {
    return 0; // No XP if not in guided mode or no track selected
  }

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
    if (completionDate == today) {
      final GuidedTask? completedTaskDetails = allTasksInCurrentTrackMap[completion.taskId];
      if (completedTaskDetails != null) {
        currentDayXp += completedTaskDetails.xp;
      }
    }
  }
  return currentDayXp;
});

final totalTrackXpProvider = Provider<int>((ref) {
  final selectedTrackId = ref.watch(selectedTrackProvider);
  final completions = ref.watch(completionsProvider); // List<TaskCompletion>
  final allGuidedTracks = ref.watch(guidedTracksProvider); // List<GuidedTrack>

  if (selectedTrackId == null) {
    return 0; // No track selected, so no total XP for a track
  }

  GuidedTrack? currentTrack;
  try {
    currentTrack = allGuidedTracks.firstWhere((track) => track.id == selectedTrackId);
  } catch (e) {
    print("Error: Could not find selected track with ID $selectedTrackId in totalTrackXpProvider. $e");
    return 0;
  }

  final Map<String, int> taskXpMap = {};
  for (var level in currentTrack.levels) {
    for (var task in level.unlockTasks) {
      taskXpMap[task.id] = task.xp;
    }
  }

  if (taskXpMap.isEmpty) {
    return 0; // No tasks in this track to earn XP from
  }

  int totalAccumulatedXp = 0;

  for (final completion in completions) {
    if (taskXpMap.containsKey(completion.taskId)) {
      // Ensure that trackId in completion matches selectedTrackId if it exists.
      // This is important if a task ID could hypothetically be in multiple tracks.
      // For AlphaFlow's current design, completion.trackId is for Guided Tasks.
      if (completion.trackId == selectedTrackId || completion.trackId == null) {
        // Allow if trackId matches, or if trackId is null (e.g. if completions could be for custom tasks, though this provider is for guided track XP)
        // For robustness, ensuring the completion is for the *selected track* is key.
        // The taskXpMap already filters by selected track's tasks.
        // If completion.trackId is consistently set for guided task completions, this check is even stronger:
        // if (completion.trackId == selectedTrackId && taskXpMap.containsKey(completion.taskId)) {
        totalAccumulatedXp += taskXpMap[completion.taskId]!;
      }
    }
  }

  return totalAccumulatedXp;
});

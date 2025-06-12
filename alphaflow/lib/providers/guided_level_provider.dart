import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphaflow/data/models/guided_track.dart';
import 'package:alphaflow/data/models/level_definition.dart';
import 'package:alphaflow/providers/selected_track_provider.dart';
import 'package:alphaflow/features/guided/providers/guided_tracks_provider.dart';
import 'package:alphaflow/providers/xp_provider.dart'; // For totalTrackXpProvider

final currentGuidedLevelProvider = Provider<LevelDefinition?>((ref) {
  final selectedTrackId = ref.watch(selectedTrackProvider);
  final allGuidedTracks = ref.watch(guidedTracksProvider);
  // totalTrackXpProvider calculates total XP for the currently selected track
  final totalAccumulatedXp = ref.watch(totalTrackXpProvider);

  if (selectedTrackId == null) {
    return null; // No track selected
  }

  GuidedTrack? currentTrack;
  try {
    currentTrack = allGuidedTracks.firstWhere((track) => track.id == selectedTrackId);
  } catch (e) {
    print("Error: Selected track with ID $selectedTrackId not found in currentGuidedLevelProvider. $e");
    return null; // Selected track not found
  }

  if (currentTrack.levels.isEmpty) {
    print("Warning: Selected track ${currentTrack.title} has no levels defined.");
    return null; // Track has no levels defined
  }

  // Assuming currentTrack.levels are sorted by xpThreshold in ascending order
  // (as they are in guided_tracks.dart).
  // Iterate from the highest defined level downwards.
  LevelDefinition? currentLevel = null;
  for (int i = currentTrack.levels.length - 1; i >= 0; i--) {
    final level = currentTrack.levels[i];
    if (totalAccumulatedXp >= level.xpThreshold) {
      currentLevel = level;
      break; // Found the highest level achieved
    }
  }

  // If after the loop, currentLevel is still null, it means totalAccumulatedXp is less than
  // the xpThreshold of all defined levels. This should only happen if the first level's
  // threshold is > 0 and user has less XP than that.
  // However, our data ensures the first level has xpThreshold: 0.
  // So, if currentTrack.levels is not empty, currentLevel should not be null here.
  // If it were possible for levels to not start at 0 XP, one might return currentTrack.levels.first
  // or null based on specific game logic for users below the first threshold.
  // For our case, the loop should suffice.

  return currentLevel;
});

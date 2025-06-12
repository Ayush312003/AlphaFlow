// features/guided/providers/guided_tracks_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/guided_task.dart'; // Moved to top
import '../../../data/models/guided_track.dart';
import '../../../data/models/level_definition.dart';
import '../data/guided_tracks.dart'; // Data source for guidedTracks

/// All guided tracks
final guidedTracksProvider = Provider<List<GuidedTrack>>((ref) => guidedTracks);

/// Get a track by ID
final guidedTrackByIdProvider = Provider.family<GuidedTrack?, String>((ref, trackId) {
  final tracks = ref.watch(guidedTracksProvider);
  try {
    return tracks.firstWhere((track) => track.id == trackId);
  } catch (e) {
    // If firstWhere throws (e.g., no element found and no orElse provided to it), return null.
    // This makes it behave like the previous orElse: () => null, but within a try-catch.
    print("Track with ID $trackId not found. Error: $e");
    return null;
  }
});

/// Get all levels of a track
final guidedLevelsProvider = Provider.family<List<LevelDefinition>, String>((ref, trackId) {
  final track = ref.watch(guidedTrackByIdProvider(trackId));
  // If track is null (not found), return an empty list of levels.
  return track?.levels ?? [];
});

/// Get unlockable tasks for a given track and level number
final unlockTasksProvider = Provider.family<List<GuidedTask>, (String trackId, int levelNumber)>((ref, args) {
  final (trackId, levelNum) = args;
  final levels = ref.watch(guidedLevelsProvider(trackId));

  // If levels list is empty and the track itself was not found,
  // it implies invalid trackId was passed or track has no levels.
  // No need to proceed further, return empty list of tasks.
  if (levels.isEmpty && ref.watch(guidedTrackByIdProvider(trackId)) == null) {
    print("Warning: Track $trackId not found or has no levels. Returning empty tasks for level $levelNum.");
    return [];
  }

  try {
    final levelData = levels.firstWhere(
      (lvl) => lvl.levelNumber == levelNum,
    );
    return levelData.unlockTasks; // Returns List<GuidedTask>
  } catch (e) {
    // This catch block handles cases where the level number itself is not found within a valid track.
    print("Warning: Level $levelNum not found for track $trackId. Error: $e. Returning empty tasks list.");
    return []; // Return empty list if level not found
  }
});

// features/guided/providers/guided_tracks_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/guided_tracks.dart';
import '../../../data/models/guided_track.dart'; // GuidedTrack
import '../../../data/models/level_definition.dart'; // LevelDefinition

/// All guided tracks
final guidedTracksProvider = Provider<List<GuidedTrack>>((ref) => guidedTracks);

/// Get a track by ID
final guidedTrackByIdProvider = Provider.family<GuidedTrack?, String>((ref, trackId) {
  return guidedTracks.firstWhere(
    (track) => track.id == trackId,
    orElse: () => null,
  );
});

/// Get all levels of a track
final guidedLevelsProvider = Provider.family<List<LevelDefinition>, String>((ref, trackId) {
  final track = ref.watch(guidedTrackByIdProvider(trackId));
  return track?.levels ?? [];
});

import '../../../data/models/guided_task.dart'; // Import GuidedTask

/// Get unlockable tasks for a given track and level number
final unlockTasksProvider = Provider.family<List<GuidedTask>, (String trackId, int levelNumber)>((ref, args) {
  final (trackId, levelNum) = args;
  final levels = ref.watch(guidedLevelsProvider(trackId));
  final levelData = levels.firstWhere(
    (lvl) => lvl.levelNumber == levelNum,
    orElse: () {
      // This orElse should ideally not be hit if UI logic is correct and only requests valid levels.
      // Returning an empty list of tasks if a level is somehow not found.
      print("Warning: Level $levelNum not found for track $trackId in unlockTasksProvider. Returning empty tasks list.");
      return LevelDefinition(levelNumber: 0, title: "Unknown Level", icon: "❓", xpThreshold: 0, unlockTasks: []);
    }
  );
  return levelData.unlockTasks; // Returns List<GuidedTask>
});

// features/guided/providers/guided_tracks_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphaflow/features/guided/data/guided_tracks_service.dart';
import 'package:alphaflow/data/models/guided_track.dart';

import '../../../data/models/guided_task.dart'; // Moved to top
import '../../../data/models/guided_track.dart';
import '../../../data/models/level_definition.dart';

/// Provider that loads guided tracks from the bundled JSON asset
final guidedTracksProvider = FutureProvider<List<GuidedTrack>>((ref) async {
  return await GuidedTracksService.loadGuidedTracks();
});

/// Provider for a specific guided track by ID
final guidedTrackByIdProvider = FutureProvider.family<GuidedTrack?, String>((ref, trackId) async {
  final tracks = await ref.watch(guidedTracksProvider.future);
  try {
    return tracks.firstWhere((track) => track.id == trackId);
  } catch (e) {
    return null;
  }
});

/// Get all levels of a track
final guidedLevelsProvider = FutureProvider.family<List<LevelDefinition>, String>((ref, trackId) async {
  final track = await ref.watch(guidedTrackByIdProvider(trackId).future);
  // If track is null (not found), return an empty list of levels.
  return track?.levels ?? [];
});

/// Get unlockable tasks for a given track and level number
final unlockTasksProvider = Provider.family<AsyncValue<List<GuidedTask>>, (String trackId, int levelNumber)>((ref, args) {
  final (trackId, levelNum) = args;
  final levelsAsync = ref.watch(guidedLevelsProvider(trackId));

  return levelsAsync.when(
    data: (levels) {
      if (levels.isEmpty) {
        print("Warning: Track $trackId not found or has no levels. Returning empty tasks for level $levelNum.");
        return const AsyncValue.data(<GuidedTask>[]);
      }
      try {
        final levelData = levels.firstWhere((lvl) => lvl.levelNumber == levelNum);
        return AsyncValue.data(levelData.unlockTasks);
      } catch (e) {
        print("Warning: Level $levelNum not found for track $trackId. Error: $e. Returning empty tasks list.");
        return const AsyncValue.data(<GuidedTask>[]);
      }
    },
    loading: () => const AsyncValue.loading(),
    error: (e, s) {
      print("Error loading levels for track $trackId: $e");
      return AsyncValue.error(e, s);
    },
  );
});

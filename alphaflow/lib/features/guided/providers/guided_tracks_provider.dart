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

/// Get unlockable task IDs for a given track and level
final unlockTasksProvider = Provider.family<List<String>, (String trackId, int level)>((ref, args) {
  final (trackId, level) = args;
  final levels = ref.watch(guidedLevelsProvider(trackId));
  final levelData = levels.firstWhere(
    (lvl) => lvl.level == level,
    orElse: () => LevelDefinition(level: 0, title: '', unlockTasks: []),
  );
  return levelData.unlockTasks;
});

import 'level_definition.dart';

/// A full guided track, comprising multiple levels.
class GuidedTrack {
  final String id;                         // e.g. "monk_mode"
  final String title;                      // "Monk Mode"
  final String description;                // short pitch
  final String theme;                      // for UI styling
  final List<LevelDefinition> levels;      // progression steps

  GuidedTrack({
    required this.id,
    required this.title,
    required this.description,
    required this.theme,
    required this.levels,
  });
}

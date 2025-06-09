import 'frequency.dart';

/// A single task in a guided track.
class GuidedTask {
  final String id; // unique across all tracks, e.g. "monk_no_social"
  final String title;
  final String description;
  final Frequency frequency; // daily, weekly, or oneTime
  final int xp; // xp gained when completed
  final int requiredLevel; // minimum LevelDefinition.levelNumber to unlock
  final int?
  dayOfWeek; // 1 for Monday, ..., 7 for Sunday. Null if not day-specific.

  GuidedTask({
    required this.id,
    required this.title,
    required this.description,
    required this.frequency,
    required this.xp,
    required this.requiredLevel,
    this.dayOfWeek, // Added new optional parameter
  });
}

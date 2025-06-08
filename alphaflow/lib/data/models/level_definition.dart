import 'guided_task.dart';

/// One step in the Greek-god progression ladder.
class LevelDefinition {
  final int levelNumber;      // 1,2,3…
  final String title;         // e.g. "Eros"
  final String icon;          // e.g. "❤️"
  final int xpThreshold;      // e.g. 100
  final List<GuidedTask> unlockTasks;

  LevelDefinition({
    required this.levelNumber,
    required this.title,
    required this.icon,
    required this.xpThreshold,
    this.unlockTasks = const [],
  });
}

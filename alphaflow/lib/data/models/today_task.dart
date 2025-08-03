import 'package:alphaflow/data/models/custom_task.dart';
import 'package:alphaflow/data/models/guided_task.dart';
import 'package:alphaflow/data/models/frequency.dart'; // For Frequency enum
import 'package:alphaflow/data/models/task_priority.dart';

// Enum to differentiate task types within TodayTask
enum TodayTaskType { guided, custom }

class TodayTask {
  final String id;
  final String title;
  final TodayTaskType type;
  final Frequency frequency; // Common field
  final bool isCompleted; // Calculated field for UI

  // Original task objects - useful for accessing type-specific properties
  final GuidedTask? guidedTask;
  final CustomTask? customTask;

  // Custom task specific fields (for convenience, could also be accessed via customTask object)
  final String? iconName;
  final int? colorValue;
  final TaskPriority? priority;
  // Streak count can also be added here if todayTasksProvider becomes responsible for that
  // For now, keep it separate, fetched by UI from CustomTaskStreaksProvider

  TodayTask({
    required this.id,
    required this.title,
    required this.type,
    required this.frequency,
    required this.isCompleted,
    this.guidedTask,
    this.customTask,
    this.iconName, // Specific to custom, but useful for direct access
    this.colorValue, // Specific to custom
    this.priority,
  }) {
    // Ensure that the correct original task object is provided based on the type
    assert(
      type == TodayTaskType.guided ? guidedTask != null : true,
      "GuidedTask must be provided for type TodayTaskType.guided",
    );
    assert(
      type == TodayTaskType.custom ? customTask != null : true,
      "CustomTask must be provided for type TodayTaskType.custom",
    );
    // Ensure icon/color are only provided for custom tasks if passed directly (though factory constructors manage this)
    // This assertion might be too strict if we ever wanted to assign a default icon/color to guided tasks at this wrapper level
    // assert(type == TodayTaskType.guided ? (iconName == null && colorValue == null) : true, "iconName and colorValue should only be set for Custom Tasks at the TodayTask wrapper level");
  }

  // Factory constructor for creating from a GuidedTask
  factory TodayTask.fromGuidedTask(GuidedTask task, bool isCompleted) {
    return TodayTask(
      id: task.id,
      title: task.title,
      type: TodayTaskType.guided,
      frequency: task.frequency,
      isCompleted: isCompleted,
      guidedTask: task,
      customTask: null,
      // No iconName or colorValue for guided tasks directly in TodayTask wrapper's direct fields
      // These would be null here and accessed via guidedTask object if ever needed by UI for guided (not typical).
      iconName: null,
      colorValue: null,
      priority: null,
    );
  }

  // Factory constructor for creating from a CustomTask
  factory TodayTask.fromCustomTask(CustomTask task, bool isCompleted) {
    return TodayTask(
      id: task.id,
      title: task.title,
      type: TodayTaskType.custom,
      frequency: task.frequency,
      isCompleted: isCompleted,
      guidedTask: null,
      customTask: task,
      iconName: task.iconName, // Pass through custom task's icon
      colorValue: task.colorValue, // Pass through custom task's color
      priority: task.priority,
    );
  }

  // Helper to get XP if it's a guided task
  int get xp {
    if (type == TodayTaskType.guided && guidedTask != null) {
      return guidedTask!.xp;
    }
    return 0;
  }
}

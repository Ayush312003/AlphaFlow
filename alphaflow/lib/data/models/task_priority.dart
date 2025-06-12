enum TaskPriority { none, low, medium, high }

extension TaskPriorityExtension on TaskPriority {
  String get displayName {
    switch (this) {
      case TaskPriority.none:
        return 'None';
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      default: // Should not happen
        return 'None';
    }
  }

  // Using .name for serialization (requires Dart 2.15+)
  // String toJson() => this.name; // This would be an alternative way
}

// Helper for robust deserialization from string
TaskPriority priorityFromString(String? value) {
  if (value == null) {
    return TaskPriority.none;
  }
  // Iterating through enum values to find a match by name
  // This is robust if a direct byName (Dart 2.15+) isn't used or as a fallback
  for (final priority in TaskPriority.values) {
    if (priority.name == value) {
      // .name requires Dart 2.15+
      return priority;
    }
  }
  // Fallback for older enum.toString() style if .name failed or wasn't used for saving
  // e.g., value might be "TaskPriority.low"
  for (final priority in TaskPriority.values) {
    if (priority.toString().split('.').last == value) {
      return priority;
    }
  }
  return TaskPriority.none; // Default if no match
}

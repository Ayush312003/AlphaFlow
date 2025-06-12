enum TargetType {
  none,
  numeric,
  // Future types like boolean, counter can be added later
}

// Helper for TargetType serialization using .name (Dart 2.15+)
String targetTypeToString(TargetType type) {
  return type.name;
}

// Helper for TargetType deserialization, robust to unknown or null values
TargetType targetTypeFromString(String? value) {
  if (value == null) return TargetType.none;
  for (final type in TargetType.values) {
    if (type.name == value) {
      // Assumes value is saved as enum.name
      return type;
    }
    // Fallback for older enum.toString() format
    if (type.toString().split('.').last == value) {
      return type;
    }
  }
  return TargetType.none; // Default if no match
}

class TaskTarget {
  final TargetType type;
  final double targetValue; // e.g., 100 (pages), 5 (km), 30 (minutes)
  final double currentValue; // e.g., 20 (pages), 2 (km), 10 (minutes)
  final String? unit; // e.g., "pages", "km", "minutes", "times" - optional

  TaskTarget({
    this.type = TargetType.none,
    this.targetValue = 0.0, // Sensible default, can be overridden
    this.currentValue = 0.0,
    this.unit,
  });

  TaskTarget copyWith({
    TargetType? type,
    double? targetValue,
    double? currentValue,
    String? unit,
    bool clearUnit = false, // Flag to explicitly set unit to null
  }) {
    return TaskTarget(
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      unit:
          clearUnit
              ? null
              : (unit ?? this.unit), // Handle clearing or updating unit
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'type': targetTypeToString(type),
      'targetValue': targetValue,
      'currentValue': currentValue,
    };
    if (unit != null && unit!.isNotEmpty) {
      // Only include unit if it's not null or empty
      json['unit'] = unit;
    }
    return json;
  }

  factory TaskTarget.fromJson(Map<String, dynamic> json) {
    return TaskTarget(
      type: targetTypeFromString(json['type'] as String?),
      // Ensure robust parsing for doubles, defaulting to 0.0
      targetValue: (json['targetValue'] as num?)?.toDouble() ?? 0.0,
      currentValue: (json['currentValue'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String?, // Unit can be null
    );
  }

  @override
  String toString() {
    return 'TaskTarget(type: $type, targetValue: $targetValue, currentValue: $currentValue, unit: $unit)';
  }
}

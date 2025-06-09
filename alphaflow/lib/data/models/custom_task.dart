import 'frequency.dart';
import 'task_priority.dart';

/// A user-created task in Custom mode (flat list).
class CustomTask {
  final String id;
  final String title;
  final String description;
  final Frequency frequency; // daily, weekly, or oneTime
  final String? iconName; // New field
  final int? colorValue; // New field
  final DateTime? dueDate;
  final String? notes;
  final TaskPriority priority;

  CustomTask({
    required this.id,
    required this.title,
    required this.description,
    required this.frequency,
    this.iconName, // Optional in constructor
    this.colorValue, // Optional in constructor
    this.dueDate,
    this.notes,
    this.priority = TaskPriority.none,
  });

  /// For persistence to JSON
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'frequency': frequency.toShortString(),
    };
    if (iconName != null) {
      json['iconName'] = iconName;
    }
    if (colorValue != null) {
      json['colorValue'] = colorValue;
    }
    if (dueDate != null) {
      json['dueDate'] = dueDate!.toIso8601String();
    }
    if (notes != null) {
      json['notes'] = notes;
    }
    json['priority'] = priority.name;
    return json;
  }

  static CustomTask fromJson(Map<String, dynamic> json) {
    return CustomTask(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      frequency: Frequency.fromString(json['frequency'] as String),
      iconName: json['iconName'] as String?,
      colorValue: json['colorValue'] as int?,
      dueDate:
          json['dueDate'] == null
              ? null
              : DateTime.tryParse(json['dueDate'] as String),
      notes: json['notes'] as String?,
      priority: priorityFromString(json['priority'] as String?),
    );
  }

  CustomTask copyWith({
    String? id,
    String? title,
    String? description,
    Frequency? frequency,
    String? iconName,
    int? colorValue,
    DateTime? dueDate,
    String? notes,
    TaskPriority? priority,
    bool clearIconName = false,
    bool clearColorValue = false,
    bool clearDueDate = false,
    bool clearNotes = false,
  }) {
    return CustomTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      iconName: clearIconName ? null : iconName ?? this.iconName,
      colorValue: clearColorValue ? null : colorValue ?? this.colorValue,
      dueDate: clearDueDate ? null : dueDate ?? this.dueDate,
      notes: clearNotes ? null : notes ?? this.notes,
      priority: priority ?? this.priority,
    );
  }
}

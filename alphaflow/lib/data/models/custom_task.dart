import 'frequency.dart';

/// A user-created task in Custom mode (flat list).
class CustomTask {
  final String id;              
  final String title;
  final String description;
  final Frequency frequency;    // daily, weekly, or oneTime
  final String? iconName;   // New field
  final int? colorValue;    // New field

  CustomTask({
    required this.id,
    required this.title,
    required this.description,
    required this.frequency,
    this.iconName,         // Optional in constructor
    this.colorValue,       // Optional in constructor
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
    );
  }

  CustomTask copyWith({
    String? id,
    String? title,
    String? description,
    Frequency? frequency,
    String? iconName,
    int? colorValue,
    bool clearIconName = false,
    bool clearColorValue = false,
  }) {
    return CustomTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      iconName: clearIconName ? null : iconName ?? this.iconName,
      colorValue: clearColorValue ? null : colorValue ?? this.colorValue,
    );
  }
}

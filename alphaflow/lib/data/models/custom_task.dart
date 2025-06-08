import 'frequency.dart';

/// A user-created task in Custom mode (flat list).
class CustomTask {
  final String id;              
  final String title;
  final String description;
  final Frequency frequency;    // daily, weekly, or oneTime

  CustomTask({
    required this.id,
    required this.title,
    required this.description,
    required this.frequency,
  });

  /// For persistence to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'frequency': frequency.toShortString(),
      };

  static CustomTask fromJson(Map<String, dynamic> json) {
    return CustomTask(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      frequency: Frequency.fromString(json['frequency'] as String),
    );
  }
}

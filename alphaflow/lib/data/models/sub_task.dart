import 'package:uuid/uuid.dart';

var _uuid = Uuid();

class SubTask {
  final String id;
  final String title;
  final bool isCompleted;

  SubTask({String? id, required this.title, this.isCompleted = false})
    : this.id = id ?? _uuid.v4();

  SubTask copyWith({String? id, String? title, bool? isCompleted}) {
    return SubTask(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'isCompleted': isCompleted};
  }

  factory SubTask.fromJson(Map<String, dynamic> json) {
    return SubTask(
      id: json['id'] as String,
      title: json['title'] as String,
      // Ensure isCompleted defaults to false if null or not a bool for robustness
      isCompleted:
          (json['isCompleted'] is bool) ? json['isCompleted'] as bool : false,
    );
  }

  // Optional: For debugging or simple display
  @override
  String toString() {
    return 'SubTask(id: $id, title: "$title", isCompleted: $isCompleted)';
  }
}

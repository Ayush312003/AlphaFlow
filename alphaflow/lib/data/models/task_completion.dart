import 'package:cloud_firestore/cloud_firestore.dart'; // Import for Timestamp

/// Records a user having completed a task on a given date.
class TaskCompletion {
  final String taskId;      // id of GuidedTask or CustomTask
  final DateTime date;      // normalized to midnight UTC
  final String? trackId;    // guidedTrack.id if guided, null if custom
  final int xpAwarded;      // XP value of the task at the time of completion

  TaskCompletion({
    required this.taskId,
    required this.date,
    this.trackId,
    required this.xpAwarded, // Added to constructor
  });

  /// Converts to JSON format for Firestore.
  /// Date is stored as a Firestore Timestamp.
  Map<String, dynamic> toJson() => {
        'taskId': taskId,
        'date': Timestamp.fromDate(date), // Store as Firestore Timestamp
        'trackId': trackId,
        'xpAwarded': xpAwarded,
      };

  /// Creates a TaskCompletion instance from Firestore JSON data.
  /// Expects 'date' to be a Firestore Timestamp.
  static TaskCompletion fromJson(Map<String, dynamic> json) {
    return TaskCompletion(
      taskId: json['taskId'] as String,
      // Firestore 'date' will be a Timestamp, convert to DateTime
      // Ensure date is treated as UTC after conversion if it was stored as UTC midnight
      date: (json['date'] as Timestamp).toDate(),
      trackId: json['trackId'] as String?,
      // Provide a default for xpAwarded if it's missing from older documents
      xpAwarded: json['xpAwarded'] as int? ?? 0,
    );
  }
}

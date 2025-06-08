/// Records a user having completed a task on a given date.
class TaskCompletion {
  final String taskId;      // id of GuidedTask or CustomTask
  final DateTime date;      // normalized to midnight UTC/local
  final String? trackId;    // guidedTrack.id if guided, null if custom

  TaskCompletion({
    required this.taskId,
    required this.date,
    this.trackId,
  });

  /// JSON for local storage
  Map<String, dynamic> toJson() => {
        'taskId': taskId,
        'date': date.toIso8601String(),
        'trackId': trackId,
      };

  static TaskCompletion fromJson(Map<String, dynamic> json) {
    return TaskCompletion(
      taskId: json['taskId'] as String,
      date: DateTime.parse(json['date'] as String),
      trackId: json['trackId'] as String?,
    );
  }
}

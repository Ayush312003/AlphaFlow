/// The repeat cadence of a task.
enum Frequency {
  daily,
  weekly,
  oneTime;

  /// Parse from stored string.
  static Frequency fromString(String s) {
    return Frequency.values.firstWhere((f) => f.toString() == 'Frequency.$s');
  }

  String toShortString() {
    return toString().split('.').last;
  }
}

/// Represents which mode the user has chosen.
enum AppMode {
  guided,
  custom;

  /// Convert from string (e.g. SharedPreferences)
  static AppMode? fromString(String? s) {
    if (s == 'guided') return AppMode.guided;
    if (s == 'custom') return AppMode.custom;
    return null;
  }

  String toShortString() {
    return toString().split('.').last;
  }
}

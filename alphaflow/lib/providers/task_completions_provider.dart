import 'package:alphaflow/data/local/preferences_service.dart';
import 'package:alphaflow/data/models/task_completion.dart';
import 'package:alphaflow/providers/app_mode_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CompletionListNotifier extends StateNotifier<List<TaskCompletion>> {
  final PreferencesService _prefsService;

  CompletionListNotifier(this._prefsService) : super([]) {
    _loadCompletions();
  }

  void _loadCompletions() {
    state = _prefsService.loadCompletions();
  }

  /// Adds a completion record if not already present for that task on that date.
  /// Removes it if it is present (toggles completion).
  /// Normalizes date to midnight UTC to ensure date-based uniqueness.
  Future<void> toggleTaskCompletion(
    String taskId,
    DateTime date, {
    String? trackId,
  }) async {
    final normalizedDate = DateTime.utc(date.year, date.month, date.day);

    final existingCompletionIndex = state.indexWhere(
      (c) => c.taskId == taskId && c.date == normalizedDate,
    );

    if (existingCompletionIndex != -1) {
      // Completion exists, so remove it
      state = List.from(state)..removeAt(existingCompletionIndex);
    } else {
      // Completion does not exist, so add it
      final newCompletion = TaskCompletion(
        taskId: taskId,
        date: normalizedDate,
        trackId: trackId, // trackId is null for custom tasks
      );
      state = [...state, newCompletion];
    }
    await _prefsService.saveCompletions(state);
  }

  /// Checks if a specific task was completed on a given date.
  /// Normalizes date to midnight UTC.
  bool isTaskCompletedOnDate(String taskId, DateTime date) {
    final normalizedDate = DateTime.utc(date.year, date.month, date.day);
    return state.any((c) => c.taskId == taskId && c.date == normalizedDate);
  }

  /// Gets all completions for a specific date.
  /// Normalizes date to midnight UTC.
  List<TaskCompletion> getCompletionsForDate(DateTime date) {
    final normalizedDate = DateTime.utc(date.year, date.month, date.day);
    return state.where((c) => c.date == normalizedDate).toList();
  }

  /// Gets all completions for a specific task.
  List<TaskCompletion> getCompletionsForTask(String taskId) {
    return state.where((c) => c.taskId == taskId).toList();
  }

  Future<void> clearGuidedTaskCompletions() async {
    // Filter out completions that have a non-null trackId
    // These are considered guided task completions.
    final List<TaskCompletion> customCompletionsOnly =
        state.where((completion) => completion.trackId == null).toList();
    state = customCompletionsOnly;
    await _prefsService.saveCompletions(state);
  }

  // Method to clear all completions (optional, could be useful for debugging/reset)
  // Future<void> clearAllCompletions() async {
  //   state = [];
  //   await _prefsService.saveCompletions(state);
  // }
}

final completionsProvider =
    StateNotifierProvider<CompletionListNotifier, List<TaskCompletion>>((ref) {
      final prefsService = ref.watch(preferencesServiceProvider);
      return CompletionListNotifier(prefsService);
    });

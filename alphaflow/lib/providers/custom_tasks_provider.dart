import 'package:alphaflow/data/local/preferences_service.dart';
import 'package:alphaflow/data/models/custom_task.dart';
import 'package:alphaflow/data/models/frequency.dart';
import 'package:alphaflow/data/models/task_priority.dart';
import 'package:alphaflow/data/models/sub_task.dart';
import 'package:alphaflow/data/models/task_target.dart'; // Added import
import 'package:alphaflow/providers/app_mode_provider.dart';
import 'package:alphaflow/data/services/widget_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

var _uuid = Uuid();

class CustomTaskListNotifier extends StateNotifier<List<CustomTask>> {
  final PreferencesService _prefsService;

  CustomTaskListNotifier(this._prefsService) : super([]) {
    _loadTasks();
  }

  void _loadTasks() {
    state = _prefsService.loadCustomTasks();
  }

  Future<void> addTask({
    required String title,
    required String description,
    required Frequency frequency,
    String? iconName,
    int? colorValue,
    DateTime? dueDate,
    String? notes,
    TaskPriority priority = TaskPriority.none,
    List<SubTask>? subTasks,
    TaskTarget? taskTarget, // Added
  }) async {
    final newTask = CustomTask(
      id: _uuid.v4(), // Generate a unique ID
      title: title,
      description: description,
      frequency: frequency,
      iconName: iconName,
      colorValue: colorValue,
      dueDate: dueDate,
      notes: notes,
      priority: priority,
      subTasks: subTasks ?? const [],
      taskTarget: taskTarget, // Added
    );
    state = [...state, newTask];
    await _prefsService.saveCustomTasks(state);
    await WidgetService.updateWidget(); // Notify widget to update
  }

  Future<void> updateTask(CustomTask updatedTask) async {
    state = [
      for (final task in state)
        if (task.id == updatedTask.id) updatedTask else task,
    ];
    await _prefsService.saveCustomTasks(state);
    await WidgetService.updateWidget(); // Notify widget to update
  }

  Future<void> deleteTask(String taskId) async {
    state = state.where((task) => task.id != taskId).toList();
    await _prefsService.saveCustomTasks(state);
    await WidgetService.updateWidget(); // Notify widget to update
  }

  Future<void> toggleSubTaskCompletion(
    String parentTaskId,
    String subTaskId,
    bool newCompletionStatus,
  ) async {
    state =
        state.map((task) {
          // Using map to create a new list for state update
          if (task.id == parentTaskId) {
            return task.copyWith(
              subTasks:
                  task.subTasks.map((st) {
                    if (st.id == subTaskId) {
                      return st.copyWith(isCompleted: newCompletionStatus);
                    }
                    return st;
                  }).toList(),
            );
          }
          return task;
        }).toList();
    await _prefsService.saveCustomTasks(state);
    await WidgetService.updateWidget(); // Notify widget to update
  }

  Future<void> updateTaskTargetProgress(
    String taskId,
    double newCurrentValue,
  ) async {
    state =
        state.map((task) {
          if (task.id == taskId) {
            // Ensure the task has a target and it's numeric before attempting to update
            if (task.taskTarget != null &&
                task.taskTarget!.type == TargetType.numeric) {
              // Clamp newCurrentValue to be non-negative.
              // The targetValue acts as the max for progress display, but currentValue can exceed it.
              final checkedNewCurrentValue =
                  newCurrentValue < 0 ? 0.0 : newCurrentValue;

              return task.copyWith(
                taskTarget: task.taskTarget!.copyWith(
                  currentValue: checkedNewCurrentValue,
                ),
              );
            }
            // If the task doesn't have a numeric target, or no target at all,
            // return it unchanged. This situation should ideally be prevented by the UI.
            return task;
          }
          return task;
        }).toList();
    await _prefsService.saveCustomTasks(state);
    await WidgetService.updateWidget(); // Notify widget to update
  }

  // Optional: Method to reorder tasks if needed in the future
  // Future<void> reorderTask(int oldIndex, int newIndex) async {
  //   if (oldIndex < newIndex) {
  //     newIndex -= 1;
  //   }
  //   final task = state.removeAt(oldIndex);
  //   state.insert(newIndex, task);
  //   await _prefsService.saveCustomTasks(state);
  // }
}

final customTasksProvider =
    StateNotifierProvider<CustomTaskListNotifier, List<CustomTask>>((ref) {
      final prefsService = ref.watch(preferencesServiceProvider);
      return CustomTaskListNotifier(prefsService);
    });

// New provider for sorted tasks - optimizes performance by moving sorting outside build method
final sortedCustomTasksProvider = Provider<List<CustomTask>>((ref) {
  final allTasks = ref.watch(customTasksProvider);
  
  // Sort tasks by priority: high > medium > low > none
  final sortedTasks = List<CustomTask>.from(allTasks);
  sortedTasks.sort((a, b) {
    int priorityValue(TaskPriority p) {
      switch (p) {
        case TaskPriority.high:
          return 3;
        case TaskPriority.medium:
          return 2;
        case TaskPriority.low:
          return 1;
        case TaskPriority.none:
        default:
          return 0;
      }
    }
    return priorityValue(b.priority).compareTo(priorityValue(a.priority));
  });
  
  return sortedTasks;
});

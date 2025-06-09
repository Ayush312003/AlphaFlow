import 'package:alphaflow/data/local/preferences_service.dart';
import 'package:alphaflow/data/models/custom_task.dart';
import 'package:alphaflow/data/models/frequency.dart';
import 'package:alphaflow/data/models/task_priority.dart';
import 'package:alphaflow/data/models/sub_task.dart'; // Added import
import 'package:alphaflow/providers/app_mode_provider.dart';
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
    List<SubTask>? subTasks, // Added
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
      subTasks:
          subTasks ??
          const [], // Use ?? const [] to align with CustomTask constructor
    );
    state = [...state, newTask];
    await _prefsService.saveCustomTasks(state);
  }

  Future<void> updateTask(CustomTask updatedTask) async {
    state = [
      for (final task in state)
        if (task.id == updatedTask.id) updatedTask else task,
    ];
    await _prefsService.saveCustomTasks(state);
  }

  Future<void> deleteTask(String taskId) async {
    state = state.where((task) => task.id != taskId).toList();
    await _prefsService.saveCustomTasks(state);
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

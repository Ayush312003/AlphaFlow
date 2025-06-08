import 'package:alphaflow/data/models/custom_task.dart';
import 'package:alphaflow/data/models/frequency.dart';
import 'package:alphaflow/providers/custom_tasks_provider.dart';
import 'package:alphaflow/providers/task_completions_provider.dart';
import 'package:alphaflow/providers/custom_task_streaks_provider.dart'; // Added import
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Duplicated from TaskEditorPage for now, consider moving to a shared utility
final Map<String, IconData> _customTaskIcons = {
  'task_alt': Icons.task_alt,
  'star': Icons.star_border_purple500_outlined,
  'flag': Icons.flag_outlined,
  'fitness': Icons.fitness_center_outlined,
  'book': Icons.book_outlined,
  'work': Icons.work_outline,
  'home': Icons.home_outlined,
  'palette': Icons.palette_outlined,
};

class CustomHomePage extends ConsumerWidget {
  const CustomHomePage({super.key});

  Future<void> _showDeleteConfirmationDialog(BuildContext context, WidgetRef ref, CustomTask task) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Task?'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete "${task.title}"?'),
                const Text('This action cannot be undone.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
              child: const Text('Delete'),
              onPressed: () {
                ref.read(customTasksProvider.notifier).deleteTask(task.id);
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('"${task.title}" deleted.'), duration: const Duration(seconds: 2)),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customTasks = ref.watch(customTasksProvider);
    ref.watch(completionsProvider);
    final streaksMap = ref.watch(customTaskStreaksProvider); // Watch streaks provider

    final fab = FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/task_editor');
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Task',
      );

    if (customTasks.isEmpty) {
      return Scaffold( // No AppBar here
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.list_alt_rounded, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 20),
                Text(
                  "No Custom Tasks Yet",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Tap the '+' button to add your first task and start organizing your goals!",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: fab,
      );
    }

    return Scaffold( // No AppBar here
      body: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: customTasks.length,
              itemBuilder: (context, index) {
                final task = customTasks[index];
                final isCompleted = ref.read(completionsProvider.notifier).isTaskCompletedOnDate(task.id, DateTime.now());

                final IconData? taskIconData = task.iconName == null ? null : _customTaskIcons[task.iconName!];
                final Color? taskColor = task.colorValue == null ? null : Color(task.colorValue!);

                final Color activeColor = taskColor ?? Theme.of(context).colorScheme.primary;
                final Color iconDisplayColor = taskColor ?? Theme.of(context).iconTheme.color ?? Colors.grey.shade700;

                final TaskStreakInfo? streakInfo = streaksMap[task.id];
                Widget? streakDisplayWidget;
                if (streakInfo != null && streakInfo.streakCount > 0) {
                  String frequencyText = streakInfo.frequency == Frequency.daily ? "day" : "week";
                  if (streakInfo.streakCount > 1) frequencyText += "s";

                  streakDisplayWidget = Text(
                    "🔥 ${streakInfo.streakCount} $frequencyText streak!",
                    style: TextStyle(
                      color: Colors.orange.shade800, // Darker orange for better contrast
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                  elevation: isCompleted ? 1.0 : 3.0,
                  color: isCompleted ? (taskColor?.withOpacity(0.08) ?? Colors.green.withOpacity(0.05)) : (taskColor?.withOpacity(0.15) ?? Theme.of(context).cardColor),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: isCompleted ? (activeColor.withOpacity(0.5)) : (taskColor ?? Colors.transparent),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    leading: taskIconData != null
                        ? Icon(taskIconData, color: isCompleted ? iconDisplayColor.withOpacity(0.5) : iconDisplayColor, size: 28)
                        : const SizedBox(width: 28, height: 28),
                    title: Text(
                      task.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                        color: isCompleted ? Theme.of(context).textTheme.bodySmall?.color : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    subtitle: (task.description.isEmpty && streakDisplayWidget == null)
                        ? null
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (task.description.isNotEmpty)
                                Text(
                                  task.description,
                                  style: TextStyle(
                                    color: isCompleted ? Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7) : Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                ),
                              if (task.description.isNotEmpty && streakDisplayWidget != null)
                                const SizedBox(height: 4),
                              if (streakDisplayWidget != null)
                                streakDisplayWidget,
                            ],
                          ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          task.frequency.toShortString(),
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                            color: isCompleted ? Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7) : Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(width: 0),
                        Checkbox(
                          value: isCompleted,
                          activeColor: activeColor,
                          visualDensity: VisualDensity.compact,
                          onChanged: (bool? newValue) {
                             if (newValue != null) {
                                ref.read(completionsProvider.notifier).toggleTaskCompletion(
                                      task.id,
                                      DateTime.now(),
                                      trackId: null,
                                    );
                              }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          iconSize: 22.0,
                          visualDensity: VisualDensity.compact,
                          color: Theme.of(context).colorScheme.primary,
                          tooltip: 'Edit Task',
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/task_editor',
                              arguments: task,
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          iconSize: 22.0,
                          visualDensity: VisualDensity.compact,
                          color: Colors.red.shade700,
                          tooltip: 'Delete Task',
                          onPressed: () {
                            _showDeleteConfirmationDialog(context, ref, task);
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                        ref.read(completionsProvider.notifier).toggleTaskCompletion(
                            task.id,
                            DateTime.now(),
                            trackId: null,
                        );
                    },
                    onLongPress: () {
                         Navigator.pushNamed(context, '/task_editor', arguments: task);
                    },
                  ),
                );
              },
            ),
      floatingActionButton: fab,
    );
  }
}

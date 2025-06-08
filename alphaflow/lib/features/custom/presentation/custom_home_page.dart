import 'package:alphaflow/data/models/custom_task.dart';
import 'package:alphaflow/data/models/frequency.dart';
import 'package:alphaflow/providers/custom_tasks_provider.dart';
import 'package:alphaflow/providers/task_completions_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    final fab = FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/task_editor');
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Task',
      );

    if (customTasks.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Custom Tasks")),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text("Custom Tasks"),
      ),
      body: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: customTasks.length,
              itemBuilder: (context, index) {
                final task = customTasks[index];
                final isCompleted = ref.read(completionsProvider.notifier).isTaskCompletedOnDate(task.id, DateTime.now());

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                  elevation: isCompleted ? 1.0 : 3.0,
                  color: isCompleted ? Colors.green.withOpacity(0.05) : Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: isCompleted
                          ? BorderSide(color: Colors.green.withOpacity(0.3), width: 1)
                          : BorderSide.none,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    leading: Checkbox(
                      value: isCompleted,
                      activeColor: Colors.green,
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
                    title: Text(
                      task.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                        color: isCompleted ? Theme.of(context).textTheme.bodySmall?.color : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        task.description,
                        style: TextStyle(
                          color: isCompleted ? Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7) : Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          task.frequency.toShortString(),
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                            color: isCompleted ? Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7) : Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                        const SizedBox(width: 4), // Reduced space
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          iconSize: 22.0, // Slightly smaller icon
                          color: Theme.of(context).colorScheme.primary,
                          tooltip: 'Edit Task',
                          visualDensity: VisualDensity.compact, // Compact density
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
                          iconSize: 22.0, // Slightly smaller icon
                          color: Colors.red.shade700,
                          tooltip: 'Delete Task',
                          visualDensity: VisualDensity.compact, // Compact density
                          onPressed: () {
                            _showDeleteConfirmationDialog(context, ref, task);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: fab,
    );
  }
}

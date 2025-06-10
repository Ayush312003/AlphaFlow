import 'package:alphaflow/data/models/custom_task.dart';
import 'package:alphaflow/data/models/frequency.dart';
import 'package:alphaflow/providers/custom_tasks_provider.dart'; // Still needed for _showDeleteConfirmationDialog and edit arguments
import 'package:alphaflow/providers/task_completions_provider.dart';
import 'package:alphaflow/providers/custom_task_streaks_provider.dart';
import 'package:alphaflow/data/models/streak_info.dart'; // Added import for TaskStreakInfo
import 'package:alphaflow/providers/today_tasks_provider.dart'; // Added import
import 'package:alphaflow/data/models/today_task.dart'; // Added import
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:alphaflow/data/models/task_priority.dart';
import 'package:alphaflow/data/models/sub_task.dart';
import 'package:alphaflow/data/models/task_target.dart'; // Added import

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

  // _showDeleteConfirmationDialog still needs a CustomTask object
  Future<void> _showDeleteConfirmationDialog(
    BuildContext context,
    WidgetRef ref,
    CustomTask task,
  ) async {
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
                // Use the original task's ID for deletion
                ref.read(customTasksProvider.notifier).deleteTask(task.id);
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"${task.title}" deleted.'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showNotesDialog(
    BuildContext context,
    String taskTitle,
    String notesContent,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(taskTitle), // Using task title for context
          content: SingleChildScrollView(child: Text(notesContent)),
          contentPadding: const EdgeInsets.all(
            24.0,
          ), // Ensure good padding for content
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showUpdateTargetProgressDialog(
    BuildContext context,
    WidgetRef ref,
    CustomTask task,
  ) {
    final TextEditingController progressController = TextEditingController(
      text:
          task.taskTarget?.currentValue.toStringAsFixed(0) ??
          '0', // Or more precise formatting
    );
    final formKey = GlobalKey<FormState>(); // For validation

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Update Progress for "${task.title}"'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: progressController,
              decoration: InputDecoration(
                labelText: 'Current Progress (${task.taskTarget?.unit ?? ""})',
                hintText: 'Enter current progress',
                border: const OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a value';
                }
                final number = double.tryParse(value);
                if (number == null) {
                  return 'Please enter a valid number';
                }
                if (number < 0) {
                  return 'Progress cannot be negative';
                }
                // Optionally, validate against targetValue if needed, e.g., number > task.taskTarget!.targetValue
                // For now, allow exceeding target.
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Update'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newCurrentValue = double.parse(
                    progressController.text.trim(),
                  );
                  ref
                      .read(customTasksProvider.notifier)
                      .updateTaskTargetProgress(task.id, newCurrentValue);
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    ).then(
      (_) => progressController.dispose(),
    ); // Dispose controller when dialog is dismissed
  }

  void _showSubTasksDialog(
    BuildContext context,
    String taskTitle,
    List<SubTask> subTasks,
    WidgetRef ref,
    String parentTaskId,
  ) {
    // parentTaskId and ref are included for potential future interactivity, not used in this read-only version.
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Sub-tasks for "$taskTitle"'),
          content: Consumer(
            builder: (context, consumerRef, child) {
              final allTasks = consumerRef.watch(customTasksProvider);
              List<SubTask> displaySubTasksToShow =
                  subTasks; // Default to initially passed subTasks

              try {
                // Find the most up-to-date version of the parent task
                final currentParentTask = allTasks.firstWhere(
                  (task) => task.id == parentTaskId,
                );
                displaySubTasksToShow = currentParentTask.subTasks;
              } catch (e) {
                // Parent task not found (e.g., deleted while dialog is open).
                // Dialog will show initial subtasks, but they won't update further.
                // Or, we can return an error message widget here:
                // return const Center(child: Text("Parent task data is no longer available."));
                // For now, let it use the initial 'subTasks' list if parent is gone, to avoid crashing dialog.
              }

              return SizedBox(
                width: double.maxFinite, // Ensure dialog uses available width
                height:
                    MediaQuery.of(context).size.height *
                    0.4, // Set a max height for the content area
                child:
                    displaySubTasksToShow.isEmpty
                        ? const Center(
                          child: Text('No sub-tasks for this task.'),
                        )
                        : ListView.builder(
                          shrinkWrap:
                              true, // Important when ListView is in a constrained SizedBox
                          itemCount: displaySubTasksToShow.length,
                          itemBuilder: (BuildContext context, int index) {
                            final subTask = displaySubTasksToShow[index];
                            return ListTile(
                              dense: true,
                              leading: Checkbox(
                                value: subTask.isCompleted,
                                onChanged: (bool? newValue) {
                                  if (newValue != null) {
                                    // Use the original 'ref' from _showSubTasksDialog parameters
                                    ref
                                        .read(customTasksProvider.notifier)
                                        .toggleSubTaskCompletion(
                                          parentTaskId,
                                          subTask.id,
                                          newValue,
                                        );
                                  }
                                },
                                visualDensity: VisualDensity.compact,
                                // activeColor: Theme.of(context).colorScheme.primary, // Using default active color
                              ),
                              title: Text(
                                subTask.title,
                                softWrap: true, // Added for title wrapping
                                style: TextStyle(
                                  decoration:
                                      subTask.isCompleted
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                  color:
                                      subTask.isCompleted
                                          ? Theme.of(context)
                                              .disabledColor // Dim completed text
                                          : Theme.of(
                                            context,
                                          ).textTheme.bodyLarge?.color,
                                ),
                              ),
                            );
                          },
                        ),
              );
            },
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            20.0,
            20.0,
            20.0,
            0,
          ), // Adjust padding around content
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use todayTasksProvider for the list of tasks to display
    final List<TodayTask> tasksForDisplay = ref.watch(todayTasksProvider);
    ref.watch(completionsProvider);
    final streaksMap = ref.watch(customTaskStreaksProvider);

    final fab = FloatingActionButton(
      onPressed: () {
        Navigator.pushNamed(context, '/task_editor');
      },
      child: const Icon(Icons.add),
      tooltip: 'Add Task',
    );

    if (tasksForDisplay.isEmpty) {
      // Updated to check tasksForDisplay
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.list_alt_rounded,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 20),
                Text(
                  "No Custom Tasks Yet",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Tap the '+' button to add your first task and start organizing your goals!",
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
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
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemCount: tasksForDisplay.length, // Updated to tasksForDisplay
        itemBuilder: (context, index) {
          final todayTask = tasksForDisplay[index];
          final DateTime now = DateTime.now();
          final DateTime todayDateOnly = DateTime(now.year, now.month, now.day);

          // Access the original CustomTask for actions requiring it (edit, delete)
          // and for properties not directly on TodayTask if any were missed (shouldn't be for display)
          final CustomTask? task = todayTask.customTask;

          if (task == null) {
            // This should not happen if todayTask.type is custom and factories are correct
            return const SizedBox.shrink();
          }

          // Use todayTask.isCompleted for styling and checkbox state
          final isCompleted = todayTask.isCompleted;
          final TaskPriority priority = task.priority;

          Widget? priorityIndicatorWidget;
          if (priority == TaskPriority.high) {
            priorityIndicatorWidget = Icon(
              Icons.priority_high_rounded,
              color: Colors.red.shade700,
              size: 24,
            );
          } else if (priority == TaskPriority.medium) {
            priorityIndicatorWidget = Icon(
              Icons.flag_rounded,
              color: Colors.orange.shade700,
              size: 24,
            );
          } else if (priority == TaskPriority.low) {
            priorityIndicatorWidget = Icon(
              Icons.low_priority_rounded,
              color: Colors.blue.shade700,
              size: 24,
            );
          }

          final IconData? taskIconData =
              todayTask.iconName == null
                  ? null
                  : _customTaskIcons[todayTask.iconName!];
          final Color? taskColor =
              todayTask.colorValue == null
                  ? null
                  : Color(todayTask.colorValue!);

          final Color activeColor =
              taskColor ?? Theme.of(context).colorScheme.primary;
          final Color iconDisplayColor =
              taskColor ??
              Theme.of(context).iconTheme.color ??
              Colors.grey.shade700;

          List<Widget> leadingWidgets = [];
          if (priorityIndicatorWidget != null) {
            leadingWidgets.add(priorityIndicatorWidget);
          }

          if (taskIconData != null) {
            if (leadingWidgets.isNotEmpty) {
              leadingWidgets.add(
                const SizedBox(width: 8),
              ); // Space between priority and task icon
            }
            leadingWidgets.add(
              Icon(
                taskIconData,
                color:
                    isCompleted
                        ? iconDisplayColor.withOpacity(0.5)
                        : iconDisplayColor,
                size: 28,
              ),
            );
          }

          Widget? finalLeadingWidget;
          if (leadingWidgets.isNotEmpty) {
            finalLeadingWidget = Row(
              mainAxisSize: MainAxisSize.min,
              children: leadingWidgets,
            );
          } else {
            // Placeholder to maintain alignment if no icons at all
            finalLeadingWidget = const SizedBox(width: 28, height: 28);
          }

          final TaskStreakInfo? streakInfo =
              streaksMap[todayTask.id]; // Use todayTask.id for streaks
          Widget? streakDisplayWidget;
          if (streakInfo != null && streakInfo.streakCount > 0) {
            String frequencyText =
                streakInfo.frequency == Frequency.daily ? "day" : "week";
            if (streakInfo.streakCount > 1) frequencyText += "s";

            streakDisplayWidget = Text(
              "🔥 ${streakInfo.streakCount} $frequencyText streak!",
              style: TextStyle(
                color: Colors.orange.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            );
          }

          Widget? dueDateWidget;
          if (task.dueDate != null) {
            final String formattedDate = DateFormat.yMMMd().format(
              task.dueDate!,
            );
            final bool isOverdue =
                !isCompleted && task.dueDate!.isBefore(todayDateOnly);
            dueDateWidget = Text(
              "Due: $formattedDate",
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color:
                    isOverdue
                        ? Colors.red.shade700
                        : Theme.of(
                          context,
                        ).textTheme.bodySmall?.color?.withOpacity(0.9),
              ),
            );
          }

          Widget? notesIndicatorWidget; // Keep it nullable
          if (task.notes != null && task.notes!.isNotEmpty) {
            // Original visual part of the indicator
            Widget notesVisualRow = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.article_outlined,
                  size: 14,
                  color: Theme.of(
                    context,
                  ).textTheme.bodySmall?.color?.withOpacity(0.9),
                ),
                const SizedBox(width: 4),
                Text(
                  "View Notes",
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                    // fontWeight: FontWeight.w500, // Optional: could add for more emphasis
                  ),
                ),
              ],
            );

            notesIndicatorWidget = InkWell(
              onTap: () {
                // task, context are from itemBuilder's scope
                _showNotesDialog(context, task.title, task.notes!);
              },
              borderRadius: BorderRadius.circular(
                4.0,
              ), // Optional: for ink splash shape
              child: Padding(
                // This padding controls spacing from elements above it
                padding: EdgeInsets.only(
                  top:
                      (todayTask.description.isNotEmpty ||
                              streakDisplayWidget != null ||
                              dueDateWidget != null)
                          ? 4.0
                          : 0.0,
                ),
                child: notesVisualRow, // The actual Row with Icon and Text
              ),
            );
          }

          Widget? subTaskProgressWidget;
          if (task.subTasks.isNotEmpty) {
            int completedCount =
                task.subTasks.where((st) => st.isCompleted).length;
            int totalCount = task.subTasks.length;

            // This is the visual part (icon and text)
            Widget subTaskVisualRow = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.checklist_rtl_outlined,
                  size: 14,
                  color: Theme.of(
                    context,
                  ).textTheme.bodySmall?.color?.withOpacity(0.9),
                ),
                const SizedBox(width: 4),
                Text(
                  "Sub-tasks: $completedCount/$totalCount", // Text changed to be more descriptive for tapping
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color:
                        Theme.of(
                          context,
                        ).colorScheme.primary, // Make it look like a link
                    // textDecoration: TextDecoration.underline, // Optional: for more link-like appearance
                  ),
                ),
              ],
            );

            // Wrap the visual part (and its padding) with InkWell
            subTaskProgressWidget = InkWell(
              onTap: () {
                // task, context, and ref are from the itemBuilder's scope. task.id is the parentTaskId.
                _showSubTasksDialog(
                  context,
                  task.title,
                  task.subTasks,
                  ref,
                  task.id,
                );
              },
              borderRadius: BorderRadius.circular(
                4.0,
              ), // Optional: for ink splash shape
              child: Padding(
                // This Padding provides spacing from elements above it
                padding: EdgeInsets.only(
                  top:
                      (todayTask.description.isNotEmpty ||
                              streakDisplayWidget != null ||
                              dueDateWidget != null ||
                              notesIndicatorWidget != null)
                          ? 4.0
                          : 0.0,
                ),
                child: subTaskVisualRow,
              ),
            );
          }

          Widget? taskTargetDisplayWidget;
          if (task.taskTarget != null &&
              task.taskTarget!.type == TargetType.numeric &&
              task.taskTarget!.targetValue > 0) {
            final target = task.taskTarget!;
            double progress = target.currentValue / target.targetValue;
            if (progress < 0) progress = 0;
            if (progress > 1) progress = 1; // Clamp progress for display

            // Formatting current and target values (e.g., remove .0 for whole numbers)
            String formatValue(double val) => val.toStringAsFixed(
              val.truncateToDouble() == val ? 0 : (val * 10 % 10 == 0 ? 1 : 2),
            );
            final String currentFormatted = formatValue(target.currentValue);
            final String targetFormatted = formatValue(target.targetValue);
            final String unitDisplay =
                target.unit != null && target.unit!.isNotEmpty
                    ? " ${target.unit}"
                    : "";

            Widget targetVisual = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Target: $currentFormatted / $targetFormatted$unitDisplay",
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withOpacity(0.9),
                  ),
                ),
                if (target.targetValue > 0) ...[
                  // Only show progress bar if target is positive
                  const SizedBox(height: 3),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ],
            );

            taskTargetDisplayWidget = InkWell(
              onTap: () => _showUpdateTargetProgressDialog(context, ref, task),
              borderRadius: BorderRadius.circular(4.0),
              child: Padding(
                padding: EdgeInsets.only(
                  top:
                      (todayTask.description.isNotEmpty ||
                              streakDisplayWidget != null ||
                              dueDateWidget != null ||
                              notesIndicatorWidget != null ||
                              subTaskProgressWidget != null)
                          ? 4.0
                          : 0.0,
                ),
                child: targetVisual,
              ),
            );
          }

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            elevation: isCompleted ? 1.0 : 3.0,
            color:
                isCompleted
                    ? (taskColor?.withOpacity(0.08) ??
                        Colors.green.withOpacity(0.05))
                    : (taskColor?.withOpacity(0.15) ??
                        Theme.of(context).cardColor),
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color:
                    isCompleted
                        ? (activeColor.withOpacity(0.5))
                        : (taskColor ?? Colors.transparent),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 16.0,
              ),
              leading: finalLeadingWidget,
              title: Text(
                todayTask.title, // Use todayTask for display
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration:
                      isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                  color:
                      isCompleted
                          ? Theme.of(context).textTheme.bodySmall?.color
                          : Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              subtitle:
                  (todayTask.description.isEmpty &&
                          streakDisplayWidget == null &&
                          dueDateWidget == null &&
                          notesIndicatorWidget == null &&
                          subTaskProgressWidget == null &&
                          taskTargetDisplayWidget == null)
                      ? null
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (todayTask.description.isNotEmpty)
                            Text(
                              todayTask.description,
                              style: TextStyle(
                                color:
                                    isCompleted
                                        ? Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color
                                            ?.withOpacity(0.7)
                                        : Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.color,
                              ),
                            ),
                          if (streakDisplayWidget != null)
                            Padding(
                              padding: EdgeInsets.only(
                                top:
                                    todayTask.description.isNotEmpty
                                        ? 4.0
                                        : 0.0,
                              ),
                              child: streakDisplayWidget,
                            ),
                          if (dueDateWidget != null)
                            Padding(
                              padding: EdgeInsets.only(
                                top:
                                    (todayTask.description.isNotEmpty ||
                                            streakDisplayWidget != null)
                                        ? 4.0
                                        : 0.0,
                              ),
                              child: dueDateWidget,
                            ),
                          if (notesIndicatorWidget != null)
                            // Padding is now part of the InkWell's child if notesIndicatorWidget is built
                            notesIndicatorWidget,
                          if (subTaskProgressWidget != null)
                            subTaskProgressWidget,
                          if (taskTargetDisplayWidget != null)
                            taskTargetDisplayWidget,
                        ],
                      ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    todayTask.frequency
                        .toShortString(), // Use todayTask for display
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                      color:
                          isCompleted
                              ? Theme.of(
                                context,
                              ).textTheme.bodySmall?.color?.withOpacity(0.7)
                              : Theme.of(
                                context,
                              ).textTheme.bodySmall?.color?.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(width: 0),
                  Checkbox(
                    value: isCompleted, // Use isCompleted from todayTask
                    activeColor: activeColor,
                    visualDensity: VisualDensity.compact,
                    onChanged: (bool? newValue) {
                      if (newValue != null) {
                        ref
                            .read(completionsProvider.notifier)
                            .toggleTaskCompletion(
                              todayTask.id, // Use todayTask.id
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
                        arguments: task, // Pass original CustomTask for editing
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
                      _showDeleteConfirmationDialog(
                        context,
                        ref,
                        task,
                      ); // Pass original CustomTask
                    },
                  ),
                ],
              ),
              onTap: () {
                ref
                    .read(completionsProvider.notifier)
                    .toggleTaskCompletion(
                      todayTask.id, // Use todayTask.id
                      DateTime.now(),
                      trackId: null,
                    );
              },
              onLongPress: () {
                Navigator.pushNamed(
                  context,
                  '/task_editor',
                  arguments: task,
                ); // Pass original CustomTask
              },
            ),
          );
        },
      ),
      floatingActionButton: fab,
    );
  }
}

import 'package:alphaflow/data/models/custom_task.dart';
import 'package:alphaflow/data/models/frequency.dart';
import 'package:alphaflow/providers/custom_tasks_provider.dart';
import 'package:alphaflow/providers/task_completions_provider.dart';
import 'package:alphaflow/providers/custom_task_streaks_provider.dart';
import 'package:alphaflow/data/models/streak_info.dart';
import 'package:alphaflow/providers/today_tasks_provider.dart';
import 'package:alphaflow/data/models/today_task.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:alphaflow/data/models/task_priority.dart';
import 'package:alphaflow/data/models/sub_task.dart';
import 'package:alphaflow/data/models/task_target.dart';
import 'package:table_calendar/table_calendar.dart'; // Added
import 'package:alphaflow/providers/calendar_providers.dart'; // Added

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

class CustomHomePage extends ConsumerStatefulWidget {
  // Changed to ConsumerStatefulWidget
  const CustomHomePage({super.key});

  @override
  ConsumerState<CustomHomePage> createState() => _CustomHomePageState(); // Added createState
}

class _CustomHomePageState extends ConsumerState<CustomHomePage> {
  // New State class
  // For TableCalendar's focused day
  DateTime _focusedDay = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  // To highlight the actual current day, normalized
  final DateTime _todayNormalized = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  // Helper methods moved into the State class
  Future<void> _showDeleteConfirmationDialog(
    BuildContext context,
    CustomTask task, // WidgetRef 'ref' is now a property of ConsumerState
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
                ref
                    .read(customTasksProvider.notifier)
                    .deleteTask(task.id); // Use 'ref' directly
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
          title: Text(taskTitle),
          content: SingleChildScrollView(child: Text(notesContent)),
          contentPadding: const EdgeInsets.all(24.0),
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
    CustomTask task, // WidgetRef 'ref' is now a property of ConsumerState
  ) {
    final GlobalKey<_UpdateTargetProgressDialogContentState> dialogContentKey =
        GlobalKey<_UpdateTargetProgressDialogContentState>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Update Progress for "${task.title}"'),
          content: _UpdateTargetProgressDialogContent(
            key: dialogContentKey,
            initialCurrentValue: task.taskTarget?.currentValue ?? 0.0,
            unit: task.taskTarget?.unit,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Update'),
              onPressed: () {
                final double? validatedProgress =
                    dialogContentKey.currentState?.getValidatedProgress();
                if (validatedProgress != null) {
                  ref
                      .read(customTasksProvider.notifier)
                      .updateTaskTargetProgress(
                        task.id,
                        validatedProgress,
                      ); // Use 'ref' directly
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showSubTasksDialog(
    BuildContext context,
    String taskTitle,
    List<SubTask> subTasks,
    String parentTaskId, // WidgetRef 'ref' is now a property of ConsumerState
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Sub-tasks for "$taskTitle"'),
          content: Consumer(
            // This Consumer is for the dialog's content, not the main page state
            builder: (context, dialogConsumerRef, child) {
              // Use a different name for ref here
              final allTasks = dialogConsumerRef.watch(customTasksProvider);
              List<SubTask> displaySubTasksToShow = subTasks;
              try {
                final currentParentTask = allTasks.firstWhere(
                  (task) => task.id == parentTaskId,
                );
                displaySubTasksToShow = currentParentTask.subTasks;
              } catch (e) {
                // Fallback
              }
              return SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.4,
                child:
                    displaySubTasksToShow.isEmpty
                        ? const Center(
                          child: Text('No sub-tasks for this task.'),
                        )
                        : ListView.builder(
                          shrinkWrap: true,
                          itemCount: displaySubTasksToShow.length,
                          itemBuilder: (BuildContext context, int index) {
                            final subTask = displaySubTasksToShow[index];
                            return ListTile(
                              dense: true,
                              leading: Checkbox(
                                value: subTask.isCompleted,
                                onChanged: (bool? newValue) {
                                  if (newValue != null) {
                                    ref // Use 'ref' from _CustomHomePageState
                                        .read(customTasksProvider.notifier)
                                        .toggleSubTaskCompletion(
                                          parentTaskId,
                                          subTask.id,
                                          newValue,
                                        );
                                  }
                                },
                                visualDensity: VisualDensity.compact,
                              ),
                              title: Text(
                                subTask.title,
                                softWrap: true,
                                style: TextStyle(
                                  decoration:
                                      subTask.isCompleted
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                  color:
                                      subTask.isCompleted
                                          ? Theme.of(context).disabledColor
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
          contentPadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0),
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
  Widget build(BuildContext context) {
    // WidgetRef 'ref' is now a property of ConsumerState
    final List<TodayTask> tasksForDisplay = ref.watch(
      displayedDateTasksProvider,
    );
    ref.watch(
      completionsProvider,
    ); // Keep watching for rebuilds if completions change task state
    final streaksMap = ref.watch(customTaskStreaksProvider);

    final fab = FloatingActionButton(
      onPressed: () {
        Navigator.pushNamed(context, '/task_editor');
      },
      child: const Icon(Icons.add),
      tooltip: 'Add Task',
    );

    return Scaffold(
      body: Column(
        // Main body is now a Column
        children: [
          TableCalendar(
            locale: Localizations.localeOf(context).toString(),
            firstDay: _todayNormalized.subtract(const Duration(days: 13)),
            lastDay: _todayNormalized,
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.week,
            selectedDayPredicate:
                (day) =>
                    isSameDay(ref.watch(selectedCalendarDateProvider), day),
            currentDay: _todayNormalized,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 17.0,
                fontWeight: FontWeight.w500,
              ),
              leftChevronVisible: true,
              rightChevronVisible: true,
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            onDaySelected: (selectedDay, focusedDay) {
              final normalizedSelectedDay = DateTime(
                selectedDay.year,
                selectedDay.month,
                selectedDay.day,
              );
              final currentSelectedDateInProvider = ref.read(
                selectedCalendarDateProvider,
              );
              if (!isSameDay(
                currentSelectedDateInProvider,
                normalizedSelectedDay,
              )) {
                ref.read(selectedCalendarDateProvider.notifier).state =
                    normalizedSelectedDay;
              }
              if (!isSameDay(_focusedDay, focusedDay)) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              }
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
          ),
          const Divider(height: 1, thickness: 1),
          Expanded(
            // The rest of the content goes into Expanded
            child:
                tasksForDisplay.isEmpty
                    ? Center(
                      // Existing empty state
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
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(color: Colors.grey.shade600),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Tap the '+' button to add your first task and start organizing your goals!",
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey.shade500),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                    : ListView.builder(
                      // Existing task list
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      itemCount: tasksForDisplay.length,
                      itemBuilder: (context, index) {
                        final todayTask = tasksForDisplay[index];
                        final DateTime now = DateTime.now();
                        final DateTime todayDateOnly = DateTime(
                          now.year,
                          now.month,
                          now.day,
                        );
                        final CustomTask? task = todayTask.customTask;

                        if (task == null) {
                          return const SizedBox.shrink();
                        }

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
                            leadingWidgets.add(const SizedBox(width: 8));
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
                          finalLeadingWidget = const SizedBox(
                            width: 28,
                            height: 28,
                          );
                        }

                        final TaskStreakInfo? streakInfo =
                            streaksMap[todayTask.id];
                        Widget? streakDisplayWidget;
                        if (streakInfo != null && streakInfo.streakCount > 0) {
                          String frequencyText =
                              streakInfo.frequency == Frequency.daily
                                  ? "day"
                                  : "week";
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
                          final String formattedDate = DateFormat.yMMMd()
                              .format(task.dueDate!);
                          final bool isOverdue =
                              !isCompleted &&
                              task.dueDate!.isBefore(todayDateOnly);
                          dueDateWidget = Text(
                            "Due: $formattedDate",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color:
                                  isOverdue
                                      ? Colors.red.shade700
                                      : Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color
                                          ?.withOpacity(0.9),
                            ),
                          );
                        }

                        Widget? notesIndicatorWidget;
                        if (task.notes != null && task.notes!.isNotEmpty) {
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
                                ),
                              ),
                            ],
                          );
                          notesIndicatorWidget = InkWell(
                            onTap:
                                () => _showNotesDialog(
                                  context,
                                  task.title,
                                  task.notes!,
                                ),
                            borderRadius: BorderRadius.circular(4.0),
                            child: Padding(
                              padding: EdgeInsets.only(
                                top:
                                    (todayTask.description.isNotEmpty ||
                                            streakDisplayWidget != null ||
                                            dueDateWidget != null)
                                        ? 4.0
                                        : 0.0,
                              ),
                              child: notesVisualRow,
                            ),
                          );
                        }

                        Widget? subTaskProgressWidget;
                        if (task.subTasks.isNotEmpty) {
                          int completedCount =
                              task.subTasks
                                  .where((st) => st.isCompleted)
                                  .length;
                          int totalCount = task.subTasks.length;
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
                                "Sub-tasks: $completedCount/$totalCount",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          );
                          subTaskProgressWidget = InkWell(
                            onTap:
                                () => _showSubTasksDialog(
                                  context,
                                  task.title,
                                  task.subTasks,
                                  task.id,
                                ),
                            borderRadius: BorderRadius.circular(4.0),
                            child: Padding(
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
                          double progress =
                              target.currentValue / target.targetValue;
                          if (progress < 0) progress = 0;
                          if (progress > 1) progress = 1;
                          String formatValue(double val) => val.toStringAsFixed(
                            val.truncateToDouble() == val
                                ? 0
                                : (val * 10 % 10 == 0 ? 1 : 2),
                          );
                          final String currentFormatted = formatValue(
                            target.currentValue,
                          );
                          final String targetFormatted = formatValue(
                            target.targetValue,
                          );
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
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color
                                      ?.withOpacity(0.9),
                                ),
                              ),
                              if (target.targetValue > 0) ...[
                                const SizedBox(height: 3),
                                LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 6,
                                  backgroundColor:
                                      Theme.of(
                                        context,
                                      ).colorScheme.surfaceVariant,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ],
                            ],
                          );
                          taskTargetDisplayWidget = InkWell(
                            onTap:
                                () => _showUpdateTargetProgressDialog(
                                  context,
                                  task,
                                ), // Use 'ref' from state class
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
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 6.0,
                          ),
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
                              todayTask.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration:
                                    isCompleted
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                color:
                                    isCompleted
                                        ? Theme.of(
                                          context,
                                        ).textTheme.bodySmall?.color
                                        : Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color,
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                                      : Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium
                                                          ?.color,
                                            ),
                                          ),
                                        if (streakDisplayWidget != null)
                                          Padding(
                                            padding: EdgeInsets.only(
                                              top:
                                                  todayTask
                                                          .description
                                                          .isNotEmpty
                                                      ? 4.0
                                                      : 0.0,
                                            ),
                                            child: streakDisplayWidget,
                                          ),
                                        if (dueDateWidget != null)
                                          Padding(
                                            padding: EdgeInsets.only(
                                              top:
                                                  (todayTask
                                                              .description
                                                              .isNotEmpty ||
                                                          streakDisplayWidget !=
                                                              null)
                                                      ? 4.0
                                                      : 0.0,
                                            ),
                                            child: dueDateWidget,
                                          ),
                                        if (notesIndicatorWidget != null)
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
                                  todayTask.frequency.toShortString(),
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    fontSize: 12,
                                    color:
                                        isCompleted
                                            ? Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.color
                                                ?.withOpacity(0.7)
                                            : Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.color
                                                ?.withOpacity(0.8),
                                  ),
                                ),
                                const SizedBox(width: 0),
                                Checkbox(
                                  value: isCompleted,
                                  activeColor: activeColor,
                                  visualDensity: VisualDensity.compact,
                                  onChanged: (bool? newValue) {
                                    if (newValue != null) {
                                      ref
                                          .read(completionsProvider.notifier)
                                          .toggleTaskCompletion(
                                            todayTask.id,
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
                                  onPressed:
                                      () => Navigator.pushNamed(
                                        context,
                                        '/task_editor',
                                        arguments: task,
                                      ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  iconSize: 22.0,
                                  visualDensity: VisualDensity.compact,
                                  color: Colors.red.shade700,
                                  tooltip: 'Delete Task',
                                  onPressed:
                                      () => _showDeleteConfirmationDialog(
                                        context,
                                        task,
                                      ),
                                ), // Use 'ref' from state class
                              ],
                            ),
                            onTap:
                                () => ref
                                    .read(completionsProvider.notifier)
                                    .toggleTaskCompletion(
                                      todayTask.id,
                                      DateTime.now(),
                                      trackId: null,
                                    ),
                            onLongPress:
                                () => Navigator.pushNamed(
                                  context,
                                  '/task_editor',
                                  arguments: task,
                                ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: fab,
    );
  }
}

// --- Start of new widget definition for dialog content ---
class _UpdateTargetProgressDialogContent extends ConsumerStatefulWidget {
  final double initialCurrentValue;
  final String? unit;

  const _UpdateTargetProgressDialogContent({
    super.key,
    required this.initialCurrentValue,
    this.unit,
  });

  @override
  ConsumerState<_UpdateTargetProgressDialogContent> createState() =>
      _UpdateTargetProgressDialogContentState();
}

class _UpdateTargetProgressDialogContentState
    extends ConsumerState<_UpdateTargetProgressDialogContent> {
  late TextEditingController progressController;
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    String initialText = widget.initialCurrentValue.toStringAsFixed(
      widget.initialCurrentValue.truncateToDouble() ==
              widget.initialCurrentValue
          ? 0
          : (widget.initialCurrentValue * 10 % 10 == 0 ? 1 : 2),
    );
    progressController = TextEditingController(text: initialText);
  }

  @override
  void dispose() {
    progressController.dispose();
    super.dispose();
  }

  double? getValidatedProgress() {
    if (formKey.currentState?.validate() ?? false) {
      return double.tryParse(progressController.text.trim());
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: TextFormField(
        controller: progressController,
        decoration: InputDecoration(
          labelText:
              'Current Progress${widget.unit != null && widget.unit!.isNotEmpty ? " (${widget.unit})" : ""}',
          hintText: 'Enter current progress',
          border: const OutlineInputBorder(),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        autofocus: true,
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
          return null;
        },
      ),
    );
  }
}

// --- End of new widget definition ---

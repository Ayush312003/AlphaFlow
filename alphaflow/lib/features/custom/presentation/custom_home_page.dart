import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:alphaflow/data/models/custom_task.dart';
import 'package:alphaflow/providers/custom_tasks_provider.dart';
import '../../../common/widgets/alphaflow_drawer.dart';
import '../../../core/theme/alphaflow_theme.dart';
import '../../../common/widgets/premium_custom_task_card.dart';
import 'package:alphaflow/data/models/sub_task.dart';
import 'package:alphaflow/data/models/task_priority.dart';

// Duplicated from TaskEditorPage for now, consider moving to a shared utility
final Map<String, IconData> _customTaskIcons = {
  'task_alt': Icons.task_alt_rounded,
  'star': Icons.star_rounded,
  'flag': Icons.flag_rounded,
  'fitness': Icons.fitness_center_rounded,
  'book': Icons.book_rounded,
  'work': Icons.work_rounded,
  'home': Icons.home_rounded,
  'palette': Icons.palette_rounded,
  'school': Icons.school_rounded,
  'sports': Icons.sports_soccer_rounded,
  'music': Icons.music_note_rounded,
  'food': Icons.restaurant_rounded,
  'shopping': Icons.shopping_cart_rounded,
  'travel': Icons.flight_rounded,
  'health': Icons.favorite_rounded,
  'finance': Icons.account_balance_wallet_rounded,
};

class CustomHomePage extends ConsumerStatefulWidget {
  const CustomHomePage({super.key});

  @override
  ConsumerState<CustomHomePage> createState() => _CustomHomePageState();
}

class _CustomHomePageState extends ConsumerState<CustomHomePage> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  List<CustomTask> _tasksForSelectedDay(List<CustomTask> allTasks) {
    // Show all tasks, not just those with due dates
    return allTasks;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlphaFlowTheme.guidedBackground,
      body: Consumer(
        builder: (context, ref, child) {
          final allTasks = ref.watch(customTasksProvider);
          final tasksForSelectedDay = ref.watch(sortedCustomTasksProvider);
          
          return Column(
            children: [
              // Glassmorphic Calendar Section
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                decoration: AlphaFlowTheme.guidedGlassmorphismCardDecoration,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Column(
                    children: [
                      SizedBox(height: 0),
                      // Calendar
                      TableCalendar<CustomTask>(
                        firstDay: DateTime.now().subtract(const Duration(days: 365)),
                        lastDay: DateTime.now().add(const Duration(days: 365)),
                        focusedDay: _focusedDay,
                        calendarFormat: CalendarFormat.week,
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        onPageChanged: (focusedDay) {
                          _focusedDay = focusedDay;
                        },
                        eventLoader: (day) {
                          return allTasks.where((task) => task.dueDate != null && isSameDay(task.dueDate, day)).toList();
                        },
                        calendarStyle: CalendarStyle(
                          outsideDaysVisible: false,
                          isTodayHighlighted: true,
                          weekendTextStyle: AlphaFlowTheme.guidedTextStyle.copyWith(
                            color: AlphaFlowTheme.guidedTextSecondary,
                          ),
                          defaultTextStyle: AlphaFlowTheme.guidedTextStyle,
                          selectedTextStyle: AlphaFlowTheme.guidedTextStyle.copyWith(
                            color: AlphaFlowTheme.guidedBackground,
                            fontWeight: FontWeight.w600,
                          ),
                          todayTextStyle: AlphaFlowTheme.guidedTextStyle.copyWith(
                            color: AlphaFlowTheme.guidedAccentOrange,
                            fontWeight: FontWeight.w600,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: AlphaFlowTheme.guidedAccentOrange,
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: AlphaFlowTheme.guidedAccentOrange.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AlphaFlowTheme.guidedAccentOrange,
                              width: 1,
                            ),
                          ),
                          markerDecoration: BoxDecoration(
                            color: AlphaFlowTheme.guidedAccentOrange,
                            shape: BoxShape.circle,
                          ),
                          markersMaxCount: 3,
                          markerSize: 4,
                        ),
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          leftChevronIcon: Icon(
                            Icons.chevron_left,
                            color: AlphaFlowTheme.guidedTextPrimary,
                          ),
                          rightChevronIcon: Icon(
                            Icons.chevron_right,
                            color: AlphaFlowTheme.guidedTextPrimary,
                          ),
                          titleTextStyle: AlphaFlowTheme.guidedTextStyle.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: AlphaFlowTheme.guidedTextStyle.copyWith(
                            fontSize: 12,
                            color: AlphaFlowTheme.guidedTextSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          weekendStyle: AlphaFlowTheme.guidedTextStyle.copyWith(
                            fontSize: 12,
                            color: AlphaFlowTheme.guidedTextSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Tasks Section
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                      // Tasks Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'All Tasks',
                              style: AlphaFlowTheme.guidedTextStyle.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (tasksForSelectedDay.isNotEmpty)
                              Text(
                                '${tasksForSelectedDay.length} total',
                                style: AlphaFlowTheme.guidedTextStyle.copyWith(
                                  fontSize: 12,
                                  color: AlphaFlowTheme.guidedTextSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      // Tasks List
          Expanded(
                        child: tasksForSelectedDay.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                                      Icons.task_alt_outlined,
                                      size: 48,
                                      color: AlphaFlowTheme.guidedTextSecondary.withOpacity(0.5),
                                    ),
                                    const SizedBox(height: 16),
                            Text(
                                      'No tasks yet',
                                      style: AlphaFlowTheme.guidedTextStyle.copyWith(
                                        fontSize: 16,
                                        color: AlphaFlowTheme.guidedTextSecondary,
                                      ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                                      'Tap + to add a new task',
                                      style: AlphaFlowTheme.guidedTextStyle.copyWith(
                                        fontSize: 14,
                                        color: AlphaFlowTheme.guidedTextSecondary.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                      ),
                    )
                    : ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                itemCount: tasksForSelectedDay.length,
                      itemBuilder: (context, index) {
                                  final task = tasksForSelectedDay[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: PremiumCustomTaskCard(
                                      task: task,
                                      onEditTap: () => _editTask(context, task),
                                      onDeleteTap: () => _deleteTask(context, task),
                                      onToggleCompletion: (completed) {
                                        final now = DateTime.now();
                                        if (task.subTasks.isNotEmpty) {
                                          // Mark all subtasks as completed/incomplete
                                          final isOverdue = task.dueDate != null && task.dueDate!.isBefore(DateTime(now.year, now.month, now.day));
                                          final updated = task.copyWith(
                                            subTasks: task.subTasks
                                                .map((st) => st.copyWith(isCompleted: completed))
                                                .toList(),
                                            dueDate: (completed && isOverdue) ? null : task.dueDate,
                                          );
                                          ref.read(customTasksProvider.notifier).updateTask(updated);
                                        } else {
                                          // Toggle isCompleted for tasks without subtasks
                                          final isOverdue = task.dueDate != null && task.dueDate!.isBefore(DateTime(now.year, now.month, now.day));
                                          final updated = task.copyWith(
                                            isCompleted: completed,
                                            dueDate: (completed && isOverdue) ? null : task.dueDate,
                                          );
                                          ref.read(customTasksProvider.notifier).updateTask(updated);
                                        }
                                      },
                                      onNotesTap: task.notes != null && task.notes!.isNotEmpty
                                          ? () => _showNotesDialog(context, task.title, task.notes!)
                                          : null,
                                      onSubTasksTap: task.subTasks.isNotEmpty
                                          ? () => _showSubTasksDialog(context, task.id, task.title, task.subTasks)
                                          : null,
                                      onTargetTap: task.taskTarget != null
                                          ? () => _showTargetDialog(context, task)
                                          : null,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AlphaFlowTheme.guidedAccentOrange,
              AlphaFlowTheme.guidedAccentOrange.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AlphaFlowTheme.guidedAccentOrange.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _addTask(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(
            Icons.add,
            color: Colors.white,
                            size: 24,
            ),
        ),
      ),
    );
  }

  void _addTask(BuildContext context) {
    Navigator.pushNamed(context, '/task_editor', arguments: _selectedDay);
  }

  void _editTask(BuildContext context, CustomTask task) {
    Navigator.pushNamed(context, '/task_editor', arguments: task);
  }

  void _deleteTask(BuildContext context, CustomTask task) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.96),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Delete Task',
            style: AlphaFlowTheme.guidedTextStyle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${task.title}"?',
            style: AlphaFlowTheme.guidedTextStyle.copyWith(
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: AlphaFlowTheme.guidedTextStyle.copyWith(
                  color: AlphaFlowTheme.guidedTextSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                ref.read(customTasksProvider.notifier).deleteTask(task.id);
                Navigator.of(context).pop();
              },
              child: Text(
                'Delete',
                style: AlphaFlowTheme.guidedTextStyle.copyWith(
                  color: AlphaFlowTheme.guidedAccentOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showNotesDialog(BuildContext context, String title, String notes) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.96),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: AlphaFlowTheme.guidedTextStyle.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          notes,
          style: AlphaFlowTheme.guidedTextStyle.copyWith(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: AlphaFlowTheme.guidedTextStyle.copyWith(
                color: AlphaFlowTheme.guidedAccentOrange,
              ),
            ),
          ),
        ],
                            ),
                          );
                        }

  void _showSubTasksDialog(BuildContext context, String parentTaskId, String title, List<SubTask> subTasks) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.96),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Sub-tasks for "$title"',
            style: AlphaFlowTheme.guidedTextStyle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: subTasks.isEmpty
              ? Center(
                  child: Text(
                    'No sub-tasks for this task.',
                    style: AlphaFlowTheme.guidedTextStyle.copyWith(
                      color: AlphaFlowTheme.guidedTextSecondary,
                    ),
                  ),
                )
              : ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: 200,
                    minHeight: 60,
                    maxHeight: subTasks.length > 5
                        ? MediaQuery.of(context).size.height * 0.4
                        : double.infinity,
                  ),
                  child: SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: subTasks.length > 5
                          ? const AlwaysScrollableScrollPhysics()
                          : const NeverScrollableScrollPhysics(),
                      itemCount: subTasks.length,
                      itemBuilder: (context, index) {
                        final subTask = subTasks[index];
                        return Consumer(
                          builder: (context, ref, child) {
                            return ListTile(
                              dense: true,
                              leading: GestureDetector(
                                onTap: () {
                                  final allTasks = ref.read(customTasksProvider);
                                  final parentTask = allTasks.firstWhere((task) => task.id == parentTaskId);
                                  final updatedSubTasks = List<SubTask>.from(parentTask.subTasks);
                                  updatedSubTasks[index] = subTask.copyWith(isCompleted: !subTask.isCompleted);
                                  final updatedTask = parentTask.copyWith(subTasks: updatedSubTasks);
                                  ref.read(customTasksProvider.notifier).updateTask(updatedTask);
                                  setState(() {
                                    subTasks[index] = updatedSubTasks[index];
                                  });
                                },
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: subTask.isCompleted 
                                          ? AlphaFlowTheme.guidedAccentOrange 
                                          : AlphaFlowTheme.guidedTextSecondary.withOpacity(0.3),
                                      width: 2,
                                    ),
                                    color: subTask.isCompleted 
                                        ? AlphaFlowTheme.guidedAccentOrange 
                                        : Colors.transparent,
                                  ),
                                  child: subTask.isCompleted
                                      ? const Icon(
                                          Icons.check,
                                          size: 12,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              ),
                              title: Text(
                                subTask.title,
                                style: AlphaFlowTheme.guidedTextStyle.copyWith(
                                  decoration: subTask.isCompleted 
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: subTask.isCompleted 
                                      ? AlphaFlowTheme.guidedTextSecondary 
                                      : AlphaFlowTheme.guidedTextPrimary,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: AlphaFlowTheme.guidedTextStyle.copyWith(
                  color: AlphaFlowTheme.guidedAccentOrange,
                ),
              ),
            ),
          ],
        ),
                            ),
                          );
                        }

  void _showTargetDialog(BuildContext context, CustomTask task) {
                          final target = task.taskTarget!;
    final progress = target.currentValue / target.targetValue;
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.96),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Target Progress for "${task.title}"',
          style: AlphaFlowTheme.guidedTextStyle.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
                            mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
              '${target.currentValue} / ${target.targetValue} ${target.unit}',
              style: AlphaFlowTheme.guidedTextStyle.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
                                LinearProgressIndicator(
                                  value: progress,
              backgroundColor: AlphaFlowTheme.guidedTextSecondary.withOpacity(0.2),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                AlphaFlowTheme.guidedAccentOrange,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).toStringAsFixed(1)}% complete',
              style: AlphaFlowTheme.guidedTextStyle.copyWith(
                fontSize: 12,
                color: AlphaFlowTheme.guidedTextSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: AlphaFlowTheme.guidedTextStyle.copyWith(
                color: AlphaFlowTheme.guidedTextSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showUpdateProgressDialog(context, task);
            },
            child: Text(
              'Update Progress',
              style: AlphaFlowTheme.guidedTextStyle.copyWith(
                color: AlphaFlowTheme.guidedAccentOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpdateProgressDialog(BuildContext context, CustomTask task) {
    final target = task.taskTarget!;
    final controller = TextEditingController(
      text: target.currentValue.toString(),
    );
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.96),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: Text(
          'Update Progress',
          style: AlphaFlowTheme.guidedTextStyle.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                          Text(
              'Current target: ${target.targetValue} ${target.unit}',
              style: AlphaFlowTheme.guidedTextStyle.copyWith(
                fontSize: 14,
                color: AlphaFlowTheme.guidedTextSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Theme(
              data: Theme.of(context).copyWith(
                textSelectionTheme: const TextSelectionThemeData(
                  cursorColor: AlphaFlowTheme.guidedAccentOrange,
                  selectionColor: AlphaFlowTheme.guidedAccentOrange,
                  selectionHandleColor: AlphaFlowTheme.guidedAccentOrange,
                ),
              ),
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                cursorColor: AlphaFlowTheme.guidedAccentOrange,
                decoration: InputDecoration(
                  labelText: 'Current Progress (${target.unit})',
                  border: const OutlineInputBorder(),
                  labelStyle: AlphaFlowTheme.guidedTextStyle.copyWith(
                    color: AlphaFlowTheme.guidedTextSecondary,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AlphaFlowTheme.guidedAccentOrange, width: 2),
                  ),
                ),
                style: AlphaFlowTheme.guidedTextStyle,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: AlphaFlowTheme.guidedTextStyle.copyWith(
                color: AlphaFlowTheme.guidedTextSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final newValue = double.tryParse(controller.text);
              if (newValue != null && newValue >= 0) {
                ref.read(customTasksProvider.notifier).updateTaskTargetProgress(
                  task.id,
                  newValue,
                );
                Navigator.of(context).pop();
              }
            },
            child: Text(
              'Update',
              style: AlphaFlowTheme.guidedTextStyle.copyWith(
                color: AlphaFlowTheme.guidedAccentOrange,
                fontWeight: FontWeight.w600,
              ),
                    ),
          ),
        ],
      ),
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

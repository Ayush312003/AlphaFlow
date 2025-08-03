import 'package:alphaflow/data/models/custom_task.dart';
import 'package:alphaflow/data/models/frequency.dart';
import 'package:alphaflow/providers/custom_tasks_provider.dart';
import 'package:alphaflow/data/models/sub_task.dart';
import 'package:alphaflow/data/models/custom_task.dart';
import 'package:alphaflow/data/models/frequency.dart';
import 'package:alphaflow/providers/custom_tasks_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:alphaflow/data/models/task_priority.dart';
import 'package:alphaflow/data/models/task_target.dart';
import 'package:alphaflow/core/theme/alphaflow_theme.dart';

// Example predefined icons
final Map<String, IconData> _predefinedIcons = {
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

// Premium guided mode color palette
final List<Color> _predefinedColors = [
  Colors.white,
  Colors.grey.shade300,
  Colors.grey.shade600,
  AlphaFlowTheme.guidedAccentOrange,
  Colors.orange.shade200,
  Colors.green.shade200,
  Colors.red.shade200,
  Colors.black.withOpacity(0.7),
];

class TaskEditorPage extends ConsumerStatefulWidget {
  final CustomTask? taskToEdit;

  const TaskEditorPage({super.key, this.taskToEdit});

  @override
  ConsumerState<TaskEditorPage> createState() => _TaskEditorPageState();
}

class _TaskEditorPageState extends ConsumerState<TaskEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  int? _selectedColorValue;
  DateTime? _selectedDueDate;
  late TextEditingController _notesController;
  TaskPriority _selectedPriority = TaskPriority.none;
  List<SubTask> _currentSubTasks = [];
  List<TextEditingController> _subTaskTitleControllers = [];
  TargetType _selectedTargetType = TargetType.none;
  late TextEditingController _targetValueController;
  late TextEditingController _targetUnitController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _notesController = TextEditingController();
    _targetValueController = TextEditingController(); // Initialize here
    _targetUnitController = TextEditingController(); // Initialize here

    if (widget.taskToEdit != null) {
      _titleController.text = widget.taskToEdit!.title;
      _selectedColorValue = widget.taskToEdit!.colorValue;
      _selectedDueDate = widget.taskToEdit!.dueDate;
      _notesController.text = widget.taskToEdit!.notes ?? '';
      _selectedPriority = widget.taskToEdit!.priority;
      _currentSubTasks = List<SubTask>.from(
        widget.taskToEdit!.subTasks.map((st) => st.copyWith()),
      ); // Deep copy
      _subTaskTitleControllers =
          _currentSubTasks
              .map((st) => TextEditingController(text: st.title))
              .toList();
      if (widget.taskToEdit!.taskTarget != null) {
        final target = widget.taskToEdit!.taskTarget!;
        _selectedTargetType = target.type;
        if (target.type == TargetType.numeric) {
          // Format targetValue to string, avoiding unnecessary .0 for whole numbers
          _targetValueController.text = target.targetValue.toStringAsFixed(
            target.targetValue.truncateToDouble() == target.targetValue ? 0 : 2,
          );
          _targetUnitController.text = target.unit ?? '';
        }
      }
    }
  }

  Future<void> _pickDueDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(
        const Duration(days: 365),
      ),
      lastDate: DateTime.now().add(
        const Duration(days: 365 * 5),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AlphaFlowTheme.guidedTextPrimary,
              onPrimary: Colors.black,
              surface: AlphaFlowTheme.guidedBackground,
              onSurface: AlphaFlowTheme.guidedTextPrimary,
              secondary: AlphaFlowTheme.guidedAccentOrange,
            ),
            dialogBackgroundColor: AlphaFlowTheme.guidedBackground,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AlphaFlowTheme.guidedAccentOrange,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null && pickedDate != _selectedDueDate) {
      setState(() {
        _selectedDueDate = pickedDate;
      });
    }
  }

  void _addSubTask() {
    setState(() {
      final newSubTask = SubTask(title: ''); // ID generated by SubTask model
      _currentSubTasks.add(newSubTask);
      _subTaskTitleControllers.add(TextEditingController());
    });
  }

  void _removeSubTask(int index) {
    setState(() {
      _subTaskTitleControllers[index].dispose(); // Dispose controller first
      _currentSubTasks.removeAt(index);
      _subTaskTitleControllers.removeAt(index);
    });
  }

  void _toggleSubTaskCompletion(int index, bool? newValue) {
    if (newValue == null) return;
    setState(() {
      _currentSubTasks[index] = _currentSubTasks[index].copyWith(
        isCompleted: newValue,
      );
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    for (var controller in _subTaskTitleControllers) {
      controller.dispose();
    }
    _targetValueController.dispose();
    _targetUnitController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final title = _titleController.text.trim();

      TaskTarget? finalTaskTarget;
      if (_selectedTargetType == TargetType.numeric) {
        final String targetValueStr = _targetValueController.text.trim();
        final double? targetValue = double.tryParse(targetValueStr);

        // Validator should have already ensured targetValue is valid if type is numeric
        if (targetValue != null && targetValue > 0) {
          final String? unit =
              _targetUnitController.text.trim().isNotEmpty
                  ? _targetUnitController.text.trim()
                  : null;

          double initialCurrentValue = 0.0;
          // If editing and previous target was also numeric, preserve currentValue
          // unless new targetValue is less than currentValue (then cap or reset - for now, preserve)
          if (widget.taskToEdit?.taskTarget != null &&
              widget.taskToEdit!.taskTarget!.type == TargetType.numeric) {
            initialCurrentValue = widget.taskToEdit!.taskTarget!.currentValue;
            if (targetValue < initialCurrentValue) {
              // Decision: Cap currentValue to new targetValue if new target is smaller
              // initialCurrentValue = targetValue;
              // Or reset to 0: initialCurrentValue = 0.0;
              // For now, let's preserve. User can manually adjust progress if target shrinks.
            }
          }

          finalTaskTarget = TaskTarget(
            type: TargetType.numeric,
            targetValue: targetValue,
            currentValue:
                initialCurrentValue, // Start new/edited target's progress at 0 or preserved value
            unit: unit,
          );
        }
        // If numeric type is selected but value is invalid, validator stops form submission.
        // If it somehow passed, finalTaskTarget remains null, effectively setting no target.
      }
      // If _selectedTargetType is TargetType.none, finalTaskTarget remains null.

      List<SubTask> finalSubTasks = [];
      for (int i = 0; i < _currentSubTasks.length; i++) {
        final subTaskTitle = _subTaskTitleControllers[i].text.trim();
        if (subTaskTitle.isNotEmpty) {
          // Only save sub-tasks with non-empty titles
          finalSubTasks.add(_currentSubTasks[i].copyWith(title: subTaskTitle));
        }
      }

      final customTasksNotifier = ref.read(customTasksProvider.notifier);

      if (widget.taskToEdit == null) {
        customTasksNotifier.addTask(
          title: title,
          iconName: null,
          colorValue: _selectedColorValue,
          dueDate: _selectedDueDate,
          notes: _notesController.text.trim(),
          priority: _selectedPriority,
          subTasks: finalSubTasks,
          taskTarget: finalTaskTarget,
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Task "$title" created.')));
      } else {
        final updatedTask = widget.taskToEdit!.copyWith(
          // Use copyWith for easier updates
          title: title,
          iconName: null,
          colorValue: _selectedColorValue,
          dueDate: _selectedDueDate,
          notes: _notesController.text.trim(),
          priority: _selectedPriority,
          subTasks: finalSubTasks,
          taskTarget: finalTaskTarget,
          clearIconName: true,
          clearColorValue: _selectedColorValue == null,
          clearDueDate:
              _selectedDueDate == null && widget.taskToEdit?.dueDate != null,
          clearNotes:
              _notesController.text.trim().isEmpty &&
              (widget.taskToEdit?.notes?.isNotEmpty ?? false),
          clearTaskTarget:
              finalTaskTarget == null && widget.taskToEdit?.taskTarget != null,
        );
        customTasksNotifier.updateTask(updatedTask);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Task "$title" updated.')));
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please correct the errors in the form.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.taskToEdit == null ? 'Create Task' : 'Edit Task'),
      ),
      body: Container(
        color: AlphaFlowTheme.guidedBackground,
        child: SafeArea(
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AlphaFlowTheme.guidedTextPrimary,
                secondary: AlphaFlowTheme.guidedAccentOrange,
              ),
              inputDecorationTheme: const InputDecorationTheme(
                labelStyle: TextStyle(color: AlphaFlowTheme.guidedTextPrimary),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AlphaFlowTheme.guidedTextPrimary, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AlphaFlowTheme.guidedTextSecondary, width: 1),
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AlphaFlowTheme.guidedTextSecondary, width: 1),
                ),
                hintStyle: TextStyle(color: AlphaFlowTheme.guidedTextSecondary),
              ),
              textSelectionTheme: const TextSelectionThemeData(
                cursorColor: AlphaFlowTheme.guidedTextPrimary,
                selectionColor: AlphaFlowTheme.guidedAccentOrange,
                selectionHandleColor: AlphaFlowTheme.guidedAccentOrange,
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'Enter task title',
                        border: OutlineInputBorder(),
                        isDense: true, // Added
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 14.0,
                        ), // Added/Adjusted
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<TaskPriority>(
                      value: _selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          TaskPriority.values.map((TaskPriority priority) {
                            return DropdownMenuItem<TaskPriority>(
                              value: priority,
                              // Assumes TaskPriorityExtension with displayName is in task_priority.dart
                              child: Text(priority.displayName),
                            );
                          }).toList(),
                      onChanged: (TaskPriority? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedPriority = newValue;
                          });
                        }
                      },
                      // No validator needed as it defaults to TaskPriority.none
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Due Date (Optional)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: AlphaFlowTheme.guidedCardBackground,
                                side: const BorderSide(color: AlphaFlowTheme.guidedCardBorder, width: 1.2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                              ),
                              onPressed: _pickDueDate,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(Icons.event, color: AlphaFlowTheme.guidedTextPrimary, size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    _selectedDueDate == null
                                        ? 'Set Due Date'
                                        : DateFormat.yMMMd().format(_selectedDueDate!),
                                    style: const TextStyle(
                                      color: AlphaFlowTheme.guidedTextPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Sora',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_selectedDueDate != null)
                            IconButton(
                              icon: const Icon(Icons.close, color: AlphaFlowTheme.guidedTextSecondary),
                              tooltip: 'Clear Due Date',
                              onPressed: () {
                                setState(() {
                                  _selectedDueDate = null;
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (Optional)',
                        hintText: 'Add any notes for your task...',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true, // Good for multi-line fields
                      ),
                      maxLines: 4, // Increased maxLines
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Sub-tasks / Checklist',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_currentSubTasks.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'No sub-tasks yet. Tap "Add Sub-task" to create one.',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    Column(
                      children:
                          _currentSubTasks.asMap().entries.map((entry) {
                            int idx = entry.key;
                            SubTask subTask = entry.value;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: subTask.isCompleted,
                                    onChanged:
                                        (bool? newValue) =>
                                            _toggleSubTaskCompletion(idx, newValue),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _subTaskTitleControllers[idx],
                                      decoration: InputDecoration(
                                        hintText: 'Sub-task ${idx + 1}',
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(
                                          vertical: 8.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.grey,
                                    ),
                                    iconSize: 22,
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => _removeSubTask(idx),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Sub-task'),
                        onPressed: _addSubTask,
                      ),
                    ),
                    const SizedBox(height: 24), // Spacing from sub-task section
                    Text(
                      'Measurable Target (Optional)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<TargetType>(
                      value: _selectedTargetType,
                      decoration: const InputDecoration(
                        labelText: 'Target Type',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          [TargetType.none, TargetType.numeric].map((
                            TargetType type,
                          ) {
                            // Simple capitalization for display name
                            String displayName =
                                type.name[0].toUpperCase() + type.name.substring(1);
                            return DropdownMenuItem<TargetType>(
                              value: type,
                              child: Text(displayName),
                            );
                          }).toList(),
                      onChanged: (TargetType? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedTargetType = newValue;
                            // Optionally clear targetValue and unit when type changes from numeric to none
                            if (_selectedTargetType == TargetType.none) {
                              _targetValueController.clear();
                              _targetUnitController.clear();
                            }
                          });
                        }
                      },
                    ),
                    if (_selectedTargetType == TargetType.numeric) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _targetValueController,
                        decoration: const InputDecoration(
                          labelText: 'Target Value',
                          hintText: 'e.g., 100, 5.5, 30',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (_selectedTargetType == TargetType.numeric) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a target value';
                            }
                            final number = double.tryParse(value);
                            if (number == null) {
                              return 'Please enter a valid number';
                            }
                            if (number <= 0) {
                              return 'Target must be a positive number';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _targetUnitController,
                        decoration: const InputDecoration(
                          labelText: 'Unit (Optional)',
                          hintText: 'e.g., pages, km, minutes, reps',
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization:
                            TextCapitalization.none, // Allow units like 'km'
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AlphaFlowTheme.guidedAccentOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Sora',
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Save Task'),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

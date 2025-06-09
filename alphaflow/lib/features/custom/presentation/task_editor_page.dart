import 'package:alphaflow/data/models/custom_task.dart';
import 'package:alphaflow/data/models/frequency.dart';
import 'package:alphaflow/providers/custom_tasks_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // For date formatting

// Example predefined icons
final Map<String, IconData> _predefinedIcons = {
  'task_alt': Icons.task_alt,
  'star': Icons.star_border_purple500_outlined,
  'flag': Icons.flag_outlined,
  'fitness': Icons.fitness_center_outlined,
  'book': Icons.book_outlined,
  'work': Icons.work_outline,
  'home': Icons.home_outlined,
  'palette': Icons.palette_outlined,
};

// Example predefined colors
final List<Color> _predefinedColors = [
  Colors.grey.shade300, // A 'none' or default option
  Colors.blue.shade200,
  Colors.green.shade200,
  Colors.orange.shade200,
  Colors.purple.shade200,
  Colors.red.shade200,
  Colors.teal.shade200,
  Colors.pink.shade200,
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
  late TextEditingController _descriptionController;
  Frequency _selectedFrequency = Frequency.daily;
  String? _selectedIconName;
  int? _selectedColorValue;
  DateTime? _selectedDueDate;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _notesController = TextEditingController();

    if (widget.taskToEdit != null) {
      _titleController.text = widget.taskToEdit!.title;
      _descriptionController.text = widget.taskToEdit!.description;
      _selectedFrequency = widget.taskToEdit!.frequency;
      _selectedIconName = widget.taskToEdit!.iconName;
      _selectedColorValue = widget.taskToEdit!.colorValue;
      _selectedDueDate = widget.taskToEdit!.dueDate;
      _notesController.text = widget.taskToEdit!.notes ?? '';
    }
  }

  Future<void> _pickDueDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(
        const Duration(days: 365),
      ), // Allow past dates for flexibility
      lastDate: DateTime.now().add(
        const Duration(days: 365 * 5),
      ), // Allow up to 5 years in future
    );
    if (pickedDate != null && pickedDate != _selectedDueDate) {
      setState(() {
        _selectedDueDate = pickedDate;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();

      final customTasksNotifier = ref.read(customTasksProvider.notifier);

      if (widget.taskToEdit == null) {
        customTasksNotifier.addTask(
          title: title,
          description: description,
          frequency: _selectedFrequency,
          iconName: _selectedIconName,
          colorValue: _selectedColorValue,
          dueDate: _selectedDueDate,
          notes: _notesController.text.trim(),
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Task "$title" created.')));
      } else {
        final updatedTask = widget.taskToEdit!.copyWith(
          // Use copyWith for easier updates
          title: title,
          description: description,
          frequency: _selectedFrequency,
          iconName: _selectedIconName,
          colorValue: _selectedColorValue,
          dueDate: _selectedDueDate,
          notes: _notesController.text.trim(),
          clearIconName: _selectedIconName == null,
          clearColorValue: _selectedColorValue == null,
          clearDueDate:
              _selectedDueDate == null && widget.taskToEdit?.dueDate != null,
          clearNotes:
              _notesController.text.trim().isEmpty &&
              (widget.taskToEdit?.notes?.isNotEmpty ?? false),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter task title',
                  border: OutlineInputBorder(),
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
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Enter task description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Frequency>(
                value: _selectedFrequency,
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                  border: OutlineInputBorder(),
                ),
                items:
                    Frequency.values.map((Frequency frequency) {
                      return DropdownMenuItem<Frequency>(
                        value: frequency,
                        child: Text(frequency.toShortString()),
                      );
                    }).toList(),
                onChanged: (Frequency? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedFrequency = newValue;
                    });
                  }
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a frequency';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Due Date (Optional)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text(
                  _selectedDueDate == null
                      ? 'Not set'
                      : DateFormat.yMMMd().format(_selectedDueDate!),
                ),
                trailing:
                    _selectedDueDate == null
                        ? null
                        : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _selectedDueDate = null;
                            });
                          },
                        ),
                onTap: _pickDueDate,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
                tileColor: Colors.grey.shade50, // Slight background tint
              ),
              const SizedBox(height: 16), // Spacing after due date picker
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
                'Select Icon (Optional)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children:
                    _predefinedIcons.entries.map((entry) {
                      final iconName = entry.key;
                      final iconData = entry.value;
                      final isSelected = _selectedIconName == iconName;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedIconName = null;
                            } else {
                              _selectedIconName = iconName;
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color:
                                  isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey.shade400,
                              width: isSelected ? 2.0 : 1.0,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color:
                                isSelected
                                    ? Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.1)
                                    : null,
                          ),
                          child: Icon(
                            iconData,
                            color:
                                isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.shade700,
                            size: 28,
                          ),
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 24),
              Text(
                'Select Color (Optional)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10.0, // Increased spacing for colors
                runSpacing: 10.0,
                children:
                    _predefinedColors.map((color) {
                      final isSelected = _selectedColorValue == color.value;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedColorValue = null;
                            } else {
                              _selectedColorValue = color.value;
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          width: 44, // Slightly larger tap target
                          height: 44,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors
                                          .grey
                                          .shade500, // Darker border for unselected
                              width: isSelected ? 3.0 : 1.5,
                            ),
                            boxShadow: [
                              // Add subtle shadow for depth
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child:
                              isSelected
                                  ? Icon(
                                    Icons.check,
                                    color:
                                        ThemeData.estimateBrightnessForColor(
                                                  color,
                                                ) ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Colors.black,
                                    size: 24,
                                  )
                                  : null,
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
    );
  }
}

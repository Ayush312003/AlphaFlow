import 'package:alphaflow/data/models/custom_task.dart';
import 'package:alphaflow/data/models/frequency.dart';
import 'package:alphaflow/providers/custom_tasks_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();

    if (widget.taskToEdit != null) {
      _titleController.text = widget.taskToEdit!.title;
      _descriptionController.text = widget.taskToEdit!.description;
      _selectedFrequency = widget.taskToEdit!.frequency;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task "$title" created.')),
        );
      } else {
        final updatedTask = CustomTask(
          id: widget.taskToEdit!.id,
          title: title,
          description: description,
          frequency: _selectedFrequency,
        );
        customTasksNotifier.updateTask(updatedTask);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task "$title" updated.')),
        );
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
                items: Frequency.values.map((Frequency frequency) {
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
              const SizedBox(height: 32), // Increased spacing before save button
              SizedBox( // Wrap ElevatedButton with SizedBox to control its width
                width: double.infinity, // Make button full width
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    // backgroundColor: Theme.of(context).colorScheme.primary, // Optional: theming
                    // foregroundColor: Theme.of(context).colorScheme.onPrimary, // Optional: theming
                  ),
                  child: const Text('Save Task'),
                ),
              ),
              const SizedBox(height: 16), // Add some padding at the bottom of the scroll view
            ],
          ),
        ),
      ),
    );
  }
}

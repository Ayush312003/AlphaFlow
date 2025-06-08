import 'package:alphaflow/data/models/custom_task.dart';
import 'package:flutter/material.dart';

class TaskEditorPage extends StatelessWidget {
  final CustomTask? taskToEdit;

  const TaskEditorPage({super.key, this.taskToEdit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(taskToEdit == null ? 'Create Task' : 'Edit Task'),
      ),
      body: Center(
        child: Padding( // Added padding for better text presentation
          padding: const EdgeInsets.all(16.0),
          child: Text(
            taskToEdit == null
                ? 'Task Editor Placeholder (Create Mode)'
                : 'Task Editor Placeholder (Edit Mode for: "${taskToEdit!.title}")',
            textAlign: TextAlign.center, // Center align text
            style: const TextStyle(fontSize: 16), // Slightly larger font for placeholder
          ),
        ),
      ),
    );
  }
}

import 'package:alphaflow/data/models/guided_task.dart';
import 'package:alphaflow/data/models/guided_track.dart';
import 'package:alphaflow/features/guided/providers/guided_tracks_provider.dart';
import 'package:alphaflow/providers/selected_track_provider.dart';
import 'package:alphaflow/providers/task_completions_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GuidedHomePage extends ConsumerWidget {
  const GuidedHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTrackId = ref.watch(selectedTrackProvider);

    // Watch completionsProvider to ensure UI rebuilds when completion status changes.
    ref.watch(completionsProvider);

    if (selectedTrackId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Guided Mode")),
        body: const Center(child: Text("No track selected. Please select a track first.")),
      );
    }

    final track = ref.watch(guidedTrackByIdProvider(selectedTrackId));

    if (track == null) {
      return Scaffold(
        appBar: AppBar(title: Text(selectedTrackId)),
        body: const Center(child: Text("Track not found. It might have been removed or the ID is invalid.")),
      );
    }

    final List<GuidedTask> currentTasks = track.levels.isNotEmpty ? track.levels[0].unlockTasks : [];

    return Scaffold(
      appBar: AppBar(
        title: Text(track.title),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Text(
              "Level 1 Tasks", // This will be dynamic later
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          if (currentTasks.isEmpty)
            const Expanded(
              child: Center(child: Text("No tasks available for this level.")),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                itemCount: currentTasks.length,
                itemBuilder: (context, index) {
                  final task = currentTasks[index];
                  final isCompleted = ref.read(completionsProvider.notifier).isTaskCompletedOnDate(task.id, DateTime.now());

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                    elevation: isCompleted ? 1.0 : 3.0, // Change elevation based on completion
                    color: isCompleted ? Colors.green.withOpacity(0.05) : Theme.of(context).cardColor, // Subtle green tint or default card color
                    shape: RoundedRectangleBorder( // Optional: add a border or change shape
                        borderRadius: BorderRadius.circular(8.0),
                        side: isCompleted
                            ? BorderSide(color: Colors.green.withOpacity(0.3), width: 1)
                            : BorderSide.none,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      leading: Checkbox(
                        value: isCompleted,
                        activeColor: Colors.green, // Emphasize active color
                        onChanged: (bool? newValue) {
                          if (newValue != null) {
                            ref.read(completionsProvider.notifier).toggleTaskCompletion(
                              task.id,
                              DateTime.now(),
                              trackId: selectedTrackId,
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
                      trailing: Text(
                        "XP: ${task.xp}",
                        style: TextStyle(
                          color: isCompleted ? Colors.green : Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

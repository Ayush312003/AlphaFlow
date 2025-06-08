import 'package:alphaflow/data/models/today_task.dart'; // Added
import 'package:alphaflow/providers/today_tasks_provider.dart'; // Added
import 'package:alphaflow/providers/selected_track_provider.dart'; // Still needed for trackId in toggle
import 'package:alphaflow/providers/task_completions_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Removed GuidedTask, GuidedTrack, guidedTracksProvider imports as they are now handled by todayTasksProvider

class GuidedHomePage extends ConsumerWidget {
  const GuidedHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // todayTasksProvider will return only guided tasks when in guided mode.
    final List<TodayTask> tasksForDisplay = ref.watch(todayTasksProvider);
    // Watch completionsProvider to ensure UI rebuilds when completion status changes.
    ref.watch(completionsProvider);
    // We need selectedTrackId for the toggleTaskCompletion's trackId argument.
    // Watching it here also ensures that if the track changes (e.g. via drawer),
    // todayTasksProvider (which also watches it) causes a rebuild correctly.
    final selectedTrackId = ref.watch(selectedTrackProvider);


    // Fallback if, for some reason, HomePage didn't redirect and selectedTrackId is null here.
    // todayTasksProvider would likely return an empty list in this scenario for guided mode.
    if (selectedTrackId == null) {
         return const Center(child: Text("No guided track selected. Please select one from the drawer or main menu.", textAlign: TextAlign.center,));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Text(
            "Today's Tasks", // Changed header
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        if (tasksForDisplay.isEmpty)
          const Expanded(
            child: Center(child: Text("No tasks for today, or the selected track has no tasks for the current level.")),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
              itemCount: tasksForDisplay.length,
              itemBuilder: (context, index) {
                final todayTask = tasksForDisplay[index];
                // todayTask.isCompleted is now directly available

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                  elevation: todayTask.isCompleted ? 1.0 : 3.0,
                  color: todayTask.isCompleted ? Colors.green.withOpacity(0.05) : Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: todayTask.isCompleted
                          ? BorderSide(color: Colors.green.withOpacity(0.3), width: 1)
                          : BorderSide.none,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    leading: Checkbox(
                      value: todayTask.isCompleted,
                      activeColor: Colors.green,
                      onChanged: (bool? newValue) {
                        if (newValue != null) {
                          // Ensure selectedTrackId is not null before using (already checked above)
                          ref.read(completionsProvider.notifier).toggleTaskCompletion(
                            todayTask.id, // This is guidedTask.id from TodayTask
                            DateTime.now(),
                            trackId: selectedTrackId,
                          );
                        }
                      },
                    ),
                    title: Text(
                      todayTask.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: todayTask.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                        color: todayTask.isCompleted ? Theme.of(context).textTheme.bodySmall?.color : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        todayTask.description,
                         style: TextStyle(
                           color: todayTask.isCompleted ? Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7) : Theme.of(context).textTheme.bodyMedium?.color,
                         ),
                      ),
                    ),
                    trailing: Text(
                      "XP: ${todayTask.xp}", // Using getter from TodayTask
                      style: TextStyle(
                        color: todayTask.isCompleted ? Colors.green : Theme.of(context).colorScheme.primary,
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
    );
  }
}

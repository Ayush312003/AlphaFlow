import 'package:alphaflow/data/models/today_task.dart';
import 'package:alphaflow/providers/today_tasks_provider.dart';
import 'package:alphaflow/providers/selected_track_provider.dart';
import 'package:alphaflow/providers/task_completions_provider.dart';
import 'package:alphaflow/providers/xp_provider.dart';
import 'package:alphaflow/providers/guided_level_provider.dart'; // Added import
import 'package:alphaflow/data/models/level_definition.dart'; // Added import
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphaflow/providers/guided_task_streaks_provider.dart';
import 'package:alphaflow/data/models/streak_info.dart';
import 'package:alphaflow/data/models/frequency.dart';

class GuidedHomePage extends ConsumerWidget {
  const GuidedHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<TodayTask> tasksForDisplay = ref.watch(displayedDateTasksProvider);
    ref.watch(completionsProvider);
    final selectedTrackId = ref.watch(selectedTrackProvider);
    final int currentXp = ref.watch(xpProvider);
    final LevelDefinition? currentLevel = ref.watch(
      currentGuidedLevelProvider,
    ); // Watch current level
    final streakData = ref.watch(guidedTaskStreaksProvider);

    final double totalPossibleXpToday = tasksForDisplay.fold(
      0.0,
      (sum, task) => sum + task.xp,
    );
    final double progress =
        (totalPossibleXpToday > 0) ? (currentXp / totalPossibleXpToday) : 0.0;

    if (selectedTrackId == null) {
      return const Center(
        child: Text(
          "No guided track selected. Please select one from the drawer or main menu.",
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Level and XP Info Section
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 12.0,
          ), // Adjusted vertical padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currentLevel != null)
                Text(
                  "Level ${currentLevel.levelNumber}: ${currentLevel.title} ${currentLevel.icon}", // Added icon to level display
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                )
              else
                Text(
                  "Current Level: N/A",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              const SizedBox(height: 10), // Adjusted space

              Text(
                // Display total track XP relative to next level's threshold, if available
                // For now, stick to Today's XP as per previous implementation.
                // Total XP for level progress could be: "Total XP: ${ref.watch(totalTrackXpProvider)}"
                "Today's XP: $currentXp / ${totalPossibleXpToday.toInt()}",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ), // Slightly less bold than level title
              ),
              const SizedBox(height: 6),
              if (tasksForDisplay.isNotEmpty)
                LinearProgressIndicator(
                  value: progress > 1.0 ? 1.0 : progress,
                  minHeight: 12,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                  borderRadius: BorderRadius.circular(6),
                )
              else
                Text(
                  "No tasks to earn XP from today.",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              // const SizedBox(height: 8), // Removed to bring divider closer
            ],
          ),
        ),

        const Divider(height: 1, indent: 16, endIndent: 16, thickness: 1),

        Padding(
          padding: const EdgeInsets.fromLTRB(
            16.0,
            12.0,
            16.0,
            8.0,
          ), // Adjusted padding
          child: Text(
            "Today's Tasks",
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),

        if (tasksForDisplay.isEmpty)
          const Expanded(
            child: Center(
              child: Text(
                "No tasks for today, or the selected track has no tasks for the current level.",
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 0, bottom: 16.0),
              itemCount: tasksForDisplay.length,
              itemBuilder: (context, index) {
                final todayTask = tasksForDisplay[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 5.0,
                  ),
                  elevation: todayTask.isCompleted ? 1.0 : 2.5,
                  color:
                      todayTask.isCompleted
                          ? Colors.green.withOpacity(0.05)
                          : Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side:
                        todayTask.isCompleted
                            ? BorderSide(
                              color: Colors.green.withOpacity(0.4),
                              width: 1.5,
                            )
                            : BorderSide.none,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 16.0,
                    ),
                    leading: Checkbox(
                      value: todayTask.isCompleted,
                      activeColor: Colors.green,
                      onChanged: (bool? newValue) {
                        if (newValue != null) {
                          ref
                              .read(completionsProvider.notifier)
                              .toggleTaskCompletion(
                                todayTask.id,
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
                        decoration:
                            todayTask.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                        color:
                            todayTask.isCompleted
                                ? Theme.of(context).textTheme.bodySmall?.color
                                : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            // The original description Text widget
                            todayTask.description,
                            style: TextStyle(
                              color:
                                  todayTask.isCompleted
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
                          Builder(
                            // New widget to display streak information
                            builder: (context) {
                              final streakInfo =
                                  streakData[todayTask
                                      .id]; // streakData and todayTask must be in scope
                              if (streakInfo != null &&
                                  streakInfo.streakCount > 0) {
                                final frequencyText =
                                    streakInfo.frequency == Frequency.daily
                                        ? "day"
                                        : "week";
                                final pluralS =
                                    streakInfo.streakCount > 1 ? "s" : "";
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6.0),
                                  child: Text(
                                    "🔥 ${streakInfo.streakCount} ${frequencyText}${pluralS} streak!",
                                    style: TextStyle(
                                      color:
                                          todayTask.isCompleted
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withOpacity(0.7)
                                              : Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink(); // If no streak, display nothing
                            },
                          ),
                        ],
                      ),
                    ),
                    trailing: Text(
                      "XP: ${todayTask.xp}",
                      style: TextStyle(
                        color:
                            todayTask.isCompleted
                                ? Colors.green
                                : Theme.of(context).colorScheme.primary,
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

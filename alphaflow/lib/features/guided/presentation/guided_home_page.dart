import 'package:alphaflow/data/models/today_task.dart';
import 'package:alphaflow/providers/today_tasks_provider.dart';
import 'package:alphaflow/providers/selected_track_provider.dart';
import 'package:alphaflow/providers/task_completions_provider.dart';
import 'package:alphaflow/providers/xp_provider.dart';
import 'package:alphaflow/providers/guided_level_provider.dart';
import 'package:alphaflow/data/models/level_definition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphaflow/providers/guided_task_streaks_provider.dart';
import 'package:alphaflow/data/models/streak_info.dart';
import 'package:alphaflow/data/models/frequency.dart';
import 'package:table_calendar/table_calendar.dart'; // Added
import 'package:alphaflow/providers/calendar_providers.dart'; // Added
import 'package:intl/intl.dart'; // Added for date formatting

// Changed to ConsumerStatefulWidget
class GuidedHomePage extends ConsumerStatefulWidget {
  const GuidedHomePage({super.key});

  @override
  ConsumerState<GuidedHomePage> createState() => _GuidedHomePageState();
}

class _GuidedHomePageState extends ConsumerState<GuidedHomePage> {
  DateTime _focusedDay = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  final DateTime _todayNormalized = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  String _getFormattedDate(DateTime date) {
    if (isSameDay(date, _todayNormalized)) {
      return "Today's Tasks";
    } else if (isSameDay(date, _todayNormalized.subtract(const Duration(days: 1)))) {
      return "Yesterday's Tasks";
    } else {
      return "${DateFormat.yMMMd().format(date)} Tasks";
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedCalendarDateProvider);
    final List<TodayTask> tasksForDisplay = ref.watch(displayedDateTasksProvider);
    ref.watch(completionsProvider); // Keep watching for rebuilds
    final selectedTrackId = ref.watch(selectedTrackProvider);
    final int currentXp = ref.watch(xpProvider); // XP is always for the current day
    final LevelDefinition? currentLevel = ref.watch(currentGuidedLevelProvider);
    final streakData = ref.watch(guidedTaskStreaksProvider);

    final List<TodayTask> actualTodayTasks;
    if (isSameDay(selectedDate, _todayNormalized)) {
      actualTodayTasks = tasksForDisplay;
    } else {
      // If a historical date is selected, tasksForDisplay are for that date.
      // For XP bar, we use these tasks but with currentXp which is always for today.
      actualTodayTasks = tasksForDisplay;
    }

    final double totalPossibleXpForSelectedDate = actualTodayTasks.fold(
      0.0,
      (sum, task) => sum + task.xp,
    );
    final double progress = (totalPossibleXpForSelectedDate > 0)
        ? (currentXp / totalPossibleXpForSelectedDate)
        : 0.0;

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
        // Calendar
        TableCalendar(
          locale: Localizations.localeOf(context).toString(),
          firstDay: _todayNormalized.subtract(const Duration(days: 6)),
          lastDay: _todayNormalized,
          focusedDay: _focusedDay,
          calendarFormat: CalendarFormat.week,
          selectedDayPredicate: (day) => isSameDay(selectedDate, day),
          currentDay: _todayNormalized,
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(fontSize: 17.0, fontWeight: FontWeight.w500),
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
            final normalizedSelectedDay = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
            if (!isSameDay(ref.read(selectedCalendarDateProvider), normalizedSelectedDay)) {
              ref.read(selectedCalendarDateProvider.notifier).state = normalizedSelectedDay;
            }
            // Ensure focusedDay also respects the calendar boundaries if changed by selection
            DateTime newFocusedDay = focusedDay;
            final firstAllowed = _todayNormalized.subtract(const Duration(days: 6));
            final lastAllowed = _todayNormalized;
            if (newFocusedDay.isBefore(firstAllowed)) newFocusedDay = firstAllowed;
            if (newFocusedDay.isAfter(lastAllowed)) newFocusedDay = lastAllowed;

            if (!isSameDay(_focusedDay, newFocusedDay)) {
              setState(() {
                _focusedDay = newFocusedDay;
              });
            }
          },
          onPageChanged: (focusedDay) {
            DateTime newFocusedDay = focusedDay;
            final firstAllowed = _todayNormalized.subtract(const Duration(days: 6));
            final lastAllowed = _todayNormalized;
            if (newFocusedDay.isBefore(firstAllowed)) newFocusedDay = firstAllowed;
            if (newFocusedDay.isAfter(lastAllowed)) newFocusedDay = lastAllowed;

            if (!isSameDay(_focusedDay, newFocusedDay)) {
               setState(() {
                 _focusedDay = newFocusedDay;
               });
            }
          },
        ),
        const Divider(height: 1, thickness: 1),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currentLevel != null)
                Text(
                  "Level ${currentLevel.levelNumber}: ${currentLevel.title} ${currentLevel.icon}",
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
              const SizedBox(height: 10),
              Text(
                isSameDay(selectedDate, _todayNormalized)
                  ? "Today's XP: $currentXp / ${totalPossibleXpForSelectedDate.toInt()}"
                  : "Today's XP: $currentXp (viewing tasks for ${DateFormat.yMMMd().format(selectedDate)})",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              if (isSameDay(selectedDate, _todayNormalized) && actualTodayTasks.isNotEmpty)
                LinearProgressIndicator(
                  value: progress > 1.0 ? 1.0 : progress,
                  minHeight: 12,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                  borderRadius: BorderRadius.circular(6),
                )
              else if (isSameDay(selectedDate, _todayNormalized) && actualTodayTasks.isEmpty)
                 Text("No tasks to earn XP from today.", style: Theme.of(context).textTheme.bodyMedium)
              else if (!isSameDay(selectedDate, _todayNormalized))
                Text("XP progress is shown for the current day only.", style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16, thickness: 1),

        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
          child: Text(
            _getFormattedDate(selectedDate),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),

        if (tasksForDisplay.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                isSameDay(selectedDate, _todayNormalized)
                  ? "No tasks for today, or the selected track has no tasks for the current level."
                  : "No guided tasks recorded for ${DateFormat.yMMMd().format(selectedDate)}.",
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
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5.0),
                  elevation: todayTask.isCompleted ? 1.0 : 2.5,
                  color: todayTask.isCompleted ? Colors.green.withOpacity(0.05) : Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side: todayTask.isCompleted
                        ? BorderSide(color: Colors.green.withOpacity(0.4), width: 1.5)
                        : BorderSide.none,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    leading: Checkbox(
                      value: todayTask.isCompleted,
                      activeColor: Colors.green,
                      onChanged: (bool? newValue) {
                        if (newValue != null) {
                          ref.read(completionsProvider.notifier).toggleTaskCompletion(
                                todayTask.id,
                                selectedDate,
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
                        color: todayTask.isCompleted
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
                            todayTask.description,
                            style: TextStyle(
                              color: todayTask.isCompleted
                                  ? Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7)
                                  : Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                          Builder(
                            builder: (context) {
                              final streakInfo = streakData[todayTask.id];
                              if (streakInfo != null && streakInfo.streakCount > 0) {
                                final frequencyText = streakInfo.frequency == Frequency.daily ? "day" : "week";
                                final pluralS = streakInfo.streakCount > 1 ? "s" : "";
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6.0),
                                  child: Text(
                                    "🔥 ${streakInfo.streakCount} ${frequencyText}${pluralS} streak!",
                                    style: TextStyle(
                                      color: todayTask.isCompleted
                                          ? Theme.of(context).colorScheme.primary.withOpacity(0.7)
                                          : Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ],
                      ),
                    ),
                    trailing: Text(
                      "XP: ${todayTask.xp}",
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

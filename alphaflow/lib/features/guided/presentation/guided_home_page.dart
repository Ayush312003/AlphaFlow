import 'package:alphaflow/data/models/today_task.dart';
import 'package:alphaflow/providers/today_tasks_provider.dart';
// import 'package:alphaflow/providers/selected_track_provider.dart'; // Old
import 'package:alphaflow/providers/task_completions_provider.dart';
import 'package:alphaflow/providers/xp_provider.dart';
import 'package:alphaflow/providers/guided_level_provider.dart';
import 'package:alphaflow/data/models/level_definition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphaflow/providers/guided_task_streaks_provider.dart';
import 'package:alphaflow/data/models/streak_info.dart';
import 'package:alphaflow/data/models/frequency.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:alphaflow/providers/calendar_providers.dart';
import 'package:intl/intl.dart';
// import 'package:alphaflow/providers/app_mode_provider.dart'; // Old, and likely not providing firstActiveDateProvider anymore
import 'package:alphaflow/features/user_profile/application/user_data_providers.dart'; // New provider location
import 'package:alphaflow/providers/selected_track_provider.dart';
import 'package:alphaflow/widgets/manual_sync_widget.dart';

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
    final DateTime? firstActiveDate = ref.watch(firestoreFirstActiveDateProvider); // Changed to firestoreFirstActiveDateProvider
    final List<TodayTask> tasksForDisplay = ref.watch(displayedDateTasksProvider);
    ref.watch(completionsProvider);
    final selectedTrackId = ref.watch(localSelectedTrackProvider); // Changed to local provider
    final int currentSessionXp = ref.watch(xpProvider);
    final LevelDefinition? currentLevel = ref.watch(currentGuidedLevelProvider);
    final streakData = ref.watch(guidedTaskStreaksProvider);

    final double totalPossibleXpForSelectedDate = tasksForDisplay.fold(
      0.0,
      (sum, task) => sum + task.xp,
    );

    double xpEarnedForSelectedDate = 0;
    for (var task in tasksForDisplay) {
      if (task.isCompleted) {
        xpEarnedForSelectedDate += task.xp;
      }
    }

    double uiXpDisplayValue;
    double uiTotalPossibleXp;
    double uiProgressValue;
    String xpTextLabel;

    if (isSameDay(selectedDate, _todayNormalized)) {
      uiXpDisplayValue = currentSessionXp.toDouble();
      uiTotalPossibleXp = totalPossibleXpForSelectedDate;
      xpTextLabel = "Today's XP:";
    } else {
      uiXpDisplayValue = xpEarnedForSelectedDate;
      uiTotalPossibleXp = totalPossibleXpForSelectedDate;
      xpTextLabel = "${DateFormat.yMMMd().format(selectedDate)} XP:";
    }

    uiProgressValue = (uiTotalPossibleXp > 0) ? (uiXpDisplayValue / uiTotalPossibleXp) : 0.0;
    if (uiProgressValue > 1.0) uiProgressValue = 1.0;
    if (uiProgressValue < 0.0) uiProgressValue = 0.0;

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
                "$xpTextLabel ${uiXpDisplayValue.toInt()} / ${uiTotalPossibleXp.toInt()}",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              if (uiTotalPossibleXp > 0)
                LinearProgressIndicator(
                  value: uiProgressValue,
                  minHeight: 12,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                  borderRadius: BorderRadius.circular(6),
                )
              else
                 Text(
                   isSameDay(selectedDate, _todayNormalized)
                     ? "No tasks to earn XP from today."
                     : "No tasks for XP on ${DateFormat.yMMMd().format(selectedDate)}.",
                   style: Theme.of(context).textTheme.bodySmall?.copyWith(
                         color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                       ),
                 ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            _getFormattedDate(selectedDate),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),

        const SizedBox(height: 8),

        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await ref.read(completionsManagerProvider).syncPendingCompletions();
            },
            child: tasksForDisplay.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.task_alt,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isSameDay(selectedDate, _todayNormalized)
                              ? "No tasks for today!"
                              : "No tasks for ${DateFormat.yMMMd().format(selectedDate)}",
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "All caught up! 🎉",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: tasksForDisplay.length,
                    itemBuilder: (context, index) {
                      final task = tasksForDisplay[index];
                      final streakInfo = streakData[task.id];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        child: ListTile(
                          leading: Checkbox(
                            value: task.isCompleted,
                            onChanged: (
                              isSameDay(selectedDate, _todayNormalized) ||
                              (isSameDay(selectedDate, _todayNormalized.subtract(const Duration(days: 1))) &&
                                firstActiveDate != null && firstActiveDate.isBefore(_todayNormalized))
                            )
                                ? (bool? value) {
                                    final completionsManager = ref.read(completionsManagerProvider);
                                    completionsManager.toggleTaskCompletion(
                                      task.id,
                                      selectedDate,
                                      trackId: selectedTrackId,
                                    );
                                  }
                                : null,
                          ),
                          title: Text(
                            task.title,
                            style: TextStyle(
                              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                              color: task.isCompleted
                                  ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                                  : null,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (task.description.isNotEmpty)
                                Text(
                                  task.description,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              if (streakInfo != null && streakInfo.streakCount > 0)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.local_fire_department,
                                      size: 16,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${streakInfo.streakCount} day${streakInfo.streakCount == 1 ? '' : 's'}",
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          trailing: Text(
                            "${task.xp} XP",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: task.isCompleted
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

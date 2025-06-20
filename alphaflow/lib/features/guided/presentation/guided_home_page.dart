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
    final selectedTrackId = ref.watch(firestoreSelectedTrackProvider); // Changed to firestoreSelectedTrackProvider
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
                   style: Theme.of(context).textTheme.bodyMedium
                 ),
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

                final DateTime yesterdayDate = _todayNormalized.subtract(const Duration(days: 1));
                bool canEditYesterday = false;
                if (firstActiveDate != null) {
                  // Yesterday is editable if it's not before the first active date.
                  // (i.e., yesterday is same as firstActiveDate or after firstActiveDate)
                  canEditYesterday = !yesterdayDate.isBefore(firstActiveDate);
                }
                // If firstActiveDate is null (should not happen for a user who has set a mode),
                // canEditYesterday remains false, so yesterday won't be editable by default.
                // This is a safe default.

                final bool isEditable = isSameDay(selectedDate, _todayNormalized) ||
                                        (isSameDay(selectedDate, yesterdayDate) && canEditYesterday);

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
                      onChanged: isEditable
                          ? (bool? newValue) {
                              if (newValue != null) {
                                ref.read(completionsManagerProvider).toggleTaskCompletion( // Changed to completionsManagerProvider
                                      todayTask.id,
                                      selectedDate,
                                      trackId: selectedTrackId,
                                    );
                              }
                            }
                          : null,
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

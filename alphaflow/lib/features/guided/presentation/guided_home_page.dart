import 'package:alphaflow/data/models/today_task.dart';
import 'package:alphaflow/providers/today_tasks_provider.dart';
import 'package:alphaflow/providers/task_completions_provider.dart';
import 'package:alphaflow/providers/xp_provider.dart';
import 'package:alphaflow/providers/guided_level_provider.dart';
import 'package:alphaflow/data/models/level_definition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphaflow/providers/guided_task_streaks_provider.dart';
import 'package:alphaflow/data/models/streak_info.dart';
import 'package:alphaflow/features/user_profile/application/user_data_providers.dart';
import 'package:alphaflow/providers/selected_track_provider.dart';
import 'package:alphaflow/providers/calendar_providers.dart';
import 'package:alphaflow/common/widgets/glassmorphic_components.dart';
import 'package:alphaflow/common/widgets/premium_calendar_strip.dart';
import 'package:alphaflow/common/widgets/xp_progress_section.dart';
import 'package:alphaflow/common/widgets/premium_task_card.dart';
import 'package:alphaflow/core/theme/alphaflow_theme.dart';
import 'package:alphaflow/core/presentation/widgets/xp_cap_popup.dart';
import 'package:intl/intl.dart';
import 'package:alphaflow/features/guided/presentation/analytics_page.dart';

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
    if (_isSameDay(date, _todayNormalized)) {
      return "Today's Tasks";
    } else if (_isSameDay(date, _todayNormalized.subtract(const Duration(days: 1)))) {
      return "Yesterday's Tasks";
    } else {
      return "${DateFormat.yMMMd().format(date)} Tasks";
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedCalendarDateProvider);
    final DateTime? firstActiveDate = ref.watch(firestoreFirstActiveDateProvider);
    final List<TodayTask> tasksForDisplay = ref.watch(displayedDateTasksProvider);
    ref.watch(completionsProvider);
    final selectedTrackId = ref.watch(localSelectedTrackProvider);
    final LevelDefinition? currentLevel = ref.watch(currentGuidedLevelProvider);
    final streakData = ref.watch(guidedTaskStreaksProvider);
    
    // Use the new optimized XP calculations provider
    final xpCalculations = ref.watch(guidedXpCalculationsProvider);

    if (selectedTrackId == null) {
      return Container(
        color: AlphaFlowTheme.guidedBackground,
        child: const Center(
          child: Text(
            "No guided track selected. Please select one from the drawer or main menu.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AlphaFlowTheme.guidedTextPrimary,
              fontSize: 16,
              fontFamily: 'Sora',
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! < -200) {
          // Right-to-left swipe detected
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AnalyticsPage()),
          );
        }
      },
      child: Container(
      color: AlphaFlowTheme.guidedBackground,
      child: Column(
        children: [
          // Calendar Strip
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: PremiumCalendarStrip(
              selectedDate: selectedDate,
              today: _todayNormalized,
              onDateSelected: (selectedDay) {
                final normalizedSelectedDay = DateTime(
                  selectedDay.year, 
                  selectedDay.month, 
                  selectedDay.day
                );
                if (!_isSameDay(ref.read(selectedCalendarDateProvider), normalizedSelectedDay)) {
                  ref.read(selectedCalendarDateProvider.notifier).state = normalizedSelectedDay;
                }
              },
            ),
          ),

          // XP Progress Section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: XpProgressSection(
              currentLevel: currentLevel,
              currentXp: xpCalculations.uiXpDisplayValue,
              totalXp: xpCalculations.uiTotalPossibleXp,
              xpLabel: xpCalculations.xpTextLabel,
              animateOnLoad: true,
            ),
          ),

          // Tasks Section Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              _getFormattedDate(selectedDate),
              style: const TextStyle(
                color: AlphaFlowTheme.guidedTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Sora',
              ),
            ),
          ),

          // Tasks List
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
                            color: AlphaFlowTheme.guidedTextSecondary.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isSameDay(selectedDate, _todayNormalized)
                                ? "No tasks for today!"
                                : "No tasks for ${DateFormat.yMMMd().format(selectedDate)}",
                            style: const TextStyle(
                              color: AlphaFlowTheme.guidedTextSecondary,
                              fontSize: 16,
                              fontFamily: 'Sora',
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "All caught up!",
                            style: TextStyle(
                              color: AlphaFlowTheme.guidedTextSecondary,
                              fontSize: 14,
                              fontFamily: 'Sora',
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: tasksForDisplay.length,
                      itemBuilder: (context, index) {
                        final task = tasksForDisplay[index];
                        final streakInfo = streakData[task.id];
                        
                        // Determine if task is editable
                        final bool isEditable = (
                          _isSameDay(selectedDate, _todayNormalized) ||
                          (_isSameDay(selectedDate, _todayNormalized.subtract(const Duration(days: 1))) &&
                            firstActiveDate != null && firstActiveDate.isBefore(_todayNormalized))
                        );

                        return PremiumTaskCard(
                          key: ValueKey(task.id), // Add key for better performance
                          task: task,
                          streakInfo: streakInfo,
                          isEditable: isEditable,
                          onToggleCompletion: (bool value) async {
                            final completionsManager = ref.read(completionsManagerProvider);
                            final success = await completionsManager.toggleTaskCompletion(
                              task.id,
                              selectedDate,
                              trackId: selectedTrackId,
                            );
                            
                            // Show XP cap popup if completion failed
                            if (success == false && mounted) {
                              showDialog(
                                context: context,
                                barrierDismissible: true,
                                builder: (context) => const XpCapPopup(),
                              );
                            }
                          },
                          animateOnLoad: true,
                        );
                      },
                    ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

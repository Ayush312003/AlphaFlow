import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphaflow/providers/task_completions_provider.dart';
import 'package:alphaflow/features/guided/providers/guided_tracks_provider.dart';
import 'package:alphaflow/data/models/task_completion.dart';
import 'package:alphaflow/data/models/guided_track.dart';
import 'package:alphaflow/features/user_profile/application/user_data_providers.dart';

/// Premium analytics data model containing all aggregated analytics
class PremiumAnalytics {
  final Map<String, int> xpPerWeek;
  final Map<String, int> xpPerSkill;
  final Map<String, int> xpPerDay;
  final int currentStreak;
  final int longestStreak;
  final List<String> bestDays;
  final String? mostImprovedSkill;
  final List<String> recommendations;
  final int totalXp;
  final int totalTasksCompleted;
  final DateTime? firstActiveDate;

  PremiumAnalytics({
    required this.xpPerWeek,
    required this.xpPerSkill,
    required this.xpPerDay,
    required this.currentStreak,
    required this.longestStreak,
    required this.bestDays,
    this.mostImprovedSkill,
    required this.recommendations,
    required this.totalXp,
    required this.totalTasksCompleted,
    this.firstActiveDate,
  });
}

/// Provider for premium analytics
final premiumAnalyticsProvider = Provider<PremiumAnalytics?>((ref) {
  final completionsAsync = ref.watch(combinedCompletionsProvider);
  final guidedTracksAsync = ref.watch(guidedTracksProvider);
  final firstActiveDateAsync = ref.watch(firestoreFirstActiveDateProvider);

  // Wait for all data to load
  if (guidedTracksAsync.isLoading) {
    return null;
  }

  final completions = completionsAsync;
  final guidedTracks = guidedTracksAsync.value ?? [];
  final firstActiveDate = firstActiveDateAsync;

  if (completions.isEmpty) {
    // Return empty analytics if no completions
    return PremiumAnalytics(
      xpPerWeek: {},
      xpPerSkill: {},
      xpPerDay: {},
      currentStreak: 0,
      longestStreak: 0,
      bestDays: [],
      recommendations: [],
      totalXp: 0,
      totalTasksCompleted: 0,
      firstActiveDate: firstActiveDate,
    );
  }

  // Build a taskId -> tag map from guided tracks
  final Map<String, String> taskIdToTag = _buildTaskIdToTagMap(guidedTracks);

  // Aggregate analytics
  final Map<String, int> xpPerWeek = _calculateXpPerWeek(completions);
  final Map<String, int> xpPerSkill = _calculateXpPerSkill(completions, taskIdToTag);
  final Map<String, int> xpPerDay = _calculateXpPerDay(completions);
  final Map<String, int> streaks = _calculateStreaks(completions);
  final List<String> bestDays = _findBestDays(xpPerDay);
  final String? mostImprovedSkill = _findMostImprovedSkill(completions, taskIdToTag);
  final List<String> recommendations = _generateRecommendations(completions, taskIdToTag, guidedTracks);
  final int totalXp = completions.fold(0, (sum, completion) => sum + completion.xpAwarded);
  final int totalTasksCompleted = completions.length;

  return PremiumAnalytics(
    xpPerWeek: xpPerWeek,
    xpPerSkill: xpPerSkill,
    xpPerDay: xpPerDay,
    currentStreak: streaks['current'] ?? 0,
    longestStreak: streaks['longest'] ?? 0,
    bestDays: bestDays,
    mostImprovedSkill: mostImprovedSkill,
    recommendations: recommendations,
    totalXp: totalXp,
    totalTasksCompleted: totalTasksCompleted,
    firstActiveDate: firstActiveDate,
  );
});

/// Builds a map from taskId to skill tag
Map<String, String> _buildTaskIdToTagMap(List<GuidedTrack> guidedTracks) {
  final Map<String, String> taskIdToTag = {};
  
  for (final track in guidedTracks) {
    for (final level in track.levels) {
      for (final task in level.unlockTasks) {
        taskIdToTag[task.id] = task.tag;
      }
    }
  }
  
  return taskIdToTag;
}

/// Calculates XP per week
Map<String, int> _calculateXpPerWeek(List<TaskCompletion> completions) {
  final Map<String, int> xpPerWeek = {};
  
  for (final completion in completions) {
    final week = _getWeekString(completion.date);
    xpPerWeek[week] = (xpPerWeek[week] ?? 0) + completion.xpAwarded;
  }
  
  return xpPerWeek;
}

/// Calculates XP per skill
Map<String, int> _calculateXpPerSkill(List<TaskCompletion> completions, Map<String, String> taskIdToTag) {
  final Map<String, int> xpPerSkill = {};
  
  for (final completion in completions) {
    final tag = taskIdToTag[completion.taskId] ?? 'Unknown';
    xpPerSkill[tag] = (xpPerSkill[tag] ?? 0) + completion.xpAwarded;
  }
  
  return xpPerSkill;
}

/// Calculates XP per day
Map<String, int> _calculateXpPerDay(List<TaskCompletion> completions) {
  final Map<String, int> xpPerDay = {};
  
  for (final completion in completions) {
    final day = _getDayString(completion.date);
    xpPerDay[day] = (xpPerDay[day] ?? 0) + completion.xpAwarded;
  }
  
  return xpPerDay;
}

/// Calculates current and longest streaks
Map<String, int> _calculateStreaks(List<TaskCompletion> completions) {
  if (completions.isEmpty) {
    return {'current': 0, 'longest': 0};
  }

  // Sort completions by date
  final sortedCompletions = List<TaskCompletion>.from(completions)
    ..sort((a, b) => a.date.compareTo(b.date));

  // Get unique days with completions
  final Set<String> daysWithCompletions = {};
  for (final completion in sortedCompletions) {
    daysWithCompletions.add(_getDayString(completion.date));
  }

  final List<String> sortedDays = daysWithCompletions.toList()..sort();
  
  int currentStreak = 0;
  int longestStreak = 0;
  int tempStreak = 0;

  // Calculate streaks
  for (int i = 0; i < sortedDays.length; i++) {
    final currentDay = DateTime.parse(sortedDays[i]);
    
    if (i == 0) {
      tempStreak = 1;
    } else {
      final previousDay = DateTime.parse(sortedDays[i - 1]);
      final daysDifference = currentDay.difference(previousDay).inDays;
      
      if (daysDifference == 1) {
        tempStreak++;
      } else {
        tempStreak = 1;
      }
    }
    
    longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;
  }

  // Check if current streak is still active (last completion was today or yesterday)
  final today = DateTime.now();
  final lastCompletionDay = sortedDays.isNotEmpty ? DateTime.parse(sortedDays.last) : null;
  
  if (lastCompletionDay != null) {
    final daysSinceLastCompletion = today.difference(lastCompletionDay).inDays;
    if (daysSinceLastCompletion <= 1) {
      currentStreak = tempStreak;
    }
  }

  return {
    'current': currentStreak,
    'longest': longestStreak,
  };
}

/// Finds the best days (highest XP)
List<String> _findBestDays(Map<String, int> xpPerDay) {
  if (xpPerDay.isEmpty) return [];

  final sortedDays = xpPerDay.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final maxXp = sortedDays.first.value;
  return sortedDays
      .where((entry) => entry.value == maxXp)
      .map((entry) => entry.key)
      .toList();
}

/// Finds the most improved skill (comparing this week vs last week)
String? _findMostImprovedSkill(List<TaskCompletion> completions, Map<String, String> taskIdToTag) {
  if (completions.isEmpty) return null;

  final now = DateTime.now();
  final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
  final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));

  final Map<String, int> thisWeekXp = {};
  final Map<String, int> lastWeekXp = {};

  for (final completion in completions) {
    final tag = taskIdToTag[completion.taskId] ?? 'Unknown';
    final completionDate = completion.date;

    if (completionDate.isAfter(thisWeekStart.subtract(const Duration(days: 1)))) {
      thisWeekXp[tag] = (thisWeekXp[tag] ?? 0) + completion.xpAwarded;
    } else if (completionDate.isAfter(lastWeekStart.subtract(const Duration(days: 1))) &&
               completionDate.isBefore(thisWeekStart)) {
      lastWeekXp[tag] = (lastWeekXp[tag] ?? 0) + completion.xpAwarded;
    }
  }

  String? mostImprovedSkill;
  int maxImprovement = 0;

  for (final tag in thisWeekXp.keys) {
    final thisWeek = thisWeekXp[tag] ?? 0;
    final lastWeek = lastWeekXp[tag] ?? 0;
    final improvement = thisWeek - lastWeek;

    if (improvement > maxImprovement) {
      maxImprovement = improvement;
      mostImprovedSkill = tag;
    }
  }

  return mostImprovedSkill;
}

/// Generates recommendations based on user activity
List<String> _generateRecommendations(List<TaskCompletion> completions, Map<String, String> taskIdToTag, List<GuidedTrack> guidedTracks) {
  if (completions.isEmpty) return [];

  final recommendations = <String>[];
  final now = DateTime.now();
  final weekAgo = now.subtract(const Duration(days: 7));

  // Find skills with least activity in the last week
  final Map<String, int> recentXpPerSkill = {};
  for (final completion in completions) {
    if (completion.date.isAfter(weekAgo)) {
      final tag = taskIdToTag[completion.taskId] ?? 'Unknown';
      recentXpPerSkill[tag] = (recentXpPerSkill[tag] ?? 0) + completion.xpAwarded;
    }
  }

  // Find skills with no or low activity
  final allSkills = <String>{};
  for (final track in guidedTracks) {
    for (final level in track.levels) {
      for (final task in level.unlockTasks) {
        allSkills.add(task.tag);
      }
    }
  }

  final inactiveSkills = allSkills.where((skill) => 
    (recentXpPerSkill[skill] ?? 0) < 20 // Threshold for "inactive"
  ).toList();

  // Generate recommendations
  if (inactiveSkills.isNotEmpty) {
    recommendations.add("Try completing more ${inactiveSkills.first} tasks to balance your skills.");
  }

  // Streak-based recommendations
  final streaks = _calculateStreaks(completions);
  if (streaks['current'] != null && streaks['current']! > 0) {
    recommendations.add("Great job! You're on a ${streaks['current']} day streak. Keep it up!");
  }

  // Best day recommendations
  final xpPerDay = _calculateXpPerDay(completions);
  final bestDays = _findBestDays(xpPerDay);
  if (bestDays.isNotEmpty) {
    recommendations.add("Your best day was ${bestDays.first}. Try to replicate that success!");
  }

  return recommendations;
}

/// Utility function to get week string (e.g., '2025-W29')
String _getWeekString(DateTime date) {
  // Calculate week of year manually
  final startOfYear = DateTime(date.year, 1, 1);
  final daysSinceStartOfYear = date.difference(startOfYear).inDays;
  final weekOfYear = ((daysSinceStartOfYear + startOfYear.weekday - 1) / 7).floor() + 1;
  return '${date.year}-W$weekOfYear';
}

/// Utility function to get day string (e.g., '2025-07-18')
String _getDayString(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
} 
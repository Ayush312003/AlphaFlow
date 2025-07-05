import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphaflow/features/user_profile/application/user_data_providers.dart';
import 'package:alphaflow/data/models/app_mode.dart';
import 'package:alphaflow/data/models/guided_task.dart';
import 'package:alphaflow/data/models/guided_track.dart';
import 'package:alphaflow/data/models/task_completion.dart';
import 'package:alphaflow/providers/app_mode_provider.dart';
import 'package:alphaflow/providers/selected_track_provider.dart';
import 'package:alphaflow/features/guided/providers/guided_tracks_provider.dart';
import 'package:alphaflow/providers/task_completions_provider.dart';
import 'package:alphaflow/data/local/preferences_service.dart';
import 'package:alphaflow/providers/guided_level_provider.dart';

class XpNotifier extends StateNotifier<int> {
  final PreferencesService _prefsService;
  static const int _dailyXpCap = 200; // Daily XP cap

  XpNotifier(this._prefsService) : super(0) {
    _loadXp();
  }

  void _loadXp() {
    state = _prefsService.loadSessionXp();
  }

  Future<void> _saveXp() async {
    await _prefsService.saveSessionXp(state);
  }

  // Get today's date as a string for tracking daily XP
  String _getTodayKey() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  // Get today's earned XP
  int getTodayEarnedXp() {
    final todayKey = _getTodayKey();
    return _prefsService.loadDailyXp(todayKey);
  }

  // Check if user can earn more XP today
  bool canEarnXpToday(int xpToEarn) {
    final todayEarned = getTodayEarnedXp();
    return (todayEarned + xpToEarn) <= _dailyXpCap;
  }

  // Get remaining XP that can be earned today
  int getRemainingXpToday() {
    final todayEarned = getTodayEarnedXp();
    return (_dailyXpCap - todayEarned).clamp(0, _dailyXpCap);
  }

  // Add XP to today's total
  Future<void> addDailyXp(int xp) async {
    final todayKey = _getTodayKey();
    final currentDailyXp = _prefsService.loadDailyXp(todayKey);
    final newDailyXp = currentDailyXp + xp;
    
    // Cap at daily limit
    final cappedXp = newDailyXp.clamp(0, _dailyXpCap);
    await _prefsService.saveDailyXp(todayKey, cappedXp);
  }

  // Reset daily XP (called at midnight or when needed)
  Future<void> resetDailyXp() async {
    final todayKey = _getTodayKey();
    await _prefsService.saveDailyXp(todayKey, 0);
  }

  // Get the daily XP cap
  int get dailyXpCap => _dailyXpCap;

  Future<void> addXp(int xp) async {
    state += xp;
    await _saveXp();
  }

  Future<void> resetXp() async {
    state = 0;
    await _saveXp();
  }

  // Calculate total XP from completions
  Future<void> calculateTotalXpFromCompletions(List<TaskCompletion> completions) async {
    int totalXp = 0;
    
    for (final completion in completions) {
      // Only count today's completions for session XP
      final today = DateTime.now();
      final completionDate = completion.date;
      
      if (completionDate.year == today.year &&
          completionDate.month == today.month &&
          completionDate.day == today.day) {
        totalXp += completion.xpAwarded;
      }
    }
    
    state = totalXp;
    await _saveXp();
  }

  // Sync session XP with actual completions (for app startup or when needed)
  Future<void> syncSessionXpWithCompletions(List<TaskCompletion> completions) async {
    await calculateTotalXpFromCompletions(completions);
  }
}

final xpProvider = StateNotifierProvider<XpNotifier, int>((ref) {
  final prefsService = ref.watch(preferencesServiceProvider);
  return XpNotifier(prefsService);
});

// Provider to get today's earned XP
final todayEarnedXpProvider = Provider<int>((ref) {
  final xpNotifier = ref.watch(xpProvider.notifier);
  return xpNotifier.getTodayEarnedXp();
});

// Provider to get remaining XP today
final remainingXpTodayProvider = Provider<int>((ref) {
  final xpNotifier = ref.watch(xpProvider.notifier);
  return xpNotifier.getRemainingXpToday();
});

// Provider to check if user can earn XP
final canEarnXpProvider = Provider.family<bool, int>((ref, xpToEarn) {
  final xpNotifier = ref.watch(xpProvider.notifier);
  return xpNotifier.canEarnXpToday(xpToEarn);
});

// Provider for current day XP (for guided mode) - Based on actual completions
final currentDayXpProvider = Provider<int>((ref) {
  final appMode = ref.watch(localAppModeProvider);
  final selectedTrackId = ref.watch(localSelectedTrackProvider);
  final completions = ref.watch(combinedCompletionsProvider);

  if (appMode != AppMode.guided || selectedTrackId == null) {
    return 0;
  }

  // Calculate XP from actual completions for today
  final today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      int currentDayXp = 0;

      for (final completion in completions) {
        final completionDate = DateTime.utc(completion.date.year, completion.date.month, completion.date.day);
        if (completionDate == today && completion.trackId == selectedTrackId) {
          currentDayXp += completion.xpAwarded;
        }
      }
  
      return currentDayXp;
});

// Provider to sync session XP with completions when needed
final syncSessionXpProvider = Provider.family<Future<void>, List<TaskCompletion>>((ref, completions) async {
  final xpNotifier = ref.read(xpProvider.notifier);
  await xpNotifier.syncSessionXpWithCompletions(completions);
});

// Provider for total track XP
final totalTrackXpProvider = Provider<int>((ref) {
  final selectedTrackId = ref.watch(localSelectedTrackProvider);
  final completions = ref.watch(combinedCompletionsProvider);
  final guidedTracksAsync = ref.watch(guidedTracksProvider);

  if (selectedTrackId == null) {
    return 0;
  }

  return guidedTracksAsync.when(
    data: (allGuidedTracks) {
      GuidedTrack? currentTrack;
      try {
        currentTrack = allGuidedTracks.firstWhere((track) => track.id == selectedTrackId);
      } catch (e) {
        print("Error: Could not find selected track with ID $selectedTrackId in totalTrackXpProvider. $e");
        return 0;
      }

      final Map<String, GuidedTask> allTasksInCurrentTrackMap = {};
      for (var level in currentTrack.levels) {
        for (var task in level.unlockTasks) {
          allTasksInCurrentTrackMap[task.id] = task;
        }
      }

      int totalXp = 0;
      for (final completion in completions) {
        if (completion.trackId == selectedTrackId) {
          totalXp += completion.xpAwarded;
        }
      }
      return totalXp;
    },
    loading: () => 0,
    error: (error, stack) {
      print("Error loading guided tracks in totalTrackXpProvider: $error");
      return 0;
    },
  );
});

// Provider to get XP for a specific skill
final skillXpProvider = Provider.family<int, String>((ref, skillTag) {
  final prefsService = ref.watch(preferencesServiceProvider);
  return prefsService.loadSkillXp(skillTag);
});

// Provider to get all skill XPs as a map
final allSkillXpProvider = Provider.family<Map<String, int>, List<String>>((ref, skillTags) {
  final prefsService = ref.watch(preferencesServiceProvider);
  return prefsService.loadAllSkillXp(skillTags);
});

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphaflow/data/models/task_completion.dart';
import 'package:alphaflow/features/auth/application/auth_providers.dart'; // For currentUserIdProvider
import 'package:alphaflow/features/guided/providers/guided_tracks_provider.dart'; // For guidedTracksProvider to get XP
import 'package:alphaflow/data/models/guided_task.dart'; // For GuidedTask type
import 'package:alphaflow/data/models/custom_task.dart'; // For CustomTask type (future use for custom task XP)
import 'package:alphaflow/providers/custom_tasks_provider.dart'; // For customTasksProvider (future use for custom task XP)
import 'package:alphaflow/providers/batch_sync_provider.dart'; // For batch sync functionality
import 'package:alphaflow/providers/xp_provider.dart'; // For XP cap checking
import 'package:flutter/widgets.dart';
import 'package:alphaflow/providers/app_mode_provider.dart'; // For preferencesServiceProvider

final completionsProvider = StreamProvider<List<TaskCompletion>>((ref) async* {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null || userId.isEmpty) {
    yield []; // Return an empty stream if no user is logged in
    return;
  }

  final prefsService = ref.read(preferencesServiceProvider);
  final cachedCompletions = prefsService.loadTaskCompletions();

  if (cachedCompletions != null) {
    yield cachedCompletions;
  }

  final firestore = FirebaseFirestore.instance;
  final collectionRef = firestore
      .collection('users')
      .doc(userId)
      .collection('taskCompletions');

  final stream = collectionRef.snapshots().map((snapshot) {
    try {
      final completions = snapshot.docs
          .map((doc) => TaskCompletion.fromJson(doc.data()))
          .toList();
      prefsService.saveTaskCompletions(completions);
      return completions;
    } catch (e, stackTrace) {
      print('Error parsing completions snapshot: $e');
      print(stackTrace);
      return cachedCompletions ?? [];
    }
  });

  yield* stream;
});

// Provider for local completions state (for immediate UI updates)
final localCompletionsProvider = StateNotifierProvider<LocalCompletionsNotifier, List<TaskCompletion>>((ref) {
  return LocalCompletionsNotifier();
});

// Notifier for managing local completions state
class LocalCompletionsNotifier extends StateNotifier<List<TaskCompletion>> {
  LocalCompletionsNotifier() : super([]);

  void addCompletion(TaskCompletion completion) {
    // Check if completion already exists
    final existingIndex = state.indexWhere((c) => 
      c.taskId == completion.taskId && 
      c.trackId == completion.trackId && 
      c.date.isAtSameMomentAs(completion.date)
    );
    
    if (existingIndex >= 0) {
      // Update existing completion
      final newState = List<TaskCompletion>.from(state);
      newState[existingIndex] = completion;
      state = newState;
    } else {
      // Add new completion
      state = [...state, completion];
    }
  }

  void removeCompletion(String taskId, String? trackId, DateTime date) {
    state = state.where((c) => 
      !(c.taskId == taskId && 
        c.trackId == trackId && 
        c.date.isAtSameMomentAs(date))
    ).toList();
  }

  void clearAll() {
    state = [];
  }

  void syncWithFirestore(List<TaskCompletion> firestoreCompletions) {
    state = firestoreCompletions;
  }

  /// Initializes local state with Firestore completions
  /// This should be called on app startup to ensure consistency
  void initializeWithFirestore(List<TaskCompletion> firestoreCompletions) {
    if (state.isEmpty) {
      // Only initialize if local state is empty to avoid overwriting recent changes
      state = firestoreCompletions;
    }
  }
}

// Combined provider that merges local and Firestore completions
final combinedCompletionsProvider = Provider<List<TaskCompletion>>((ref) {
  final firestoreCompletionsAsync = ref.watch(completionsProvider);
  final localCompletions = ref.watch(localCompletionsProvider);
  
  // Get current Firestore completions (or empty list if still loading/error)
  final firestoreCompletions = firestoreCompletionsAsync.asData?.value ?? [];
  
  // Merge local and Firestore completions, with local taking precedence
  final Map<String, TaskCompletion> mergedCompletions = {};
  
  // Add Firestore completions first
  for (final completion in firestoreCompletions) {
    final key = '${completion.taskId}_${completion.trackId ?? 'null'}_${completion.date.toIso8601String()}';
    mergedCompletions[key] = completion;
  }
  
  // Override with local completions (these take precedence)
  for (final completion in localCompletions) {
    final key = '${completion.taskId}_${completion.trackId ?? 'null'}_${completion.date.toIso8601String()}';
    mergedCompletions[key] = completion;
  }
  
  return mergedCompletions.values.toList();
});

// Separate provider for initializing local completions with Firestore data
final localCompletionsInitializerProvider = Provider<void>((ref) {
  final firestoreCompletionsAsync = ref.watch(completionsProvider);
  final localCompletionsNotifier = ref.read(localCompletionsProvider.notifier);
  
  // Initialize local state with Firestore data when it becomes available
  firestoreCompletionsAsync.whenData((firestoreCompletions) {
    // Use a post-frame callback to avoid provider modification during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      localCompletionsNotifier.initializeWithFirestore(firestoreCompletions);
    });
  });
});

// Manages operations related to task completions
class CompletionsManager {
  final String? _userId;
  final FirebaseFirestore _firestore;
  final Ref _ref; // Changed Reader to Ref. Riverpod reader to access other providers

  CompletionsManager(this._userId, this._firestore, this._ref); // Changed _read to _ref

  /// Toggles task completion for both guided and custom tasks
  /// Guided tasks use batch sync and are subject to daily XP cap
  /// Custom tasks are stored locally only and don't have XP cap restrictions
  /// Returns true if completion was successful, false if XP cap was reached (guided tasks only)
  Future<bool> toggleTaskCompletion(
    String taskId,
    DateTime date, {
    String? trackId,
  }) async {
    if (_userId == null || _userId!.isEmpty) {
      print("User not logged in. Cannot toggle task completion.");
      return false;
    }

    final normalizedDate = DateTime.utc(date.year, date.month, date.day);

    if (trackId != null) {
      // Guided task - use immediate local update + background sync
      return await _toggleGuidedTaskCompletion(taskId, trackId, normalizedDate);
    } else {
      // Custom task - store locally only
      return await _toggleCustomTaskCompletion(taskId, normalizedDate);
    }
  }

  /// Handles guided task completion using immediate local update + background sync
  /// Returns true if completion was successful, false if XP cap was reached
  Future<bool> _toggleGuidedTaskCompletion(
    String taskId,
    String trackId,
    DateTime normalizedDate,
  ) async {
    final localCompletionsNotifier = _ref.read(localCompletionsProvider.notifier);
    final batchSyncService = _ref.read(batchSyncServiceProvider);
    final syncStatusNotifier = _ref.read(syncStatusProvider.notifier);

    // Check if completion already exists locally (no Firestore query for performance)
    final existingCompletions = localCompletionsNotifier.state;
    final completionExists = existingCompletions.any((comp) => 
      comp.taskId == taskId && 
      comp.trackId == trackId && 
      comp.date.isAtSameMomentAs(normalizedDate)
    );

    if (completionExists) {
      // Remove completion - immediate local update
      localCompletionsNotifier.removeCompletion(taskId, trackId, normalizedDate);
      
      // Background sync to Firestore
      syncStatusNotifier.setSyncing();
      try {
        await batchSyncService.removeGuidedCompletion(
          taskId: taskId,
          trackId: trackId,
          date: normalizedDate,
        );
        syncStatusNotifier.setSuccess();
      } catch (e) {
        syncStatusNotifier.setError("Failed to remove completion: $e");
        print("Error removing guided completion: $e");
      }
      return true;
    } else {
      // Check XP cap before adding completion
      int xpToAward = _getGuidedTaskXP(taskId, trackId);
      final xpNotifier = _ref.read(xpProvider.notifier);
      
      if (!xpNotifier.canEarnXpToday(xpToAward)) {
        // XP cap reached, don't add completion
        return false;
      }
      
      // Add completion - immediate local update
      final newCompletion = TaskCompletion(
        taskId: taskId,
        date: normalizedDate,
        trackId: trackId,
        xpAwarded: xpToAward,
      );
      
      localCompletionsNotifier.addCompletion(newCompletion);
      
      // Add to daily XP tracking
      await xpNotifier.addDailyXp(xpToAward);
      
      // --- Skill XP Persistence ---
      // Find the GuidedTask to get its tag
      final guidedTracksAsync = _ref.read(guidedTracksProvider);
      final prefsService = _ref.read(preferencesServiceProvider);
      
      // Handle skill XP persistence synchronously
      guidedTracksAsync.when(
        data: (allGuidedTracks) {
          for (var track in allGuidedTracks) {
            if (track.id == trackId) {
              for (var level in track.levels) {
                try {
                  final task = level.unlockTasks.firstWhere((t) => t.id == taskId);
                  final skillTag = task.tag;
                  final prevSkillXp = prefsService.loadSkillXp(skillTag);
                  // Use unawaited to avoid blocking the UI
                  prefsService.saveSkillXp(skillTag, prevSkillXp + xpToAward);
                  break;
                } catch (e) {
                  // Task not found in this level
                }
              }
            }
          }
        },
        loading: () {},
        error: (error, stack) {},
      );
      // --- End Skill XP Persistence ---
      
      // Background sync to Firestore
      syncStatusNotifier.setSyncing();
      try {
        await batchSyncService.addGuidedCompletion(
          taskId: taskId,
          trackId: trackId,
          date: normalizedDate,
          xpAwarded: xpToAward,
        );
        syncStatusNotifier.setSuccess();
      } catch (e) {
        syncStatusNotifier.setError("Failed to add completion: $e");
        print("Error adding guided completion: $e");
      }
      return true;
    }
  }

  /// Handles custom task completion using local storage only
  /// Custom tasks don't have XP cap restrictions since they don't use the XP system
  /// Returns true if completion was successful
  Future<bool> _toggleCustomTaskCompletion(
    String taskId,
    DateTime normalizedDate,
  ) async {
    final localCompletionsNotifier = _ref.read(localCompletionsProvider.notifier);
    
    // Check if completion already exists locally
    final existingCompletions = localCompletionsNotifier.state;
    final completionExists = existingCompletions.any((comp) => 
      comp.taskId == taskId && 
      comp.trackId == null && // Custom tasks have no trackId
      comp.date.isAtSameMomentAs(normalizedDate)
    );

    if (completionExists) {
      // Remove completion
      localCompletionsNotifier.removeCompletion(taskId, null, normalizedDate);
      print("Removed custom task completion: $taskId for ${normalizedDate.toIso8601String()}");
      return true;
    } else {
      // Add completion - custom tasks get 1 XP by default but don't count towards daily cap
      const int customTaskXp = 1;
      
      // Add completion - custom tasks get 1 XP by default
      final newCompletion = TaskCompletion(
        taskId: taskId,
        date: normalizedDate,
        trackId: null, // Custom tasks have no trackId
        xpAwarded: customTaskXp, // Default XP for custom tasks
      );
      
      localCompletionsNotifier.addCompletion(newCompletion);
      
      // Note: Custom tasks don't count towards daily XP cap since they don't have a proper XP system
      // They just get a default 1 XP for tracking purposes
      
      print("Added custom task completion: $taskId for ${normalizedDate.toIso8601String()}");
      return true;
    }
  }

  /// Gets existing guided completions from Firestore for a specific task and date
  Future<List<TaskCompletion>> _getExistingGuidedCompletions(
    String taskId,
    DateTime normalizedDate,
  ) async {
    if (_userId == null || _userId!.isEmpty) return [];

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('taskCompletions')
          .where('taskId', isEqualTo: taskId)
          .where('date', isEqualTo: Timestamp.fromDate(normalizedDate))
          .get();

      return querySnapshot.docs
          .map((doc) => TaskCompletion.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print("Error getting existing guided completions: $e");
      return [];
    }
  }

  /// Gets XP value for a guided task
  int _getGuidedTaskXP(String taskId, String trackId) {
    final guidedTracksAsync = _ref.read(guidedTracksProvider);
    
    // Handle async loading of guided tracks
    return guidedTracksAsync.when(
      data: (allGuidedTracks) {
        for (var track in allGuidedTracks) {
          if (track.id == trackId) {
            for (var level in track.levels) {
              try {
                final task = level.unlockTasks.firstWhere((t) => t.id == taskId);
                return task.xp;
              } catch (e) {
                // Task not found in this level
              }
            }
          }
        }
        return 0; // Default XP if task not found
      },
      loading: () => 0,
      error: (error, stack) {
        print("Error loading guided tracks in _getGuidedTaskXP: $error");
        return 0;
      },
    );
  }

  /// Clears all guided task completions from Firestore
  Future<void> clearGuidedTaskCompletions() async {
    if (_userId == null || _userId!.isEmpty) {
      print("User not logged in. Cannot clear guided task completions.");
      return;
    }
    
    final CollectionReference completionsRef = _firestore
        .collection('users')
        .doc(_userId)
        .collection('taskCompletions');

    final querySnapshot = await completionsRef
        .where('trackId', isNotEqualTo: null)
        .get();

    WriteBatch batch = _firestore.batch();
    for (var doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    
    // Also clear pending completions and local state
    final batchSyncService = _ref.read(batchSyncServiceProvider);
    await batchSyncService.clearPendingCompletions();
    
    final localCompletionsNotifier = _ref.read(localCompletionsProvider.notifier);
    localCompletionsNotifier.clearAll();
  }

  /// Manually triggers a sync of pending completions
  Future<void> syncPendingCompletions() async {
    final batchSyncService = _ref.read(batchSyncServiceProvider);
    final syncStatusNotifier = _ref.read(syncStatusProvider.notifier);
    
    syncStatusNotifier.setSyncing();
    try {
      final success = await batchSyncService.syncPendingCompletions();
      if (success) {
        syncStatusNotifier.setSuccess();
      } else {
        syncStatusNotifier.setError("Sync failed");
      }
    } catch (e) {
      syncStatusNotifier.setError("Sync error: $e");
    }
  }

  /// Syncs pending completions on app startup
  /// This ensures any pending changes from previous sessions are synced
  Future<void> syncOnStartup() async {
    final batchSyncService = _ref.read(batchSyncServiceProvider);
    
    try {
      final success = await batchSyncService.syncPendingCompletions();
      if (success) {
        print("CompletionsManager: Successfully synced pending completions on startup");
      } else {
        print("CompletionsManager: Failed to sync pending completions on startup");
      }
    } catch (e) {
      print("CompletionsManager: Error syncing pending completions on startup: $e");
    }
  }
}

// Provider for CompletionsManager
final completionsManagerProvider = Provider<CompletionsManager>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  // final firestore = ref.watch(firebaseFirestoreProvider); // Assuming a provider for FirebaseFirestore.instance if needed elsewhere
  final firestore = FirebaseFirestore.instance;
  return CompletionsManager(userId, firestore, ref); // Changed ref.read to ref
});

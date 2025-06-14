import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphaflow/data/models/task_completion.dart';
import 'package:alphaflow/features/auth/application/auth_providers.dart'; // For currentUserIdProvider
import 'package:alphaflow/features/guided/providers/guided_tracks_provider.dart'; // For guidedTracksProvider to get XP
import 'package:alphaflow/data/models/guided_task.dart'; // For GuidedTask type
import 'package:alphaflow/data/models/custom_task.dart'; // For CustomTask type (future use for custom task XP)
import 'package:alphaflow/providers/custom_tasks_provider.dart'; // For customTasksProvider (future use for custom task XP)

// Provider that streams the list of task completions from Firestore
final completionsProvider = StreamProvider<List<TaskCompletion>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null || userId.isEmpty) {
    return Stream.value([]); // Return an empty stream if no user is logged in
  }

  final firestore = FirebaseFirestore.instance;
  final collectionRef = firestore
      .collection('users')
      .doc(userId)
      .collection('taskCompletions');

  return collectionRef.snapshots().map((snapshot) {
    try {
      return snapshot.docs
          .map((doc) => TaskCompletion.fromJson(doc.data()))
          .toList();
    } catch (e, stackTrace) {
      print('Error parsing completions snapshot: \$e');
      print(stackTrace);
      // Depending on how strict you want to be, you could return an empty list
      // or rethrow to indicate a critical error to an error handler provider.
      return [];
    }
  });
});

// Manages operations related to task completions
class CompletionsManager {
  final String? _userId;
  final FirebaseFirestore _firestore;
  final Ref _ref; // Changed Reader to Ref. Riverpod reader to access other providers

  CompletionsManager(this._userId, this._firestore, this._ref); // Changed _read to _ref

  Future<void> toggleTaskCompletion(
    String taskId,
    DateTime date, {
    String? trackId,
    // Custom tasks are not explicitly handled for XP here yet, focus on guided.
    // bool isCustomTask = false,
  }) async {
    if (_userId == null || _userId!.isEmpty) {
      print("User not logged in. Cannot toggle task completion.");
      return;
    }

    final normalizedDate = DateTime.utc(date.year, date.month, date.day);
    final CollectionReference completionsRef = _firestore
        .collection('users')
        .doc(_userId)
        .collection('taskCompletions');

    // Query for existing completion
    final querySnapshot = await completionsRef
        .where('taskId', isEqualTo: taskId)
        .where('date', isEqualTo: Timestamp.fromDate(normalizedDate))
        // .where('trackId', isEqualTo: trackId) // trackId can be null, this might not be needed if taskId+date is unique enough
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // Completion exists, so remove it
      await completionsRef.doc(querySnapshot.docs.first.id).delete();
    } else {
      // Completion does not exist, so add it
      int xpToAward = 0;
      // Fetch XP for the task
      if (trackId != null) { // Guided Task
        final allGuidedTracks = _ref.read(guidedTracksProvider); // Changed _read to _ref.read
        for (var track in allGuidedTracks) {
          if (track.id == trackId) {
            for (var level in track.levels) {
              try {
                final task = level.unlockTasks.firstWhere((t) => t.id == taskId);
                xpToAward = task.xp;
                break;
              } catch (e) {
                // Task not found in this level
              }
            }
          }
          if (xpToAward > 0) break;
        }
      } else {
        // TODO: Handle XP for custom tasks if they have XP
        // final allCustomTasks = _read(customTasksProvider);
        // try {
        //   final task = allCustomTasks.firstWhere((t) => t.id == taskId);
        //   xpToAward = task.xp ?? 0; // Assuming CustomTask has an optional xp field
        // } catch (e) {
        //   // Task not found
        // }
      }

      final newCompletion = TaskCompletion(
        taskId: taskId,
        date: normalizedDate, // Already normalized
        trackId: trackId,
        xpAwarded: xpToAward,
      );
      await completionsRef.add(newCompletion.toJson());
    }
  }

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
  }
}

// Provider for CompletionsManager
final completionsManagerProvider = Provider<CompletionsManager>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  // final firestore = ref.watch(firebaseFirestoreProvider); // Assuming a provider for FirebaseFirestore.instance if needed elsewhere
  final firestore = FirebaseFirestore.instance;
  return CompletionsManager(userId, firestore, ref); // Changed ref.read to ref
});

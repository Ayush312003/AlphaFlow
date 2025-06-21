import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../local/preferences_service.dart';
import '../models/task_completion.dart';

/// Service for batch syncing guided task completions to Firestore
/// This reduces Firestore costs by batching operations instead of individual writes
class BatchSyncService {
  final FirebaseFirestore _firestore;
  final PreferencesService _prefsService;
  final String? _userId;

  BatchSyncService(this._firestore, this._prefsService, this._userId);

  /// Syncs all pending completions to Firestore in a single batch operation
  /// Returns true if sync was successful, false otherwise
  Future<bool> syncPendingCompletions() async {
    if (_userId == null || _userId!.isEmpty) {
      if (kDebugMode) {
        print("BatchSyncService: No user ID available for sync");
      }
      return false;
    }

    final pendingCompletions = _prefsService.getPendingCompletions();
    if (pendingCompletions.isEmpty) {
      if (kDebugMode) {
        print("BatchSyncService: No pending completions to sync");
      }
      return true; // No work to do, consider it successful
    }

    if (kDebugMode) {
      print("BatchSyncService: Syncing ${pendingCompletions.length} pending completions");
    }

    try {
      final batch = _firestore.batch();
      final completionsRef = _firestore
          .collection('users')
          .doc(_userId)
          .collection('taskCompletions');

      final List<Map<String, dynamic>> successfullySynced = [];

      for (final completionData in pendingCompletions) {
        try {
          // Validate completion data
          if (!_isValidCompletionData(completionData)) {
            if (kDebugMode) {
              print("BatchSyncService: Invalid completion data: $completionData");
            }
            continue;
          }

          // Convert date string back to Timestamp for Firestore
          final Map<String, dynamic> firestoreData = Map<String, dynamic>.from(completionData);
          if (firestoreData['date'] is String) {
            final dateString = firestoreData['date'] as String;
            final date = DateTime.parse(dateString);
            firestoreData['date'] = Timestamp.fromDate(date);
          }

          // Create a unique document ID for this completion
          final docId = _generateCompletionDocId(firestoreData);
          final docRef = completionsRef.doc(docId);

          // Add to batch - use set with merge to ensure document is created
          batch.set(docRef, firestoreData, SetOptions(merge: true));
          successfullySynced.add(completionData);

          if (kDebugMode) {
            print("BatchSyncService: Added completion to batch: ${completionData['taskId']} for ${completionData['date']}");
          }
        } catch (e) {
          if (kDebugMode) {
            print("BatchSyncService: Error processing completion $completionData: $e");
          }
        }
      }

      // Commit the batch
      await batch.commit();

      // Remove successfully synced completions from pending queue
      if (successfullySynced.isNotEmpty) {
        await _prefsService.removePendingCompletions(successfullySynced);
        if (kDebugMode) {
          print("BatchSyncService: Successfully synced ${successfullySynced.length} completions");
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print("BatchSyncService: Error during batch sync: $e");
      }
      return false;
    }
  }

  /// Syncs pending completions when app opens
  Future<void> syncOnAppOpen() async {
    if (kDebugMode) {
      print("BatchSyncService: Syncing on app open...");
    }
    await syncPendingCompletions();
  }

  /// Syncs pending completions when app closes
  Future<void> syncOnAppClose() async {
    if (kDebugMode) {
      print("BatchSyncService: Syncing on app close...");
    }
    await syncPendingCompletions();
  }

  /// Syncs pending completions when connectivity changes
  Future<void> syncOnConnectivityChange(bool isConnected) async {
    if (isConnected) {
      if (kDebugMode) {
        print("BatchSyncService: Connectivity restored, syncing pending completions...");
      }
      await syncPendingCompletions();
    } else {
      if (kDebugMode) {
        print("BatchSyncService: Connectivity lost, will sync when connection restored");
      }
    }
  }

  /// Adds a guided task completion to the pending sync queue
  /// This will be synced to Firestore in batches
  Future<void> addGuidedCompletion({
    required String taskId,
    required String trackId,
    required DateTime date,
    required int xpAwarded,
  }) async {
    final normalizedDate = DateTime.utc(date.year, date.month, date.day);
    
    final completionData = {
      'taskId': taskId,
      'trackId': trackId,
      'date': normalizedDate.toIso8601String(), // Store as ISO string for SharedPreferences
      'xpAwarded': xpAwarded,
    };

    await _prefsService.addPendingCompletion(completionData);
    
    if (kDebugMode) {
      print("BatchSyncService: Added guided completion to pending queue: $taskId for ${normalizedDate.toIso8601String()}");
    }
  }

  /// Removes a guided task completion from the pending sync queue
  /// Useful for "un-completing" tasks
  Future<void> removeGuidedCompletion({
    required String taskId,
    required String trackId,
    required DateTime date,
  }) async {
    final normalizedDate = DateTime.utc(date.year, date.month, date.day);
    
    final completionData = {
      'taskId': taskId,
      'trackId': trackId,
      'date': normalizedDate.toIso8601String(), // Store as ISO string
      'xpAwarded': 0, // XP doesn't matter for removal
    };

    // Remove from pending queue
    await _prefsService.removePendingCompletions([completionData]);
    
    // Also remove from Firestore if it exists there
    if (_userId != null && _userId!.isNotEmpty) {
      try {
        final docId = _generateCompletionDocId({
          ...completionData,
          'date': Timestamp.fromDate(normalizedDate), // Convert to Timestamp for Firestore
        });
        
        // Delete the document from Firestore
        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('taskCompletions')
            .doc(docId)
            .delete();
            
        if (kDebugMode) {
          print("BatchSyncService: Removed guided completion from Firestore: $taskId for ${normalizedDate.toIso8601String()}");
        }
      } catch (e) {
        if (kDebugMode) {
          print("BatchSyncService: Error removing completion from Firestore: $e");
        }
      }
    }
  }

  /// Gets the count of pending completions
  int getPendingCompletionsCount() {
    return _prefsService.getPendingCompletions().length;
  }

  /// Clears all pending completions from the queue
  /// Use this after successful batch sync or when clearing all data
  Future<void> clearPendingCompletions() async {
    await _prefsService.clearPendingCompletions();
    if (kDebugMode) {
      print("BatchSyncService: Cleared all pending completions");
    }
  }

  /// Validates completion data before syncing
  bool _isValidCompletionData(Map<String, dynamic> data) {
    return data.containsKey('taskId') &&
           data.containsKey('trackId') &&
           data.containsKey('date') &&
           data.containsKey('xpAwarded') &&
           data['taskId'] is String &&
           data['trackId'] is String &&
           (data['date'] is String || data['date'] is Timestamp) &&
           data['xpAwarded'] is int;
  }

  /// Generates a unique document ID for a completion
  /// This ensures consistent document IDs and prevents duplicates
  String _generateCompletionDocId(Map<String, dynamic> completionData) {
    final taskId = completionData['taskId'] as String;
    final trackId = completionData['trackId'] as String;
    
    DateTime date;
    if (completionData['date'] is Timestamp) {
      date = (completionData['date'] as Timestamp).toDate();
    } else if (completionData['date'] is String) {
      date = DateTime.parse(completionData['date'] as String);
    } else {
      throw ArgumentError('Invalid date format in completion data');
    }
    
    final dateString = date.toIso8601String().substring(0, 10); // YYYY-MM-DD format
    
    return '${taskId}_${trackId}_$dateString';
  }
} 
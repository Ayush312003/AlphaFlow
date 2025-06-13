import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alphaflow/data/models/app_mode.dart';
import 'package:alphaflow/data/models/user_data.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:alphaflow/data/local/preferences_service.dart'; // For migration
import 'package:alphaflow/data/models/task_completion.dart' as old_completion_model; // Alias for old model
import 'package:alphaflow/data/models/guided_track.dart'; // For XP lookup
import 'package:alphaflow/data/models/level_definition.dart'; // For LevelDefinition

class UserDataService {
  final FirebaseFirestore _firestore;
  static const String _migrationFlagKey = 'hasMigratedUserDataToFirestore_v1';


  UserDataService(this._firestore);

  DocumentReference<Map<String, dynamic>> _userDocRef(String userId) {
    return _firestore.collection('users').doc(userId);
  }

  Future<void> ensureUserDataDocumentExists(String userId) async {
    final docRef = _userDocRef(userId);
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      try {
        await docRef.set({});
        if (kDebugMode) {
          print("Created empty user document for userId: \$userId");
        }
      } catch (e) {
        if (kDebugMode) {
          print("Error ensuring user document exists for userId: \$userId, error: \$e");
        }
      }
    }
  }

  Stream<UserData> streamUserData(String userId) {
    final docRef = _userDocRef(userId);
    return docRef.snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return UserData(appMode: null, selectedTrackId: null, firstActiveDate: null);
      }
      return UserData.fromFirestore(snapshot);
    }).handleError((error) {
      if (kDebugMode) {
        print("Error streaming user data for userId: \$userId, error: \$error");
      }
      return UserData(appMode: null, selectedTrackId: null, firstActiveDate: null);
    });
  }

  Future<void> updateAppMode(String userId, AppMode mode) async {
    final docRef = _userDocRef(userId);
    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        final Map<String, dynamic> updates = {'appMode': mode.toShortString()};

        if (!snapshot.exists || snapshot.data()?['firstActiveDate'] == null) {
          updates['firstActiveDate'] = Timestamp.fromDate(DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day));
           if (kDebugMode) {
             print("Setting firstActiveDate for userId: \$userId as part of appMode update");
           }
        }
        if (!snapshot.exists){
            transaction.set(docRef, updates);
        } else {
            transaction.update(docRef, updates);
        }
      });
      if (kDebugMode) {
        print("Updated appMode for userId: \$userId to \${mode.toShortString()}");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error updating appMode for userId: \$userId, error: \$e");
      }
    }
  }

  Future<void> clearAppMode(String userId) async {
    try {
      await _userDocRef(userId).update({'appMode': FieldValue.delete()});
      if (kDebugMode) {
        print("Cleared appMode for userId: \$userId");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error clearing appMode for userId: \$userId, error: \$e");
      }
    }
  }

  Future<void> updateSelectedTrack(String userId, String? trackId) async {
    final Map<String, dynamic> updateData = {};
    if (trackId == null) {
      updateData['selectedTrackId'] = FieldValue.delete();
    } else {
      updateData['selectedTrackId'] = trackId;
    }
    try {
      await _userDocRef(userId).set(updateData, SetOptions(merge: true));
      if (kDebugMode) {
        print("Updated selectedTrackId for userId: \$userId to \$trackId");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error updating selectedTrackId for userId: \$userId, error: \$e");
      }
    }
  }

  Future<void> migrateUserDataIfNeeded(
    String userId,
    PreferencesService prefsService,
    List<GuidedTrack> allGuidedTracks
  ) async {
    if (prefsService.getBool(_migrationFlagKey, defaultValue: false) == true) {
        if (kDebugMode) {
          print("Migration already completed for userId: \$userId. Skipping.");
        }
        return;
    }
    if (kDebugMode) {
      print("Starting data migration to Firestore for userId: \$userId...");
    }

    await ensureUserDataDocumentExists(userId); // Should have been called already, but safe to call again.

    AppMode? localAppMode = prefsService.getAppMode();
    String? localSelectedTrackId = prefsService.getSelectedTrack();
    DateTime? localFirstActiveDate = prefsService.loadFirstActiveDate();
    List<old_completion_model.TaskCompletion> localCompletions = prefsService.loadCompletions();

    Map<String, dynamic> userDocUpdates = {};
    bool userDocNeedsUpdate = false;

    if (localAppMode != null) {
        userDocUpdates['appMode'] = localAppMode.toShortString();
        userDocNeedsUpdate = true;
    }
    if (localSelectedTrackId != null) {
        userDocUpdates['selectedTrackId'] = localSelectedTrackId;
        userDocNeedsUpdate = true;
    }
    // Important: Only migrate SharedPreferences firstActiveDate if Firestore one doesn't exist yet.
    // The ensureUserDataDocumentExists or initial updateAppMode might have set one based on current date.
    // The one from SharedPreferences is the true original one.
    final userDocSnapshot = await _userDocRef(userId).get();
    if (localFirstActiveDate != null && (userDocSnapshot.data()?['firstActiveDate'] == null)) {
        userDocUpdates['firstActiveDate'] = Timestamp.fromDate(localFirstActiveDate);
        userDocNeedsUpdate = true;
    } else if (localFirstActiveDate == null && (userDocSnapshot.data()?['firstActiveDate'] == null) && localAppMode != null) {
        // If no firstActiveDate from prefs, and none in Firestore, AND an app mode was set (implying activity)
        // then set firstActiveDate to now (or a very old date if completions exist before it).
        // For simplicity, if localAppMode exists, it implies activity; set firstActiveDate.
        // This case is mostly for users who used app before firstActiveDate was tracked even in prefs.
        // The most robust is to check earliest completion, but for now, this is simpler.
         userDocUpdates['firstActiveDate'] = Timestamp.fromDate(DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day));
         userDocNeedsUpdate = true;
    }


    Map<String, Map<String, dynamic>> trackProgressData = {};
    List<Map<String, dynamic>> firestoreCompletionsData = [];
    Map<String, int> taskXpLookup = {};
    for (var track in allGuidedTracks) {
        for (var level in track.levels) {
            for (var task in level.unlockTasks) {
                taskXpLookup[task.id] = task.xp;
            }
        }
    }
    Map<String, int> trackXpTotals = {};

    for (var localComp in localCompletions) {
        int xp = taskXpLookup[localComp.taskId] ?? 0;
        // The old TaskCompletion model's date is already normalized DateTime.
        // The new TaskCompletion model (not used here for writing directly) expects Timestamp.
        firestoreCompletionsData.add({
            'taskId': localComp.taskId,
            'date': Timestamp.fromDate(localComp.date),
            'trackId': localComp.trackId,
            'xpAwarded': xp, // Old completions didn't store this, so we look it up.
        });

        if (localComp.trackId != null) {
            trackXpTotals[localComp.trackId!] = (trackXpTotals[localComp.trackId!] ?? 0) + xp;
        }
    }

    for (var entry in trackXpTotals.entries) {
        String trackId = entry.key;
        int totalXp = entry.value;
        GuidedTrack? currentTrack;
        try {
            currentTrack = allGuidedTracks.firstWhere((t) => t.id == trackId);
        } catch (e) { /* Track not found in current guided_tracks.dart, skip */ }

        if (currentTrack != null) {
            int currentLevelNum = 1; // Default to level 1
             // Find the highest level achieved
            for (int i = currentTrack.levels.length - 1; i >= 0; i--) {
                final level = currentTrack.levels[i];
                if (totalXp >= level.xpThreshold) {
                    currentLevelNum = level.levelNumber;
                    break;
                }
            }
            trackProgressData[trackId] = {
                'totalXP': totalXp,
                'currentLevelNumber': currentLevelNum,
            };
        }
    }
    if (trackProgressData.isNotEmpty) {
        userDocUpdates['trackProgress'] = trackProgressData;
        userDocNeedsUpdate = true;
    }

    WriteBatch batch = _firestore.batch();
    DocumentReference userRef = _userDocRef(userId);

    if (userDocNeedsUpdate) {
        batch.set(userRef, userDocUpdates, SetOptions(merge: true));
    }

    CollectionReference completionsColRef = userRef.collection('taskCompletions');
    // To prevent duplicates if migration runs multiple times (though flag should stop it),
    // ideally, we'd query existing Firestore completions for the user for these dates/tasks.
    // For a one-time migration, this direct batch set is usually okay if flag is reliable.
    for (var fcData in firestoreCompletionsData) {
        batch.set(completionsColRef.doc(), fcData); // Add new completions
    }

    try {
      await batch.commit();
      await prefsService.setBool(_migrationFlagKey, true); // Set flag AFTER successful commit
      if (kDebugMode) {
        print("User data migration to Firestore successful for userId: \$userId.");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error during Firestore batch commit or setting migration flag for userId: \$userId, error: \$e");
      }
      // Do NOT set the flag if commit fails.
    }
  }
}

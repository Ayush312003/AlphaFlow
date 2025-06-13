import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alphaflow/data/models/app_mode.dart'; // Ensure this path is correct

class UserData {
  final AppMode? appMode;
  final String? selectedTrackId;
  final DateTime? firstActiveDate; // Normalized to UTC midnight

  UserData({
    this.appMode,
    this.selectedTrackId,
    this.firstActiveDate,
  });

  factory UserData.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) {
      // Return default UserData if document doesn't exist or has no data
      // This helps in initializing the state before the document is created.
      return UserData(appMode: null, selectedTrackId: null, firstActiveDate: null);
    }
    return UserData(
      appMode: data['appMode'] != null ? AppMode.fromString(data['appMode'] as String) : null,
      selectedTrackId: data['selectedTrackId'] as String?,
      firstActiveDate: data['firstActiveDate'] != null ? (data['firstActiveDate'] as Timestamp).toDate() : null,
    );
  }

  // Not strictly needed if UserData objects are only read from Firestore and updates happen field by field.
  // However, can be useful for creating new documents or full overwrites.
  Map<String, dynamic> toFirestore() {
    return {
      // Using FieldValue.delete() for nulls ensures fields are removed if explicitly set to null
      'appMode': appMode?.toShortString(), // Store as string, or null to let update handle it
      'selectedTrackId': selectedTrackId, // Store as string, or null
      'firstActiveDate': firstActiveDate != null ? Timestamp.fromDate(firstActiveDate!) : null, // Store as Timestamp, or null
    };
  }

  UserData copyWith({
    AppMode? appMode,
    String? selectedTrackId,
    DateTime? firstActiveDate,
    bool setAppModeToNull = false,
    bool setSelectedTrackIdToNull = false,
  }) {
    return UserData(
      appMode: setAppModeToNull ? null : (appMode ?? this.appMode),
      selectedTrackId: setSelectedTrackIdToNull ? null : (selectedTrackId ?? this.selectedTrackId),
      firstActiveDate: firstActiveDate ?? this.firstActiveDate,
    );
  }
}

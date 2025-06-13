import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphaflow/data/models/user_data.dart';
import 'package:alphaflow/features/auth/application/auth_providers.dart'; // For currentUserIdProvider
import 'user_data_service.dart';
import 'package:alphaflow/data/models/app_mode.dart'; // For AppMode type

// Provider for UserDataService instance
final userDataServiceProvider = Provider<UserDataService>((ref) {
  return UserDataService(FirebaseFirestore.instance);
});

// Main StreamProvider for UserData object
final userDataProvider = StreamProvider<UserData?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null || userId.isEmpty) {
    // No user, so emit null or a default UserData if preferred.
    // Emitting null is fine if UI handles AsyncValue states properly.
    return Stream.value(null);
  }
  final service = ref.watch(userDataServiceProvider);
  return service.streamUserData(userId);
});

// Derived providers for specific fields from UserData
final firestoreAppModeProvider = Provider<AppMode?>((ref) {
  return ref.watch(userDataProvider).asData?.value?.appMode;
});

final firestoreSelectedTrackProvider = Provider<String?>((ref) {
  return ref.watch(userDataProvider).asData?.value?.selectedTrackId;
});

final firestoreFirstActiveDateProvider = Provider<DateTime?>((ref) {
  return ref.watch(userDataProvider).asData?.value?.firstActiveDate;
});

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_service.dart';
import 'package:alphaflow/features/user_profile/application/user_data_service.dart'; // Added
import 'package:cloud_firestore/cloud_firestore.dart'; // Added for FirebaseFirestore.instance
// Import for userDataServiceProvider
import 'package:alphaflow/features/user_profile/application/user_data_providers.dart';


final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authServiceProvider = Provider<AuthService>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return AuthService(firebaseAuth);
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges();
});

final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.asData?.value?.uid;
});

// Updated anonymousUserProvider to ensure user document exists
final anonymousUserProvider = FutureProvider<User?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final user = await authService.signInAnonymouslyIfNeeded();

  if (user?.uid != null) {
    // Get UserDataService instance to ensure document exists.
    // This is a bit indirect. Ideally, UserDataService is self-contained or
    // AuthService calls it. For now, this triggers it.
    // A cleaner way might be for AuthService.signInAnonymouslyIfNeeded to return a value
    // that indicates if it was a new user, or for it to take UserDataService as a dependency.
    // Or, another provider could watch anonymousUserProvider and call ensureUserDataDocumentExists.

    // Let's make UserDataService accessible here to call it.
    // This creates a temporary UserDataService instance. It's better if UserDataService
    // is provided by its own provider, which we did in user_data_providers.dart.
    // So, we should read that provider.

    // final userDataService = UserDataService(FirebaseFirestore.instance); // Temporary instance
    // await userDataService.ensureUserDataDocumentExists(user!.uid);

    // Better: Read the userDataServiceProvider
    await ref.read(userDataServiceProvider).ensureUserDataDocumentExists(user!.uid);
  }
  return user;
});

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_service.dart';

// Provider for FirebaseAuth instance
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// Provider for AuthService instance
final authServiceProvider = Provider<AuthService>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return AuthService(firebaseAuth);
});

// Provider for the current Firebase User object (updates on auth state changes)
final authStateChangesProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges();
});

// Provider for the current UserID string (convenience)
// This depends on authStateChangesProvider to re-evaluate when user changes.
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.asData?.value?.uid;
});

// Provider that attempts to sign in anonymously when first read if needed,
// and then provides the User object.
// This is one way to trigger the sign-in.
final anonymousUserProvider = FutureProvider<User?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.signInAnonymouslyIfNeeded();
});

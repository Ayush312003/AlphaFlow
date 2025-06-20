import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode

class AuthService {
  final FirebaseAuth _firebaseAuth;

  AuthService(this._firebaseAuth);

  User? get currentUser => _firebaseAuth.currentUser;
  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  Future<User?> signInAnonymouslyIfNeeded() async {
    if (currentUser == null) {
      try {
        final userCredential = await _firebaseAuth.signInAnonymously();
        if (kDebugMode) {
          print("Signed in anonymously: \${userCredential.user?.uid}");
        }
        return userCredential.user;
      } catch (e) {
        if (kDebugMode) {
          print("Error signing in anonymously: \$e");
        }
        return null;
      }
    }
    return currentUser;
  }

  Future<void> signOut() async {
    // Note: Signing out an anonymous user deletes the user.
    // New anonymous sign-in will create a new user with a new UID.
    // This might not be desired if you want anonymous users to persist across "sign outs".
    // For true persistence, a proper account linking flow would be needed later.
    // For now, this is standard anonymous sign out.
    if (kDebugMode) {
      print("Signing out anonymous user: \${currentUser?.uid}");
    }
    await _firebaseAuth.signOut();
  }
}

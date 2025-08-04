import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode

class AuthService {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthService(this._firebaseAuth, this._googleSignIn);

  User? get currentUser => _firebaseAuth.currentUser;
  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // The user canceled the sign-in
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      if (kDebugMode) {
        print("Signed in with Google: \${userCredential.user?.uid}");
      }
      return userCredential.user;
    } catch (e) {
      if (kDebugMode) {
        print("Error signing in with Google: \$e");
      }
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
    if (kDebugMode) {
      print("Signed out from Google and Firebase");
    }
  }
}

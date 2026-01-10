// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<User?> registerWithEmail(String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update Display Name
      await result.user!.updateDisplayName(name);
      await result.user!.reload(); // Reload to reflect changes
      
      await _saveUserId(result.user!.uid);
      return _auth.currentUser; // Return the reloaded user
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> loginWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _saveUserId(result.user!.uid);
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web-specific Google Sign-In using Firebase Popup
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        
        final UserCredential result = await _auth.signInWithPopup(googleProvider);
        if (result.user != null) {
          await _saveUserId(result.user!.uid);
        }
        return result.user;
      } else {
        // Mobile-specific Google Sign-In using google_sign_in package
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth = 
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        UserCredential result = await _auth.signInWithCredential(credential);
        await _saveUserId(result.user!.uid);
        return result.user;
      }
    } catch (e) {
      debugPrint('Auth Service: Google Sign-In Error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    await _clearUserId();
  }

  Future<void> _saveUserId(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', uid);
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  Future<void> _clearUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
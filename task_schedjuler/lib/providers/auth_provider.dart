// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;
  String? _error;
  
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Stream<User?> get authStateChanges => _authService.authStateChanges;
  
  AuthProvider() {
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }
  
  Future<void> registerWithEmail(String email, String password, String name) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      _user = await _authService.registerWithEmail(email, password, name);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> loginWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      _user = await _authService.loginWithEmail(email, password);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> signInWithGoogle() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      _user = await _authService.signInWithGoogle();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }
  
  Future<String?> getStoredUserId() async {
    return await _authService.getUserId();
  }
}

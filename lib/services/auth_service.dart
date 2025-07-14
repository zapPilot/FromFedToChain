import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _currentUserId;
  String? _currentUserEmail;
  String? _currentUserName;

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  String? get currentUserId => _currentUserId;
  String? get currentUserEmail => _currentUserEmail;
  String? get currentUserName => _currentUserName;

  // Check if user is authenticated
  Future<void> checkAuthStatus() async {
    // TODO: Implement actual authentication check
    // For now, we'll simulate a guest user
    _isLoggedIn = false;
    _currentUserId = null;
    _currentUserEmail = null;
    _currentUserName = null;
    notifyListeners();
  }

  // Login with email and password
  Future<bool> login(String email, String password) async {
    try {
      // TODO: Implement actual login logic
      // For now, we'll simulate a successful login
      await Future.delayed(const Duration(seconds: 1));
      
      _isLoggedIn = true;
      _currentUserId = 'user-123';
      _currentUserEmail = email;
      _currentUserName = 'Demo User';
      
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Register with email and password
  Future<bool> register(String email, String password, String name) async {
    try {
      // TODO: Implement actual registration logic
      // For now, we'll simulate a successful registration
      await Future.delayed(const Duration(seconds: 1));
      
      _isLoggedIn = true;
      _currentUserId = 'user-123';
      _currentUserEmail = email;
      _currentUserName = name;
      
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _isLoggedIn = false;
    _currentUserId = null;
    _currentUserEmail = null;
    _currentUserName = null;
    
    notifyListeners();
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      // TODO: Implement actual password reset logic
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      return false;
    }
  }
}
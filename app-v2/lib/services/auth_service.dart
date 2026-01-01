import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';

/// Simplified authentication service using Google Sign-In
/// For v2, we're using a simplified auth without Firebase
class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  User? _currentUser;
  static const String _userKey = 'current_user';

  /// Get current authenticated user
  User? get currentUser => _currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => _currentUser != null;

  /// Initialize auth service and restore session
  Future<void> initialize() async {
    try {
      // Try to restore user from local storage
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_userKey);

      if (userData != null) {
        final json = jsonDecode(userData) as Map<String, dynamic>;
        _currentUser = User.fromJson(json);
      }

      // Try to sign in silently if we have a previous session
      if (_currentUser != null) {
        try {
          await _googleSignIn.signInSilently();
        } catch (e) {
          debugPrint('Silent sign-in failed: $e');
          // Clear invalid session
          await signOut();
        }
      }
    } catch (e) {
      debugPrint('Error initializing auth service: $e');
    }
  }

  /// Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled sign-in
        return null;
      }

      // Create user object
      _currentUser = User(
        id: googleUser.id,
        email: googleUser.email,
        displayName: googleUser.displayName ?? 'User',
        photoUrl: googleUser.photoUrl,
      );

      // Save to local storage
      await _saveUser(_currentUser!);

      return _currentUser;
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      throw Exception('Google sign-in failed: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _currentUser = null;

      // Clear from local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
    } catch (e) {
      debugPrint('Error signing out: $e');
      throw Exception('Sign out failed: $e');
    }
  }

  /// Save user to local storage
  Future<void> _saveUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(user.toJson());
      await prefs.setString(_userKey, json);
    } catch (e) {
      debugPrint('Error saving user: $e');
    }
  }

  /// Check if Google Play Services are available
  Future<bool> isGooglePlayServicesAvailable() async {
    try {
      return await _googleSignIn.isSignedIn();
    } catch (e) {
      return false;
    }
  }
}

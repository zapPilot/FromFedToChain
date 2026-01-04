import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:from_fed_to_chain_app/features/auth/models/user.dart';
import 'package:from_fed_to_chain_app/core/services/logger_service.dart';

/// Authentication states
enum AuthState {
  initial,
  authenticating,
  authenticated,
  unauthenticated,
  error,
}

/// Authentication service for handling Apple and Google sign-in
class AuthService extends ChangeNotifier {
  static final _log = LoggerService.getLogger('AuthService');
  static const String _userKey = 'app_user';
  static const String _authTokenKey = 'auth_token';

  AuthState _authState = AuthState.initial;
  AppUser? _currentUser;
  String? _errorMessage;

  // Getters
  AuthState get authState => _authState;
  AppUser? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated =>
      _authState == AuthState.authenticated && _currentUser != null;
  bool get isLoading => _authState == AuthState.authenticating;

  /// Initialize the auth service and check for existing session.
  ///
  /// Checks SharedPreferences for stored user data and token.
  /// If found, restores the session and sets state to [AuthState.authenticated].
  /// Otherwise, sets state to [AuthState.unauthenticated].
  Future<void> initialize() async {
    try {
      _setAuthState(AuthState.authenticating);

      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      final authToken = prefs.getString(_authTokenKey);

      if (userJson != null && authToken != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        _currentUser = AppUser.fromJson(userMap);
        _setAuthState(AuthState.authenticated);

        _log.info('User session restored: ${_currentUser?.email}');
      } else {
        _setAuthState(AuthState.unauthenticated);
        _log.info('No existing user session found');
      }
    } catch (e) {
      _log.severe('Auth initialization error: $e');
      _setError('Failed to initialize authentication');
    }
  }

  /// Sign in with Apple.
  ///
  /// Returns `true` if sign in is successful, `false` otherwise.
  Future<bool> signInWithApple() async {
    try {
      _setAuthState(AuthState.authenticating);
      _clearError();

      _log.info('Starting Apple Sign In...');

      // For now, simulate Apple Sign In since we don't have the actual implementation
      // In a real app, you would use sign_in_with_apple package here
      await _simulateAppleSignIn();

      return true;
    } catch (e) {
      _log.severe('Apple Sign In error: $e');

      if (e is PlatformException) {
        if (e.code == 'SignInWithAppleNotSupported') {
          _setError('Apple Sign In is not supported on this device');
        } else if (e.code == 'SignInWithAppleCanceled') {
          _setError('Apple Sign In was canceled');
        } else {
          _setError('Apple Sign In failed: ${e.message}');
        }
      } else {
        _setError('Apple Sign In failed');
      }

      _setAuthState(AuthState.unauthenticated);
      return false;
    }
  }

  /// Sign in with Google.
  ///
  /// Returns `true` if sign in is successful, `false` otherwise.
  Future<bool> signInWithGoogle() async {
    try {
      _setAuthState(AuthState.authenticating);
      _clearError();

      _log.info('Starting Google Sign In...');

      // For now, simulate Google Sign In since we don't have the actual implementation
      // In a real app, you would use google_sign_in package here
      await _simulateGoogleSignIn();

      return true;
    } catch (e) {
      _log.severe('Google Sign In error: $e');

      if (e is PlatformException) {
        _setError('Google Sign In failed: ${e.message}');
      } else {
        _setError('Google Sign In failed');
      }

      _setAuthState(AuthState.unauthenticated);
      return false;
    }
  }

  /// Sign out the current user.
  ///
  /// Clears local storage and resets state to [AuthState.unauthenticated].
  Future<void> signOut() async {
    try {
      _log.info('Signing out user: ${_currentUser?.email}');

      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      await prefs.remove(_authTokenKey);

      // Clear in-memory data
      _currentUser = null;
      _clearError();
      _setAuthState(AuthState.unauthenticated);

      _log.info('User signed out successfully');
    } catch (e) {
      _log.severe('Sign out error: $e');
      _setError('Failed to sign out');
    }
  }

  /// Delete user account (placeholder for future implementation).
  ///
  /// Returns `true` if account deletion is successful.
  Future<bool> deleteAccount() async {
    try {
      if (_currentUser == null) {
        _setError('No user to delete');
        return false;
      }

      if (_simulateError) throw Exception('Simulated delete failure');

      _log.info('Deleting account for: ${_currentUser?.email}');

      // In a real app, you would call your backend API to delete the account
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      // Sign out after account deletion
      await signOut();

      _log.info('Account deleted successfully');

      return true;
    } catch (e) {
      _log.severe('Account deletion error: $e');
      _setError('Failed to delete account');
      return false;
    }
  }

  /// Update user profile.
  ///
  /// Updates local user state and persists changes.
  /// Returns `true` if update is successful.
  Future<bool> updateProfile({
    String? name,
    String? photoUrl,
  }) async {
    try {
      if (_currentUser == null) {
        _setError('No user to update');
        return false;
      }

      if (_simulateError) throw Exception('Simulated update failure');

      _currentUser = _currentUser!.copyWith(
        name: name ?? _currentUser!.name,
        photoUrl: photoUrl ?? _currentUser!.photoUrl,
        lastLoginAt: DateTime.now(),
      );

      // Save updated user to local storage
      await _saveUserToStorage(_currentUser!);

      notifyListeners();

      _log.info('User profile updated');

      return true;
    } catch (e) {
      _log.severe('Profile update error: $e');
      _setError('Failed to update profile');
      return false;
    }
  }

  // Private methods

  // Test helpers
  bool _simulateError = false;

  @visibleForTesting
  void setSimulateErrorForTesting(bool value) {
    _simulateError = value;
  }

  /// Simulate Apple Sign In (replace with real implementation)
  Future<void> _simulateAppleSignIn() async {
    if (_simulateError) {
      throw PlatformException(
        code: 'SignInWithAppleNotSupported',
        message: 'Simulated error',
      );
    }
    await Future.delayed(const Duration(seconds: 2)); // Simulate network delay

    final now = DateTime.now();
    final user = AppUser(
      id: 'apple_${now.millisecondsSinceEpoch}',
      name: 'Apple User',
      email: 'apple.user@example.com',
      photoUrl: null,
      provider: 'apple',
      createdAt: now,
      lastLoginAt: now,
    );

    await _completeSignIn(user, 'apple_token_${now.millisecondsSinceEpoch}');
  }

  /// Simulate Google Sign In (replace with real implementation)
  Future<void> _simulateGoogleSignIn() async {
    if (_simulateError) {
      throw PlatformException(
        code: 'GoogleSignInFailed',
        message: 'Simulated error',
      );
    }
    await Future.delayed(const Duration(seconds: 2)); // Simulate network delay

    final now = DateTime.now();
    final user = AppUser(
      id: 'google_${now.millisecondsSinceEpoch}',
      name: 'Google User',
      email: 'google.user@gmail.com',
      photoUrl: 'https://lh3.googleusercontent.com/a/default-user=s96-c',
      provider: 'google',
      createdAt: now,
      lastLoginAt: now,
    );

    await _completeSignIn(user, 'google_token_${now.millisecondsSinceEpoch}');
  }

  /// Complete the sign-in process
  Future<void> _completeSignIn(AppUser user, String token) async {
    _currentUser = user;

    // Save to local storage
    await _saveUserToStorage(user);
    await _saveTokenToStorage(token);

    _setAuthState(AuthState.authenticated);

    _log.info('Sign in completed for: ${user.email}');
  }

  /// Save user to local storage
  Future<void> _saveUserToStorage(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  /// Save auth token to local storage
  Future<void> _saveTokenToStorage(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authTokenKey, token);
  }

  /// Set authentication state and notify listeners
  void _setAuthState(AuthState state) {
    _authState = state;
    notifyListeners();
  }

  /// Set error message and state
  void _setError(String message) {
    _errorMessage = message;
    _authState = AuthState.error;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
  }
}

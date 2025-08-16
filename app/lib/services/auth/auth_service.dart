import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Authentication states
enum AuthState {
  initial,
  authenticating,
  authenticated,
  unauthenticated,
  error,
}

/// User model for authentication
class AppUser {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String provider; // 'apple' or 'google'
  final DateTime createdAt;
  final DateTime lastLoginAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.provider,
    required this.createdAt,
    required this.lastLoginAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'provider': provider,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      photoUrl: json['photoUrl'],
      provider: json['provider'],
      createdAt: DateTime.parse(json['createdAt']),
      lastLoginAt: DateTime.parse(json['lastLoginAt']),
    );
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    String? provider,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      provider: provider ?? this.provider,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}

/// Authentication service for handling Apple and Google sign-in
class AuthService extends ChangeNotifier {
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

  /// Initialize the auth service and check for existing session
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

        if (kDebugMode) {
          print('✅ User session restored: ${_currentUser?.email}');
        }
      } else {
        _setAuthState(AuthState.unauthenticated);
        if (kDebugMode) {
          print('ℹ️ No existing user session found');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Auth initialization error: $e');
      }
      _setError('Failed to initialize authentication');
    }
  }

  /// Sign in with Apple
  Future<bool> signInWithApple() async {
    try {
      _setAuthState(AuthState.authenticating);
      _clearError();

      if (kDebugMode) {
        print('🍎 Starting Apple Sign In...');
      }

      // For now, simulate Apple Sign In since we don't have the actual implementation
      // In a real app, you would use sign_in_with_apple package here
      await _simulateAppleSignIn();

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Apple Sign In error: $e');
      }

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

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      _setAuthState(AuthState.authenticating);
      _clearError();

      if (kDebugMode) {
        print('🔍 Starting Google Sign In...');
      }

      // For now, simulate Google Sign In since we don't have the actual implementation
      // In a real app, you would use google_sign_in package here
      await _simulateGoogleSignIn();

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Google Sign In error: $e');
      }

      if (e is PlatformException) {
        _setError('Google Sign In failed: ${e.message}');
      } else {
        _setError('Google Sign In failed');
      }

      _setAuthState(AuthState.unauthenticated);
      return false;
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      if (kDebugMode) {
        print('👋 Signing out user: ${_currentUser?.email}');
      }

      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      await prefs.remove(_authTokenKey);

      // Clear in-memory data
      _currentUser = null;
      _clearError();
      _setAuthState(AuthState.unauthenticated);

      if (kDebugMode) {
        print('✅ User signed out successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Sign out error: $e');
      }
      _setError('Failed to sign out');
    }
  }

  /// Delete user account (placeholder for future implementation)
  Future<bool> deleteAccount() async {
    try {
      if (_currentUser == null) {
        _setError('No user to delete');
        return false;
      }

      if (kDebugMode) {
        print('🗑️ Deleting account for: ${_currentUser?.email}');
      }

      // In a real app, you would call your backend API to delete the account
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      // Sign out after account deletion
      await signOut();

      if (kDebugMode) {
        print('✅ Account deleted successfully');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Account deletion error: $e');
      }
      _setError('Failed to delete account');
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? name,
    String? photoUrl,
  }) async {
    try {
      if (_currentUser == null) {
        _setError('No user to update');
        return false;
      }

      _currentUser = _currentUser!.copyWith(
        name: name ?? _currentUser!.name,
        photoUrl: photoUrl ?? _currentUser!.photoUrl,
        lastLoginAt: DateTime.now(),
      );

      // Save updated user to local storage
      await _saveUserToStorage(_currentUser!);

      notifyListeners();

      if (kDebugMode) {
        print('✅ User profile updated');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Profile update error: $e');
      }
      _setError('Failed to update profile');
      return false;
    }
  }

  // Private methods

  /// Simulate Apple Sign In (replace with real implementation)
  Future<void> _simulateAppleSignIn() async {
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

    if (kDebugMode) {
      print('✅ Sign in completed for: ${user.email}');
    }
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

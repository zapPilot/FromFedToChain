import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  static const String _userKey = 'authenticated_user';
  static const bool _developmentMode = kDebugMode;
  
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  User? _currentUser;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  // Check if running on iOS simulator
  bool get _isSimulator {
    if (!Platform.isIOS) return false;
    return defaultTargetPlatform == TargetPlatform.iOS && !kReleaseMode;
  }

  Future<void> initialize() async {
    await _loadSavedUser();
  }

  Future<User?> signInWithGoogle() async {
    try {
      // In development mode, provide demo login
      if (_developmentMode && (_isSimulator || _googleSignIn.clientId?.contains('YOUR_GOOGLE_CLIENT_ID_HERE') == true)) {
        return _createDemoUser(AuthProvider.google);
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // User cancelled
      }

      final user = User.fromGoogle(
        id: googleUser.id,
        email: googleUser.email,
        displayName: googleUser.displayName ?? googleUser.email,
        photoUrl: googleUser.photoUrl,
      );

      await _saveUser(user);
      _currentUser = user;
      notifyListeners();
      return user;
    } catch (e) {
      if (_developmentMode) {
        // Fallback to demo user in development
        return _createDemoUser(AuthProvider.google);
      }
      throw AuthException('Google sign-in failed: $e');
    }
  }

  Future<User?> signInWithApple() async {
    if (!Platform.isIOS && !Platform.isMacOS) {
      throw AuthException('Apple Sign In is only available on iOS and macOS');
    }

    try {
      // In development mode on simulator, provide demo login
      if (_developmentMode && _isSimulator) {
        return _createDemoUser(AuthProvider.apple);
      }

      final available = await SignInWithApple.isAvailable();
      if (!available) {
        if (_developmentMode) {
          return _createDemoUser(AuthProvider.apple);
        }
        throw AuthException('Apple Sign In is not available on this device');
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      if (credential.userIdentifier == null) {
        throw AuthException('Failed to get Apple ID credential');
      }

      String fullName = '';
      if (credential.givenName != null || credential.familyName != null) {
        fullName = '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim();
      }

      final user = User.fromApple(
        id: credential.userIdentifier!,
        email: credential.email ?? '${credential.userIdentifier}@appleid.apple.com',
        fullName: fullName.isEmpty ? null : fullName,
      );

      await _saveUser(user);
      _currentUser = user;
      notifyListeners();
      return user;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (_developmentMode && e.code == AuthorizationErrorCode.unknown) {
        // Common simulator error, fallback to demo user
        return _createDemoUser(AuthProvider.apple);
      }
      throw AuthException('Apple sign-in failed: ${e.message}');
    } on PlatformException catch (e) {
      if (_developmentMode) {
        // Fallback to demo user in development
        return _createDemoUser(AuthProvider.apple);
      }
      throw AuthException('Apple sign-in failed: ${e.message}');
    } catch (e) {
      if (_developmentMode) {
        // Fallback to demo user in development
        return _createDemoUser(AuthProvider.apple);
      }
      throw AuthException('Apple sign-in failed: $e');
    }
  }

  Future<void> signOut() async {
    try {
      if (_currentUser?.provider == AuthProvider.google) {
        await _googleSignIn.signOut();
      }
      
      await _clearSavedUser();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      throw AuthException('Sign out failed: $e');
    }
  }

  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<void> _loadSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(_userKey);
    
    if (userString != null) {
      try {
        final userData = jsonDecode(userString);
        _currentUser = User.fromJson(userData);
        notifyListeners();
      } catch (e) {
        await _clearSavedUser();
      }
    }
  }

  Future<void> _clearSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  /// Create a demo user for development/testing purposes
  Future<User> _createDemoUser(AuthProvider provider) async {
    final user = provider == AuthProvider.google
        ? User.fromGoogle(
            id: 'demo_google_123',
            email: 'demo.user@gmail.com',
            displayName: 'Demo Google User',
            photoUrl: 'https://via.placeholder.com/150',
          )
        : User.fromApple(
            id: 'demo_apple_123',
            email: 'demo.user@icloud.com',
            fullName: 'Demo Apple User',
          );

    await _saveUser(user);
    _currentUser = user;
    notifyListeners();
    
    if (kDebugMode) {
      print('📱 Demo login: ${provider.toString()} user created for development');
    }
    
    return user;
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  
  @override
  String toString() => 'AuthException: $message';
}
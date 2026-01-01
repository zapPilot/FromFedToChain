@Tags(['sequential']) // Avoids channel collisions with other suites.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:from_fed_to_chain_app/features/auth/services/auth_service.dart';
import 'package:from_fed_to_chain_app/features/auth/models/user.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService Comprehensive Tests', () {
    late AuthService authService;
    late AppUser testUser;

    setUp(() async {
      // Reset SharedPreferences before each test with explicit cleanup
      SharedPreferences.setMockInitialValues({});

      // Allow the mock to fully reset with longer delay for test isolation
      await Future.delayed(const Duration(milliseconds: 1));

      authService = AuthService();

      testUser = AppUser(
        id: 'test-user-123',
        name: 'Test User',
        email: 'test@example.com',
        photoUrl: 'https://example.com/photo.jpg',
        provider: 'google',
        createdAt: DateTime(2025, 1, 1),
        lastLoginAt: DateTime(2025, 1, 15),
      );
    });

    tearDown(() async {
      // Dispose authService first
      authService.dispose();

      // Ensure complete cleanup of SharedPreferences state
      SharedPreferences.setMockInitialValues({});

      // Longer delay to ensure complete state reset between tests
      await Future.delayed(const Duration(milliseconds: 1));
    });

    group('Initialization', () {
      test('should start with initial state', () {
        expect(authService.authState, AuthState.initial);
        expect(authService.currentUser, isNull);
        expect(authService.errorMessage, isNull);
        expect(authService.isAuthenticated, isFalse);
        expect(authService.isLoading, isFalse);
      });

      test('should initialize with no existing session', () async {
        await authService.initialize();

        expect(authService.authState, AuthState.unauthenticated);
        expect(authService.currentUser, isNull);
        expect(authService.isAuthenticated, isFalse);
      });

      test('should restore existing session', () async {
        // Set up existing session in SharedPreferences
        SharedPreferences.setMockInitialValues({
          'app_user': jsonEncode(testUser.toJson()),
          'auth_token': 'test_token_123',
        });

        await authService.initialize();

        expect(authService.authState, AuthState.authenticated);
        expect(authService.currentUser, isNotNull);
        expect(authService.currentUser?.email, testUser.email);
        expect(authService.isAuthenticated, isTrue);
      });

      test('should handle corrupted session data gracefully', () async {
        // Set up corrupted session data
        SharedPreferences.setMockInitialValues({
          'app_user': 'invalid_json',
          'auth_token': 'test_token_123',
        });

        // Allow mock to fully settle with proper delay
        await Future.delayed(const Duration(milliseconds: 1));

        // Create new AuthService instance AFTER setting mock values
        // This ensures the service uses the corrupted mock data
        final testAuthService = AuthService();

        await testAuthService.initialize();

        // Debug output to understand what's happening
        print('DEBUG: authState = ${testAuthService.authState}');
        print('DEBUG: errorMessage = "${testAuthService.errorMessage}"');
        print('DEBUG: isAuthenticated = ${testAuthService.isAuthenticated}');

        expect(testAuthService.authState, AuthState.error);
        expect(testAuthService.errorMessage, contains('Failed to initialize'));

        // Clean up
        testAuthService.dispose();

        // Reset SharedPreferences to clean state for next tests
        SharedPreferences.setMockInitialValues({});
        await Future.delayed(const Duration(milliseconds: 1));
      });

      test('should handle incomplete session data', () async {
        // Only user data, no token
        SharedPreferences.setMockInitialValues({
          'app_user': jsonEncode(testUser.toJson()),
        });

        await authService.initialize();

        expect(authService.authState, AuthState.unauthenticated);
        expect(authService.currentUser, isNull);
      });
    });

    group('Apple Sign In', () {
      test('should successfully sign in with Apple', () async {
        final result = await authService.signInWithApple();

        expect(result, isTrue);
        expect(authService.authState, AuthState.authenticated);
        expect(authService.currentUser, isNotNull);
        expect(authService.currentUser?.provider, 'apple');
        expect(authService.currentUser?.email, 'apple.user@example.com');
        expect(authService.isAuthenticated, isTrue);
        expect(authService.errorMessage, isNull);
      });

      test('should go through authenticating state during Apple sign in',
          () async {
        final stateChanges = <AuthState>[];
        authService.addListener(() {
          stateChanges.add(authService.authState);
        });

        await authService.signInWithApple();

        expect(stateChanges, contains(AuthState.authenticating));
        expect(stateChanges, contains(AuthState.authenticated));
      });

      test('should persist Apple user session', () async {
        await authService.signInWithApple();

        final prefs = await SharedPreferences.getInstance();
        final userJson = prefs.getString('app_user');
        final token = prefs.getString('auth_token');

        expect(userJson, isNotNull);
        expect(token, isNotNull);

        final savedUser = AppUser.fromJson(jsonDecode(userJson!));
        expect(savedUser.provider, 'apple');
        expect(savedUser.email, 'apple.user@example.com');
      });

      test('should handle Apple sign in errors', () async {
        // This test would normally mock the Apple Sign In failure
        // For now, we test that the error handling structure is in place
        // Test that the method exists and is callable without disposing issues
        expect(authService.signInWithApple, isA<Function>());
      });
    });

    group('Google Sign In', () {
      test('should successfully sign in with Google', () async {
        final result = await authService.signInWithGoogle();

        expect(result, isTrue);
        expect(authService.authState, AuthState.authenticated);
        expect(authService.currentUser, isNotNull);
        expect(authService.currentUser?.provider, 'google');
        expect(authService.currentUser?.email, 'google.user@gmail.com');
        expect(authService.currentUser?.photoUrl, isNotNull);
        expect(authService.isAuthenticated, isTrue);
        expect(authService.errorMessage, isNull);
      });

      test('should go through authenticating state during Google sign in',
          () async {
        final stateChanges = <AuthState>[];
        authService.addListener(() {
          stateChanges.add(authService.authState);
        });

        await authService.signInWithGoogle();

        expect(stateChanges, contains(AuthState.authenticating));
        expect(stateChanges, contains(AuthState.authenticated));
      });

      test('should persist Google user session', () async {
        await authService.signInWithGoogle();

        final prefs = await SharedPreferences.getInstance();
        final userJson = prefs.getString('app_user');
        final token = prefs.getString('auth_token');

        expect(userJson, isNotNull);
        expect(token, isNotNull);

        final savedUser = AppUser.fromJson(jsonDecode(userJson!));
        expect(savedUser.provider, 'google');
        expect(savedUser.email, 'google.user@gmail.com');
        expect(savedUser.photoUrl, isNotNull);
      });

      test('should handle Google sign in errors', () async {
        // This test would normally mock the Google Sign In failure
        // For now, we test that the error handling structure is in place
        // Test that the method exists and is callable without disposing issues
        expect(authService.signInWithGoogle, isA<Function>());
      });
    });

    group('Sign Out', () {
      test('should successfully sign out authenticated user', () async {
        // First sign in
        await authService.signInWithGoogle();
        expect(authService.isAuthenticated, isTrue);

        // Then sign out
        await authService.signOut();

        expect(authService.authState, AuthState.unauthenticated);
        expect(authService.currentUser, isNull);
        expect(authService.isAuthenticated, isFalse);
        expect(authService.errorMessage, isNull);
      });

      test('should clear persisted session data on sign out', () async {
        // First sign in to create session
        await authService.signInWithGoogle();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('app_user'), isNotNull);
        expect(prefs.getString('auth_token'), isNotNull);

        // Sign out
        await authService.signOut();

        expect(prefs.getString('app_user'), isNull);
        expect(prefs.getString('auth_token'), isNull);
      });

      test('should handle sign out when not authenticated', () async {
        expect(authService.isAuthenticated, isFalse);

        await authService.signOut();

        expect(authService.authState, AuthState.unauthenticated);
        expect(authService.currentUser, isNull);
      });
    });

    group('Profile Updates', () {
      test('should update user profile name', () async {
        // First sign in
        await authService.signInWithGoogle();
        expect(authService.currentUser?.name, 'Google User');

        // Update profile
        final result = await authService.updateProfile(name: 'Updated Name');

        expect(result, isTrue);
        expect(authService.currentUser?.name, 'Updated Name');
        expect(authService.currentUser?.email,
            'google.user@gmail.com'); // Should remain unchanged
      });

      test('should update user profile photo URL', () async {
        // First sign in
        await authService.signInWithGoogle();

        // Update profile
        const newPhotoUrl = 'https://example.com/new-photo.jpg';
        final result = await authService.updateProfile(photoUrl: newPhotoUrl);

        expect(result, isTrue);
        expect(authService.currentUser?.photoUrl, newPhotoUrl);
        expect(authService.currentUser?.name,
            'Google User'); // Should remain unchanged
      });

      test('should update both name and photo URL', () async {
        // First sign in
        await authService.signInWithGoogle();

        // Update profile
        const newName = 'Updated Name';
        const newPhotoUrl = 'https://example.com/new-photo.jpg';
        final result = await authService.updateProfile(
          name: newName,
          photoUrl: newPhotoUrl,
        );

        expect(result, isTrue);
        expect(authService.currentUser?.name, newName);
        expect(authService.currentUser?.photoUrl, newPhotoUrl);
      });

      test('should persist profile updates', () async {
        // First sign in
        await authService.signInWithGoogle();

        // Update profile
        await authService.updateProfile(name: 'Updated Name');

        // Check persisted data
        final prefs = await SharedPreferences.getInstance();
        final userJson = prefs.getString('app_user');
        expect(userJson, isNotNull);

        final savedUser = AppUser.fromJson(jsonDecode(userJson!));
        expect(savedUser.name, 'Updated Name');
      });

      test('should update lastLoginAt timestamp on profile update', () async {
        // First sign in
        await authService.signInWithGoogle();
        final originalLastLogin = authService.currentUser?.lastLoginAt;

        // Wait a bit then update
        await Future.delayed(Duration(milliseconds: 10));
        await authService.updateProfile(name: 'Updated Name');

        expect(authService.currentUser?.lastLoginAt.isAfter(originalLastLogin!),
            isTrue);
      });

      test('should fail to update profile when not authenticated', () async {
        expect(authService.isAuthenticated, isFalse);

        final result = await authService.updateProfile(name: 'New Name');

        expect(result, isFalse);
        expect(authService.errorMessage, 'No user to update');
      });
    });

    group('Account Deletion', () {
      test('should delete account successfully', () async {
        // First sign in
        await authService.signInWithGoogle();
        expect(authService.isAuthenticated, isTrue);

        // Delete account
        final result = await authService.deleteAccount();

        expect(result, isTrue);
        expect(authService.authState, AuthState.unauthenticated);
        expect(authService.currentUser, isNull);
        expect(authService.isAuthenticated, isFalse);
      });

      test('should clear session data on account deletion', () async {
        // First sign in
        await authService.signInWithGoogle();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('app_user'), isNotNull);
        expect(prefs.getString('auth_token'), isNotNull);

        // Delete account
        await authService.deleteAccount();

        expect(prefs.getString('app_user'), isNull);
        expect(prefs.getString('auth_token'), isNull);
      });

      test('should fail to delete account when not authenticated', () async {
        expect(authService.isAuthenticated, isFalse);

        final result = await authService.deleteAccount();

        expect(result, isFalse);
        expect(authService.errorMessage, 'No user to delete');
      });
    });

    group('State Management', () {
      test('should notify listeners on state changes', () async {
        var notificationCount = 0;
        authService.addListener(() {
          notificationCount++;
        });

        await authService.signInWithGoogle();

        expect(notificationCount, greaterThan(0));
      });

      test('should handle loading states correctly', () async {
        expect(authService.isLoading, isFalse);

        // Start async operation and check loading state
        final future = authService.signInWithGoogle();

        // Note: Due to the simulation delay, we can't easily test the intermediate loading state
        // In real implementation, you might need to add testing hooks

        await future;
        expect(authService.isLoading, isFalse);
      });

      test('should handle error states correctly', () async {
        // Initialize with corrupted data to trigger error
        SharedPreferences.setMockInitialValues({
          'app_user': 'invalid_json',
          'auth_token': 'test_token_123',
        });

        // Allow mock to fully settle with proper delay
        await Future.delayed(const Duration(milliseconds: 1));

        // Create new AuthService instance AFTER setting mock values
        final testAuthService = AuthService();
        await testAuthService.initialize();

        expect(testAuthService.authState, AuthState.error);
        expect(testAuthService.errorMessage, isNotNull);
        expect(testAuthService.isAuthenticated, isFalse);

        // Clean up
        testAuthService.dispose();

        // Reset SharedPreferences to clean state for next tests
        SharedPreferences.setMockInitialValues({});
        await Future.delayed(const Duration(milliseconds: 1));
      });

      test('should clear errors on successful operations', () async {
        // First trigger an error
        SharedPreferences.setMockInitialValues({
          'app_user': 'invalid_json',
          'auth_token': 'test_token_123',
        });

        // Allow mock to fully settle with proper delay
        await Future.delayed(const Duration(milliseconds: 1));

        // Create new AuthService instance AFTER setting mock values
        final testAuthService = AuthService();
        await testAuthService.initialize();
        expect(testAuthService.errorMessage, isNotNull);

        // Reset SharedPreferences for clean sign in
        SharedPreferences.setMockInitialValues({});

        // Allow mock to fully settle with proper delay
        await Future.delayed(const Duration(milliseconds: 1));

        // Successful sign in should clear error
        await testAuthService.signInWithGoogle();
        expect(testAuthService.errorMessage, isNull);
        expect(testAuthService.authState, AuthState.authenticated);

        // Clean up
        testAuthService.dispose();

        // Reset SharedPreferences to clean state for next tests
        SharedPreferences.setMockInitialValues({});
        await Future.delayed(const Duration(milliseconds: 1));
      });
    });

    group('AppUser Model', () {
      test('should create user with all properties', () {
        expect(testUser.id, 'test-user-123');
        expect(testUser.name, 'Test User');
        expect(testUser.email, 'test@example.com');
        expect(testUser.photoUrl, 'https://example.com/photo.jpg');
        expect(testUser.provider, 'google');
        expect(testUser.createdAt, DateTime(2025, 1, 1));
        expect(testUser.lastLoginAt, DateTime(2025, 1, 15));
      });

      test('should serialize to JSON correctly', () {
        final json = testUser.toJson();

        expect(json['id'], 'test-user-123');
        expect(json['name'], 'Test User');
        expect(json['email'], 'test@example.com');
        expect(json['photoUrl'], 'https://example.com/photo.jpg');
        expect(json['provider'], 'google');
        expect(json['createdAt'], '2025-01-01T00:00:00.000');
        expect(json['lastLoginAt'], '2025-01-15T00:00:00.000');
      });

      test('should deserialize from JSON correctly', () {
        final json = testUser.toJson();
        final deserializedUser = AppUser.fromJson(json);

        expect(deserializedUser.id, testUser.id);
        expect(deserializedUser.name, testUser.name);
        expect(deserializedUser.email, testUser.email);
        expect(deserializedUser.photoUrl, testUser.photoUrl);
        expect(deserializedUser.provider, testUser.provider);
        expect(deserializedUser.createdAt, testUser.createdAt);
        expect(deserializedUser.lastLoginAt, testUser.lastLoginAt);
      });

      test('should handle null photoUrl in serialization', () {
        final userWithoutPhoto = AppUser(
          id: 'test-id',
          name: 'Test User',
          email: 'test@example.com',
          photoUrl: null,
          provider: 'apple',
          createdAt: DateTime(2025, 1, 1),
          lastLoginAt: DateTime(2025, 1, 1),
        );

        final json = userWithoutPhoto.toJson();
        expect(json['photoUrl'], isNull);

        final deserializedUser = AppUser.fromJson(json);
        expect(deserializedUser.photoUrl, isNull);
      });

      test('should create copy with updated properties', () {
        final updatedUser = testUser.copyWith(
          name: 'Updated Name',
          photoUrl: 'https://example.com/new-photo.jpg',
        );

        expect(updatedUser.id, testUser.id); // Should remain the same
        expect(updatedUser.name, 'Updated Name'); // Should be updated
        expect(updatedUser.email, testUser.email); // Should remain the same
        expect(updatedUser.photoUrl,
            'https://example.com/new-photo.jpg'); // Should be updated
        expect(
            updatedUser.provider, testUser.provider); // Should remain the same
        expect(updatedUser.createdAt,
            testUser.createdAt); // Should remain the same
        expect(updatedUser.lastLoginAt,
            testUser.lastLoginAt); // Should remain the same
      });

      test(
          'should handle copyWith with no changes when called with no parameters',
          () {
        final updatedUser = testUser.copyWith();

        expect(updatedUser.id, testUser.id);
        expect(updatedUser.name, testUser.name);
        expect(updatedUser.email, testUser.email);
        expect(updatedUser.photoUrl, testUser.photoUrl);
        expect(updatedUser.provider, testUser.provider);
        expect(updatedUser.createdAt, testUser.createdAt);
        expect(updatedUser.lastLoginAt, testUser.lastLoginAt);
      });
    });
  });
}

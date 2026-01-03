import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:from_fed_to_chain_app/features/auth/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService Coverage Tests', () {
    late AuthService authService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      authService = AuthService();
    });

    test('updateProfile fails when no user', () async {
      await authService.initialize();
      // No user initially
      final result = await authService.updateProfile(name: 'New Name');
      expect(result, isFalse);
      expect(authService.errorMessage, 'No user to update');
    });

    test('deleteAccount fails when no user', () async {
      await authService.initialize();
      final result = await authService.deleteAccount();
      expect(result, isFalse);
      expect(authService.errorMessage, 'No user to delete');
    });

    test('signInWithApple handles error', () async {
      authService.setSimulateErrorForTesting(true);
      final result = await authService.signInWithApple();
      expect(result, isFalse);
      expect(
          authService.errorMessage,
          contains(
              'not supported')); // The simulated exception code maps to this
      expect(authService.authState, AuthState.unauthenticated);
    });

    test('signInWithGoogle handles error', () async {
      authService.setSimulateErrorForTesting(true);
      final result = await authService.signInWithGoogle();
      expect(result, isFalse);
      expect(authService.errorMessage,
          contains('Google Sign In failed: Simulated error'));
      expect(authService.authState, AuthState.unauthenticated);
    });

    test('updateProfile handles error', () async {
      // First sign in
      await authService.signInWithApple();
      expect(authService.isAuthenticated, isTrue);

      authService.setSimulateErrorForTesting(true);

      final result = await authService.updateProfile(name: 'Fail');
      expect(result, isFalse);
      expect(authService.errorMessage, 'Failed to update profile');
    });

    test('deleteAccount handles error', () async {
      // First sign in
      await authService.signInWithApple();
      expect(authService.isAuthenticated, isTrue);

      authService.setSimulateErrorForTesting(true);

      final result = await authService.deleteAccount();
      expect(result, isFalse);
      expect(authService.errorMessage, 'Failed to delete account');
    });

    test('getters', () async {
      expect(authService.isLoading, isFalse);
      // Trigger loading
      final future = authService.signInWithApple();
      expect(authService.isLoading, isTrue);
      await future;
      expect(authService.isLoading, isFalse);
    });
  });
}

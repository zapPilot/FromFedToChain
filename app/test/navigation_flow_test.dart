import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../lib/main.dart';
import '../lib/services/auth/auth_service.dart';
import '../lib/services/content_service.dart';
import '../lib/services/audio_service.dart' as local_audio;
import '../lib/screens/splash_screen.dart';
import '../lib/screens/onboarding/onboarding_screen.dart';
import '../lib/screens/home_screen.dart';

void main() {
  group('Navigation Flow Tests', () {
    setUpAll(() {
      // Mock shared preferences for testing
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Should start with Splash Screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthService()),
            ChangeNotifierProvider(create: (_) => ContentService()),
            ChangeNotifierProvider(
              create: (context) => local_audio.AudioService(null, context.read<ContentService>()),
            ),
          ],
          child: MaterialApp(
            home: const SplashScreen(),
          ),
        ),
      );

      // Verify splash screen is shown
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('From Fed to Chain'), findsOneWidget);
      expect(find.text('Initializing...'), findsOneWidget);

      // Verify loading indicator is present
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('Should show Onboarding Screen for first-time users', (WidgetTester tester) async {
      // Clear any existing preferences
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        MaterialApp(
          home: const OnboardingScreen(),
        ),
      );

      // Verify onboarding screen is shown
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('Stream Chinese Content'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      // Verify page indicators are present
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('Onboarding navigation should work', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const OnboardingScreen(),
        ),
      );

      // Initially should show first page
      expect(find.text('Stream Web3/Finance Content'), findsOneWidget);

      // Tap next to go to second page
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Should now show second page
      expect(find.text('Organized by Topics'), findsOneWidget);

      // Tap next again to go to third page
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Should now show third page
      expect(find.text('Track Your Progress'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('Should navigate back in onboarding', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const OnboardingScreen(),
        ),
      );

      // Go to second page
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Verify we're on second page
      expect(find.text('Organized by Topics'), findsOneWidget);

      // Find and tap the back button (arrow icon)
      await tester.tap(find.byIcon(Icons.arrow_back_ios_rounded));
      await tester.pumpAndSettle();

      // Should be back on first page
      expect(find.text('Stream Web3/Finance Content'), findsOneWidget);
    });

    testWidgets('Home Screen should load correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthService()),
            ChangeNotifierProvider(create: (_) => ContentService()),
            ChangeNotifierProvider(
              create: (context) => local_audio.AudioService(null, context.read<ContentService>()),
            ),
          ],
          child: MaterialApp(
            home: const HomeScreen(),
          ),
        ),
      );

      // Give time for content to load
      await tester.pump();

      // Verify home screen is shown
      expect(find.byType(HomeScreen), findsOneWidget);

      // Home screen should have basic elements
      // Note: Exact elements depend on the HomeScreen implementation
    });

    testWidgets('Auth Service should initialize correctly', (WidgetTester tester) async {
      final authService = AuthService();
      
      // Initial state should be unauthenticated
      expect(authService.authState, equals(AuthState.initial));
      expect(authService.currentUser, isNull);
      expect(authService.isAuthenticated, isFalse);

      // Initialize the service
      await authService.initialize();

      // After initialization, should be unauthenticated (no saved user)
      expect(authService.authState, equals(AuthState.unauthenticated));
      expect(authService.isAuthenticated, isFalse);
    });

    testWidgets('Should handle onboarding completion', (WidgetTester tester) async {
      // Start with clean state
      SharedPreferences.setMockInitialValues({});
      
      final prefs = await SharedPreferences.getInstance();
      
      // Initially, onboarding should not be completed
      expect(prefs.getBool('onboarding_completed'), isNull);
      
      // Simulate completing onboarding
      await prefs.setBool('onboarding_completed', true);
      
      // Verify it's marked as completed
      expect(prefs.getBool('onboarding_completed'), isTrue);
    });
  });

  group('Theme and Styling Tests', () {
    testWidgets('Splash screen should use app theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthService()),
            ChangeNotifierProvider(create: (_) => ContentService()),
            ChangeNotifierProvider(
              create: (context) => local_audio.AudioService(null, context.read<ContentService>()),
            ),
          ],
          child: MaterialApp(
            home: const SplashScreen(),
          ),
        ),
      );

      // Find the scaffold and verify background color
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, isNotNull);
    });

    testWidgets('Onboarding should use proper styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const OnboardingScreen(),
        ),
      );

      // Verify page indicators are present and styled
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      
      // Verify buttons are properly styled
      expect(find.byType(ElevatedButton), findsAtLeastNWidgets(1));
      expect(find.byType(TextButton), findsAtLeastNWidgets(1));
    });
  });
}
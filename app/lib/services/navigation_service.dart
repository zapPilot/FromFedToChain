import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/home_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/auth/login_screen.dart';
import 'auth_service.dart';

/// Service to handle app navigation logic and routing decisions
class NavigationService {
  /// Determine which screen to show after splash screen initialization
  static Future<Widget> getInitialScreen({
    AuthService? authService,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('onboarding_completed') ?? false;

      // If user hasn't seen onboarding, show onboarding first
      if (!hasSeenOnboarding) {
        return const OnboardingScreen();
      }

      // If user is authenticated, go to home screen
      if (authService?.isAuthenticated == true) {
        return const HomeScreen();
      }

      // Show login screen if user is not authenticated
      return const LoginScreen();
    } catch (e) {
      // On error, default to onboarding
      return const OnboardingScreen();
    }
  }

  /// Create a smooth page transition
  static PageRouteBuilder<T> createRoute<T extends Object?>(
    Widget destination, {
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeInOutCubic,
    Offset begin = const Offset(1.0, 0.0),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => destination,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const end = Offset.zero;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      transitionDuration: duration,
    );
  }

  /// Navigate with slide transition and remove all previous routes
  static void navigateAndClearStack(
    BuildContext context,
    Widget destination, {
    Duration duration = const Duration(milliseconds: 400),
  }) {
    Navigator.of(context).pushAndRemoveUntil(
      createRoute(destination, duration: duration),
      (route) => false,
    );
  }

  /// Navigate with slide transition, keeping the current stack
  static void navigateTo(
    BuildContext context,
    Widget destination, {
    Duration duration = const Duration(milliseconds: 400),
    bool replace = false,
  }) {
    if (replace) {
      Navigator.of(context).pushReplacement(
        createRoute(destination, duration: duration),
      );
    } else {
      Navigator.of(context).push(
        createRoute(destination, duration: duration),
      );
    }
  }

  /// Handle onboarding completion
  static Future<void> completeOnboarding(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    // Navigate to login screen after onboarding
    navigateAndClearStack(context, const LoginScreen());
  }

  /// Handle successful authentication
  static void handleAuthSuccess(BuildContext context) {
    navigateAndClearStack(context, const HomeScreen());
  }

  /// Handle authentication skip
  static void handleAuthSkip(BuildContext context) {
    navigateAndClearStack(context, const HomeScreen());
  }

  /// Reset app state (useful for testing or logout)
  static Future<void> resetAppState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

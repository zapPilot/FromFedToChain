import 'package:flutter_test/flutter_test.dart';

// Import all test files
import 'widgets/audio_list_test.dart' as audio_list_tests;
import 'widgets/mini_player_test.dart' as mini_player_tests;
import 'widgets/filter_bar_test.dart' as filter_bar_tests;
import 'screens/home_screen_test.dart' as home_screen_tests;
import 'integration/user_flow_test.dart' as user_flow_tests;
import 'golden/golden_test.dart' as golden_tests;
import 'accessibility/accessibility_test.dart' as accessibility_tests;
import 'responsive/responsive_test.dart' as responsive_tests;

/// Comprehensive test suite for the Flutter audio streaming app
/// 
/// This file runs all UI regression tests in a structured manner.
/// Use this for comprehensive testing across all aspects of the UI.
void main() {
  group('🎵 Flutter Audio Streaming App - Complete UI Test Suite', () {
    group('📱 Core Widget Tests', () {
      group('AudioList Widget', audio_list_tests.main);
      group('MiniPlayer Widget', mini_player_tests.main);
      group('FilterBar Widget', filter_bar_tests.main);
    });

    group('🏠 Screen Tests', () {
      group('HomeScreen', home_screen_tests.main);
    });

    group('🔄 Integration & User Flow Tests', () {
      group('User Flows', user_flow_tests.main);
    });

    group('🎨 Visual Regression Tests (Golden)', () {
      group('Golden Tests', golden_tests.main);
    });

    group('♿ Accessibility Tests', () {
      group('Accessibility', accessibility_tests.main);
    });

    group('📱 Responsive Design Tests', () {
      group('Responsive', responsive_tests.main);
    });
  });
}

/// Run specific test categories
/// 
/// Usage examples:
/// ```bash
/// # Run all tests
/// flutter test test/test_suite.dart
/// 
/// # Run only widget tests
/// flutter test test/widgets/
/// 
/// # Run only integration tests
/// flutter test test/integration/
/// 
/// # Run only golden tests
/// flutter test test/golden/
/// 
/// # Run only accessibility tests
/// flutter test test/accessibility/
/// 
/// # Run only responsive tests
/// flutter test test/responsive/
/// ```
class TestSuiteRunner {
  /// Test categories for selective testing
  static const Map<String, String> categories = {
    'widgets': 'Core UI component tests',
    'screens': 'Full screen interaction tests',
    'integration': 'User flow and navigation tests',
    'golden': 'Visual regression detection tests',
    'accessibility': 'Screen reader and accessibility tests',
    'responsive': 'Multi-screen and orientation tests',
  };

  /// Performance benchmarks for test execution
  static const Map<String, Duration> expectedDurations = {
    'widgets': Duration(seconds: 30),
    'screens': Duration(seconds: 45),
    'integration': Duration(minutes: 2),
    'golden': Duration(seconds: 60),
    'accessibility': Duration(seconds: 45),
    'responsive': Duration(minutes: 1),
  };

  /// Critical user journeys that must pass
  static const List<String> criticalPaths = [
    'Browse episodes across tabs',
    'Filter episodes by language and category',
    'Search for specific episodes',
    'Play audio and use mini player controls',
    'Navigate to full player screen',
    'Handle loading and error states',
    'Maintain accessibility across all interactions',
    'Adapt to different screen sizes and orientations',
  ];

  /// Coverage requirements for each test category
  static const Map<String, double> coverageTargets = {
    'widgets': 0.95, // 95% coverage for individual widgets
    'screens': 0.90, // 90% coverage for screen interactions
    'integration': 0.85, // 85% coverage for user flows
    'golden': 1.0, // 100% visual consistency
    'accessibility': 0.90, // 90% accessibility compliance
    'responsive': 0.90, // 90% responsive design coverage
  };
}
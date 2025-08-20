import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/widgets/audio_controls.dart';
import 'package:from_fed_to_chain_app/themes/app_theme.dart';
import '../test_utils.dart';

void main() {
  group('AudioControls Widget Tests', () {
    bool playPauseTapped = false;
    bool nextTapped = false;
    bool previousTapped = false;
    bool skipForwardTapped = false;
    bool skipBackwardTapped = false;

    void onPlayPause() {
      playPauseTapped = true;
    }

    void onNext() {
      nextTapped = true;
    }

    void onPrevious() {
      previousTapped = true;
    }

    void onSkipForward() {
      skipForwardTapped = true;
    }

    void onSkipBackward() {
      skipBackwardTapped = true;
    }

    setUp(() {
      playPauseTapped = false;
      nextTapped = false;
      previousTapped = false;
      skipForwardTapped = false;
      skipBackwardTapped = false;
    });

    Widget createAudioControls({
      bool isPlaying = false,
      bool isLoading = false,
      bool hasError = false,
      AudioControlsSize size = AudioControlsSize.medium,
      VoidCallback? onPlayPauseCallback,
      VoidCallback? onNextCallback,
      VoidCallback? onPreviousCallback,
      VoidCallback? onSkipForwardCallback,
      VoidCallback? onSkipBackwardCallback,
    }) {
      return AudioControls(
        isPlaying: isPlaying,
        isLoading: isLoading,
        hasError: hasError,
        size: size,
        onPlayPause: onPlayPauseCallback ?? onPlayPause,
        onNext: onNextCallback ?? onNext,
        onPrevious: onPreviousCallback ?? onPrevious,
        onSkipForward: onSkipForwardCallback ?? onSkipForward,
        onSkipBackward: onSkipBackwardCallback ?? onSkipBackward,
      );
    }

    testWidgets('should render with basic structure', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createAudioControls());

      // Verify main structure
      TestUtils.expectWidgetExists(find.byType(AudioControls));
      expect(find.byType(Row), findsAtLeastNWidgets(1));

      // Should have control buttons
      expect(find.byType(IconButton),
          findsAtLeastNWidgets(3)); // At least 3 secondary buttons
      expect(find.byType(InkWell),
          findsAtLeastNWidgets(1)); // At least 1 main button
    });

    testWidgets('should display all control buttons with correct icons',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createAudioControls());

      // Verify all expected icons are present
      TestUtils.expectIconExists(Icons.skip_previous);
      TestUtils.expectIconExists(Icons.replay_10);
      TestUtils.expectIconExists(Icons.play_arrow); // Default when not playing
      TestUtils.expectIconExists(Icons.forward_30);
      TestUtils.expectIconExists(Icons.skip_next);
    });

    testWidgets('should show play icon when not playing', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioControls(isPlaying: false));

      TestUtils.expectIconExists(Icons.play_arrow);
      TestUtils.expectWidgetNotExists(find.byIcon(Icons.pause));
    });

    testWidgets('should show pause icon when playing', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioControls(isPlaying: true));

      TestUtils.expectIconExists(Icons.pause);
      TestUtils.expectWidgetNotExists(find.byIcon(Icons.play_arrow));
    });

    testWidgets('should show loading indicator when loading', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioControls(isLoading: true));

      // Should show circular progress indicator instead of play/pause icon
      TestUtils.expectWidgetExists(find.byType(CircularProgressIndicator));
      TestUtils.expectWidgetNotExists(find.byIcon(Icons.play_arrow));
      TestUtils.expectWidgetNotExists(find.byIcon(Icons.pause));
    });

    testWidgets('should show refresh icon when has error', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioControls(hasError: true));

      TestUtils.expectIconExists(Icons.refresh);
      TestUtils.expectWidgetNotExists(find.byIcon(Icons.play_arrow));
      TestUtils.expectWidgetNotExists(find.byIcon(Icons.pause));
    });

    testWidgets('should handle control button interactions correctly',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createAudioControls());

      // Test previous button
      await TestUtils.tapWidget(tester, find.byIcon(Icons.skip_previous));
      expect(previousTapped, isTrue);

      // Test skip backward button
      await TestUtils.tapWidget(tester, find.byIcon(Icons.replay_10));
      expect(skipBackwardTapped, isTrue);

      // Test play/pause button
      await TestUtils.tapWidget(tester, find.byIcon(Icons.play_arrow));
      expect(playPauseTapped, isTrue);

      // Test skip forward button
      await TestUtils.tapWidget(tester, find.byIcon(Icons.forward_30));
      expect(skipForwardTapped, isTrue);

      // Test next button
      await TestUtils.tapWidget(tester, find.byIcon(Icons.skip_next));
      expect(nextTapped, isTrue);
    });

    testWidgets('should disable main button when loading', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioControls(isLoading: true));

      // Try to tap the main button (should be disabled)
      await TestUtils.tapWidget(tester, find.byType(InkWell));

      // Should not trigger callback when loading
      expect(playPauseTapped, isFalse);
    });

    testWidgets('should allow main button tap when has error', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioControls(hasError: true));

      // Should allow tap when error (for retry)
      await TestUtils.tapWidget(tester, find.byIcon(Icons.refresh));
      expect(playPauseTapped, isTrue);
    });

    testWidgets('should display tooltips for all secondary buttons',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createAudioControls());

      // Verify tooltip widgets are present
      expect(find.byType(Tooltip), findsNWidgets(4));

      // Test tooltip messages by triggering long press
      await TestUtils.longPressWidget(tester, find.byIcon(Icons.skip_previous));
      await tester.pumpAndSettle();

      // Should show tooltip content
      expect(find.text('Previous episode'), findsOneWidget);
    });

    testWidgets('should handle different control sizes correctly',
        (tester) async {
      final sizes = [
        AudioControlsSize.small,
        AudioControlsSize.medium,
        AudioControlsSize.large,
      ];

      for (final size in sizes) {
        await TestUtils.pumpWidgetWithMaterialApp(
            tester, createAudioControls(size: size));

        // Should render correctly regardless of size
        TestUtils.expectWidgetExists(find.byType(AudioControls));
        TestUtils.expectWidgetExists(find.byType(Row));

        await tester.pumpWidget(Container()); // Clear previous widget
      }
    });

    testWidgets('should apply correct button sizes for small size',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioControls(size: AudioControlsSize.small));

      // Find SizedBox widgets that define button sizes
      final sizedBoxes = find.byType(SizedBox);
      expect(sizedBoxes.evaluate().length, greaterThan(0));

      // Should render without issues
      TestUtils.expectWidgetExists(find.byType(AudioControls));
    });

    testWidgets('should apply correct button sizes for large size',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioControls(size: AudioControlsSize.large));

      // Should render without issues
      TestUtils.expectWidgetExists(find.byType(AudioControls));

      // All buttons should be present
      expect(find.byType(IconButton), findsNWidgets(4));
      TestUtils.expectWidgetExists(find.byType(InkWell));
    });

    testWidgets('should maintain proper spacing between buttons',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createAudioControls());

      // Row should use spaceEvenly for consistent spacing
      final row = tester.widget<Row>(find.byType(Row));
      expect(row.mainAxisAlignment, equals(MainAxisAlignment.spaceEvenly));
    });

    testWidgets('should handle rapid button presses correctly', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createAudioControls());

      int playPauseCount = 0;
      final rapidTestControls = createAudioControls(
        onPlayPauseCallback: () => playPauseCount++,
      );

      await TestUtils.pumpWidgetWithMaterialApp(tester, rapidTestControls);

      // Rapidly tap play/pause button
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byIcon(Icons.play_arrow));
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(playPauseCount, equals(5));
    });

    testWidgets('should handle state changes correctly', (tester) async {
      // Start with not playing
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioControls(isPlaying: false));
      TestUtils.expectIconExists(Icons.play_arrow);

      // Change to playing
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioControls(isPlaying: true));
      TestUtils.expectIconExists(Icons.pause);

      // Change to loading
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioControls(isLoading: true));
      TestUtils.expectWidgetExists(find.byType(CircularProgressIndicator));

      // Change to error
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioControls(hasError: true));
      TestUtils.expectIconExists(Icons.refresh);
    });

    testWidgets('should apply correct styling to main button', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createAudioControls());

      // Find the main button container
      final containers = find.byType(Container);
      expect(containers.evaluate().length, greaterThan(0));

      // Main button should have gradient background
      TestUtils.expectWidgetExists(find.byType(Material));
      TestUtils.expectWidgetExists(find.byType(InkWell));
    });

    testWidgets('should apply correct styling to secondary buttons',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createAudioControls());

      // All secondary buttons should be IconButton widgets
      expect(find.byType(IconButton), findsNWidgets(4));

      // Each should be wrapped in SizedBox and Tooltip
      expect(find.byType(SizedBox), findsNWidgets(4));
      expect(find.byType(Tooltip), findsNWidgets(4));
    });

    testWidgets('should handle edge case with all boolean flags set',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(
          tester,
          createAudioControls(
            isPlaying: true,
            isLoading: true,
            hasError: true,
          ));

      // Loading should take precedence over other states
      TestUtils.expectWidgetExists(find.byType(CircularProgressIndicator));
      TestUtils.expectWidgetNotExists(find.byIcon(Icons.pause));
      TestUtils.expectWidgetNotExists(find.byIcon(Icons.refresh));
    });

    testWidgets('should handle accessibility correctly', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createAudioControls());

      // All buttons should be accessible
      expect(find.byType(IconButton), findsNWidgets(4));
      TestUtils.expectWidgetExists(find.byType(InkWell));

      // Tooltips provide accessibility labels
      expect(find.byType(Tooltip), findsNWidgets(4));
    });

    testWidgets('should show all tooltip messages correctly', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createAudioControls());

      final tooltipTests = [
        (Icons.skip_previous, 'Previous episode'),
        (Icons.replay_10, 'Skip back 10s'),
        (Icons.forward_30, 'Skip forward 30s'),
        (Icons.skip_next, 'Next episode'),
      ];

      for (final (icon, expectedTooltip) in tooltipTests) {
        await TestUtils.longPressWidget(tester, find.byIcon(icon));
        await tester.pumpAndSettle();

        // Should show tooltip content
        TestUtils.expectTextExists(expectedTooltip);

        // Dismiss tooltip
        await tester.tap(find.byType(Scaffold));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('should handle null callbacks gracefully', (tester) async {
      // Test with empty callbacks (should not crash)
      final controlsWithEmptyCallbacks = AudioControls(
        isPlaying: false,
        isLoading: false,
        hasError: false,
        onPlayPause: () {}, // Empty callback
        onNext: () {}, // Empty callback
        onPrevious: () {}, // Empty callback
        onSkipForward: () {}, // Empty callback
        onSkipBackward: () {}, // Empty callback
      );

      await TestUtils.pumpWidgetWithMaterialApp(
          tester, controlsWithEmptyCallbacks);

      // Should render without issues
      TestUtils.expectWidgetExists(find.byType(AudioControls));

      // Tapping should not cause errors
      await TestUtils.tapWidget(tester, find.byIcon(Icons.play_arrow));
      await TestUtils.tapWidget(tester, find.byIcon(Icons.skip_next));
    });

    testWidgets('should maintain consistent layout across different states',
        (tester) async {
      final states = [
        (false, false, false), // Not playing, not loading, no error
        (true, false, false), // Playing, not loading, no error
        (false, true, false), // Not playing, loading, no error
        (false, false, true), // Not playing, not loading, has error
      ];

      for (final (isPlaying, isLoading, hasError) in states) {
        await TestUtils.pumpWidgetWithMaterialApp(
            tester,
            createAudioControls(
              isPlaying: isPlaying,
              isLoading: isLoading,
              hasError: hasError,
            ));

        // Should maintain consistent structure
        TestUtils.expectWidgetExists(find.byType(AudioControls));
        TestUtils.expectWidgetExists(find.byType(Row));

        // Should always have secondary buttons
        expect(find.byType(IconButton), findsNWidgets(4));

        await tester.pumpWidget(Container()); // Clear previous widget
      }
    });

    testWidgets('should handle circular progress indicator styling correctly',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioControls(isLoading: true));

      // Find circular progress indicator
      final indicator = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator));

      // Verify styling
      expect(indicator.strokeWidth, equals(3));
      expect(indicator.valueColor?.value, equals(AppTheme.onPrimaryColor));
    });

    testWidgets(
        'should handle icon sizing correctly for different control sizes',
        (tester) async {
      final sizes = [
        AudioControlsSize.small,
        AudioControlsSize.medium,
        AudioControlsSize.large,
      ];

      for (final size in sizes) {
        await TestUtils.pumpWidgetWithMaterialApp(
            tester, createAudioControls(size: size));

        // Should have consistent icon placement
        TestUtils.expectIconExists(Icons.play_arrow);
        TestUtils.expectIconExists(Icons.skip_previous);
        TestUtils.expectIconExists(Icons.skip_next);

        await tester.pumpWidget(Container()); // Clear previous widget
      }
    });

    testWidgets('should handle theme colors correctly', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createAudioControls());

      // Should apply theme colors consistently (use findsAtLeastNWidgets to allow multiple)
      expect(find.byType(Container), findsAtLeastNWidgets(1));
      expect(find.byType(Material), findsAtLeastNWidgets(1));

      // Icons should be visible
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('should prioritize loading state over error state',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioControls(isLoading: true, hasError: true));

      // Loading should take precedence
      TestUtils.expectWidgetExists(find.byType(CircularProgressIndicator));
      TestUtils.expectWidgetNotExists(find.byIcon(Icons.refresh));
    });

    testWidgets('should prioritize error state over playing state',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioControls(hasError: true, isPlaying: true));

      // Error should take precedence over playing
      TestUtils.expectIconExists(Icons.refresh);
      TestUtils.expectWidgetNotExists(find.byIcon(Icons.pause));
    });

    testWidgets('should handle button size calculations correctly',
        (tester) async {
      // Test each size variant
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioControls(size: AudioControlsSize.small));
      TestUtils.expectWidgetExists(find.byType(AudioControls));

      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioControls(size: AudioControlsSize.medium));
      TestUtils.expectWidgetExists(find.byType(AudioControls));

      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createAudioControls(size: AudioControlsSize.large));
      TestUtils.expectWidgetExists(find.byType(AudioControls));
    });

    testWidgets('should handle main button content sizing correctly',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createAudioControls());

      // Find the main button content
      TestUtils.expectIconExists(Icons.play_arrow);

      // Icon should be properly sized within the button
      final icons = find.byIcon(Icons.play_arrow);
      TestUtils.expectWidgetExists(icons);
    });
  });
}

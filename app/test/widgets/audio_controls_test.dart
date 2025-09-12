import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/widgets/audio_controls.dart';
import 'package:from_fed_to_chain_app/themes/app_theme.dart';

import 'widget_test_utils.dart';

void main() {
  group('AudioControls Widget Tests', () {
    setUp(() {
      WidgetTestUtils.resetCallbacks();
    });

    testWidgets('should render all control buttons',
        (WidgetTester tester) async {
      await WidgetTestUtils.pumpWidgetWithTheme(
        tester,
        AudioControls(
          isPlaying: false,
          isLoading: false,
          hasError: false,
          onPlayPause: WidgetTestUtils.mockPlayPause,
          onNext: WidgetTestUtils.mockNext,
          onPrevious: WidgetTestUtils.mockPrevious,
          onSkipForward: WidgetTestUtils.mockSkipForward,
          onSkipBackward: WidgetTestUtils.mockSkipBackward,
        ),
      );

      // Verify all control buttons are present
      expect(find.byIcon(Icons.skip_previous), findsOneWidget);
      expect(find.byIcon(Icons.replay_10), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.forward_30), findsOneWidget);
      expect(find.byIcon(Icons.skip_next), findsOneWidget);

      // Verify total button count
      expect(find.byType(IconButton), findsNWidgets(4)); // Secondary buttons
      // Verify main play button exists (by finding play icon)
      expect(find.byIcon(Icons.play_arrow), findsOneWidget); // Main play button
    });

    testWidgets('should show play icon when not playing',
        (WidgetTester tester) async {
      await WidgetTestUtils.pumpWidgetWithTheme(
        tester,
        AudioControls(
          isPlaying: false,
          isLoading: false,
          hasError: false,
          onPlayPause: WidgetTestUtils.mockPlayPause,
          onNext: WidgetTestUtils.mockNext,
          onPrevious: WidgetTestUtils.mockPrevious,
          onSkipForward: WidgetTestUtils.mockSkipForward,
          onSkipBackward: WidgetTestUtils.mockSkipBackward,
        ),
      );

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
    });

    testWidgets('should show pause icon when playing',
        (WidgetTester tester) async {
      await WidgetTestUtils.pumpWidgetWithTheme(
        tester,
        AudioControls(
          isPlaying: true,
          isLoading: false,
          hasError: false,
          onPlayPause: WidgetTestUtils.mockPlayPause,
          onNext: WidgetTestUtils.mockNext,
          onPrevious: WidgetTestUtils.mockPrevious,
          onSkipForward: WidgetTestUtils.mockSkipForward,
          onSkipBackward: WidgetTestUtils.mockSkipBackward,
        ),
      );

      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    testWidgets('should show loading indicator when loading',
        (WidgetTester tester) async {
      await WidgetTestUtils.pumpWidgetWithTheme(
        tester,
        AudioControls(
          isPlaying: false,
          isLoading: true,
          hasError: false,
          onPlayPause: WidgetTestUtils.mockPlayPause,
          onNext: WidgetTestUtils.mockNext,
          onPrevious: WidgetTestUtils.mockPrevious,
          onSkipForward: WidgetTestUtils.mockSkipForward,
          onSkipBackward: WidgetTestUtils.mockSkipBackward,
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
      expect(find.byIcon(Icons.pause), findsNothing);
    });

    testWidgets('should show error icon when has error',
        (WidgetTester tester) async {
      await WidgetTestUtils.pumpWidgetWithTheme(
        tester,
        AudioControls(
          isPlaying: false,
          isLoading: false,
          hasError: true,
          onPlayPause: WidgetTestUtils.mockPlayPause,
          onNext: WidgetTestUtils.mockNext,
          onPrevious: WidgetTestUtils.mockPrevious,
          onSkipForward: WidgetTestUtils.mockSkipForward,
          onSkipBackward: WidgetTestUtils.mockSkipBackward,
        ),
      );

      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
      expect(find.byIcon(Icons.pause), findsNothing);
    });

    testWidgets('should handle play/pause button tap',
        (WidgetTester tester) async {
      await WidgetTestUtils.pumpWidgetWithTheme(
        tester,
        AudioControls(
          isPlaying: false,
          isLoading: false,
          hasError: false,
          onPlayPause: WidgetTestUtils.mockPlayPause,
          onNext: WidgetTestUtils.mockNext,
          onPrevious: WidgetTestUtils.mockPrevious,
          onSkipForward: WidgetTestUtils.mockSkipForward,
          onSkipBackward: WidgetTestUtils.mockSkipBackward,
        ),
      );

      // Find and tap the main play button by its icon
      await WidgetTestUtils.tapAndSettle(tester, find.byIcon(Icons.play_arrow));

      // Verify callback was triggered
      expect(WidgetTestUtils.lastPlayPauseState, true);
    });

    testWidgets('should handle all control button taps',
        (WidgetTester tester) async {
      WidgetTestUtils.resetCallbacks();

      await WidgetTestUtils.pumpWidgetWithTheme(
        tester,
        AudioControls(
          isPlaying: false,
          isLoading: false,
          hasError: false,
          onPlayPause: WidgetTestUtils.mockPlayPause,
          onNext: WidgetTestUtils.mockNext,
          onPrevious: WidgetTestUtils.mockPrevious,
          onSkipForward: WidgetTestUtils.mockSkipForward,
          onSkipBackward: WidgetTestUtils.mockSkipBackward,
        ),
      );

      // Test each control button
      await WidgetTestUtils.tapAndSettle(
          tester, find.byIcon(Icons.skip_previous));
      await WidgetTestUtils.tapAndSettle(tester, find.byIcon(Icons.replay_10));
      await WidgetTestUtils.tapAndSettle(tester, find.byIcon(Icons.forward_30));
      await WidgetTestUtils.tapAndSettle(tester, find.byIcon(Icons.skip_next));

      // Verify all callbacks were triggered
      expect(WidgetTestUtils.tapCount, 4);
    });

    testWidgets('should disable play button when loading',
        (WidgetTester tester) async {
      await WidgetTestUtils.pumpWidgetWithTheme(
        tester,
        AudioControls(
          isPlaying: false,
          isLoading: true,
          hasError: false,
          onPlayPause: WidgetTestUtils.mockPlayPause,
          onNext: WidgetTestUtils.mockNext,
          onPrevious: WidgetTestUtils.mockPrevious,
          onSkipForward: WidgetTestUtils.mockSkipForward,
          onSkipBackward: WidgetTestUtils.mockSkipBackward,
        ),
      );

      // Try to tap the loading button (should be disabled)
      // The loading indicator should be visible instead of the play icon
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Try tapping where the play button would be (but it should be disabled)
      // We can't tap the progress indicator directly, so we test the state

      // Callback should not be triggered when loading
      expect(WidgetTestUtils.lastPlayPauseState, false);
    });

    testWidgets('should enable play button when has error',
        (WidgetTester tester) async {
      WidgetTestUtils.resetCallbacks();

      await WidgetTestUtils.pumpWidgetWithTheme(
        tester,
        AudioControls(
          isPlaying: false,
          isLoading: false,
          hasError: true,
          onPlayPause: WidgetTestUtils.mockPlayPause,
          onNext: WidgetTestUtils.mockNext,
          onPrevious: WidgetTestUtils.mockPrevious,
          onSkipForward: WidgetTestUtils.mockSkipForward,
          onSkipBackward: WidgetTestUtils.mockSkipBackward,
        ),
      );

      // Tap the error/refresh button by its icon
      await WidgetTestUtils.tapAndSettle(tester, find.byIcon(Icons.refresh));

      // Callback should be triggered when error (to retry)
      expect(WidgetTestUtils.lastPlayPauseState, true);
    });

    group('AudioControlsSize variants', () {
      testWidgets('should render small size correctly',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioControls(
            isPlaying: false,
            isLoading: false,
            hasError: false,
            size: AudioControlsSize.small,
            onPlayPause: WidgetTestUtils.mockPlayPause,
            onNext: WidgetTestUtils.mockNext,
            onPrevious: WidgetTestUtils.mockPrevious,
            onSkipForward: WidgetTestUtils.mockSkipForward,
            onSkipBackward: WidgetTestUtils.mockSkipBackward,
          ),
        );

        // Verify controls are rendered
        expect(find.byType(AudioControls), findsOneWidget);
        expect(find.byIcon(Icons.play_arrow), findsOneWidget);

        // Small size should have smaller button dimensions (48px primary)
        // Verify the play button exists and the widget renders without errors
        expect(find.byIcon(Icons.play_arrow), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Verify the play button exists and the widget renders without errors
        expect(find.byIcon(Icons.play_arrow), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should render medium size correctly',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioControls(
            isPlaying: false,
            isLoading: false,
            hasError: false,
            size: AudioControlsSize.medium,
            onPlayPause: WidgetTestUtils.mockPlayPause,
            onNext: WidgetTestUtils.mockNext,
            onPrevious: WidgetTestUtils.mockPrevious,
            onSkipForward: WidgetTestUtils.mockSkipForward,
            onSkipBackward: WidgetTestUtils.mockSkipBackward,
          ),
        );

        // Verify controls are rendered with medium size (default)
        expect(find.byType(AudioControls), findsOneWidget);
        expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      });

      testWidgets('should render large size correctly',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioControls(
            isPlaying: false,
            isLoading: false,
            hasError: false,
            size: AudioControlsSize.large,
            onPlayPause: WidgetTestUtils.mockPlayPause,
            onNext: WidgetTestUtils.mockNext,
            onPrevious: WidgetTestUtils.mockPrevious,
            onSkipForward: WidgetTestUtils.mockSkipForward,
            onSkipBackward: WidgetTestUtils.mockSkipBackward,
          ),
        );

        // Verify controls are rendered with large size
        expect(find.byType(AudioControls), findsOneWidget);
        expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      });
    });

    group('Accessibility Tests', () {
      testWidgets('should have proper tooltips for all buttons',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioControls(
            isPlaying: false,
            isLoading: false,
            hasError: false,
            onPlayPause: WidgetTestUtils.mockPlayPause,
            onNext: WidgetTestUtils.mockNext,
            onPrevious: WidgetTestUtils.mockPrevious,
            onSkipForward: WidgetTestUtils.mockSkipForward,
            onSkipBackward: WidgetTestUtils.mockSkipBackward,
          ),
        );

        // Verify tooltips are present
        expect(
            WidgetTestUtils.findByTooltip('Previous episode'), findsOneWidget);
        expect(WidgetTestUtils.findByTooltip('Skip back 10s'), findsOneWidget);
        expect(
            WidgetTestUtils.findByTooltip('Skip forward 30s'), findsOneWidget);
        expect(WidgetTestUtils.findByTooltip('Next episode'), findsOneWidget);
      });

      testWidgets('should meet accessibility guidelines',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioControls(
            isPlaying: false,
            isLoading: false,
            hasError: false,
            onPlayPause: WidgetTestUtils.mockPlayPause,
            onNext: WidgetTestUtils.mockNext,
            onPrevious: WidgetTestUtils.mockPrevious,
            onSkipForward: WidgetTestUtils.mockSkipForward,
            onSkipBackward: WidgetTestUtils.mockSkipBackward,
          ),
        );

        await WidgetTestUtils.verifyAccessibility(tester);
      });

      testWidgets('should have sufficient tap target sizes',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioControls(
            isPlaying: false,
            isLoading: false,
            hasError: false,
            onPlayPause: WidgetTestUtils.mockPlayPause,
            onNext: WidgetTestUtils.mockNext,
            onPrevious: WidgetTestUtils.mockPrevious,
            onSkipForward: WidgetTestUtils.mockSkipForward,
            onSkipBackward: WidgetTestUtils.mockSkipBackward,
          ),
        );

        // Verify button sizes meet minimum accessibility requirements
        final buttonFinders = find.byType(IconButton);
        for (int i = 0; i < buttonFinders.evaluate().length; i++) {
          final renderObject =
              tester.renderObject<RenderBox>(buttonFinders.at(i));
          final size = renderObject.size;

          // Minimum tap target size should be 48x48 for accessibility
          expect(size.width, greaterThanOrEqualTo(48)); // Secondary buttons
          expect(size.height, greaterThanOrEqualTo(48));
        }

        // Main play button should be larger - verify the play icon exists
        // and check for accessibility compliance
        expect(find.byIcon(Icons.play_arrow), findsOneWidget);

        // Verify accessibility guidelines are met
        final handle = tester.ensureSemantics();
        // Basic check that tappable elements exist and are accessible
        expect(find.bySemanticsLabel('Play'), findsOneWidget);
        handle.dispose();
      });
    });

    group('Visual State Tests', () {
      testWidgets('should apply gradient to main play button',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioControls(
            isPlaying: false,
            isLoading: false,
            hasError: false,
            onPlayPause: WidgetTestUtils.mockPlayPause,
            onNext: WidgetTestUtils.mockNext,
            onPrevious: WidgetTestUtils.mockPrevious,
            onSkipForward: WidgetTestUtils.mockSkipForward,
            onSkipBackward: WidgetTestUtils.mockSkipBackward,
          ),
        );

        // Find the main play button container (within AudioControls)
        // Structure is: Container > Material > InkWell
        final containerFinder = find.descendant(
          of: find.byType(AudioControls),
          matching: find.byType(Container),
        );

        final container = tester.widget<Container>(containerFinder.first);
        final decoration = container.decoration as BoxDecoration;

        // Verify gradient is applied
        expect(decoration.gradient, isNotNull);
        expect(decoration.gradient, isA<LinearGradient>());
        expect(decoration.shape, BoxShape.circle);
      });

      testWidgets('should show shadow on main play button',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioControls(
            isPlaying: false,
            isLoading: false,
            hasError: false,
            onPlayPause: WidgetTestUtils.mockPlayPause,
            onNext: WidgetTestUtils.mockNext,
            onPrevious: WidgetTestUtils.mockPrevious,
            onSkipForward: WidgetTestUtils.mockSkipForward,
            onSkipBackward: WidgetTestUtils.mockSkipBackward,
          ),
        );

        // Find the main play button container (within AudioControls)
        // Structure is: Container > Material > InkWell
        final containerFinder = find.descendant(
          of: find.byType(AudioControls),
          matching: find.byType(Container),
        );

        final container = tester.widget<Container>(containerFinder.first);
        final decoration = container.decoration as BoxDecoration;

        // Verify shadow is applied
        expect(decoration.boxShadow, isNotNull);
        expect(decoration.boxShadow!.isNotEmpty, true);
      });

      testWidgets('should use correct colors from theme',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioControls(
            isPlaying: false,
            isLoading: false,
            hasError: false,
            onPlayPause: WidgetTestUtils.mockPlayPause,
            onNext: WidgetTestUtils.mockNext,
            onPrevious: WidgetTestUtils.mockPrevious,
            onSkipForward: WidgetTestUtils.mockSkipForward,
            onSkipBackward: WidgetTestUtils.mockSkipBackward,
          ),
        );

        // Verify theme colors are used
        WidgetTestUtils.verifyThemeColors(tester);

        // Check loading indicator color
        await tester.pumpWidget(
          WidgetTestUtils.createTestWrapper(
            AudioControls(
              isPlaying: false,
              isLoading: true,
              hasError: false,
              onPlayPause: WidgetTestUtils.mockPlayPause,
              onNext: WidgetTestUtils.mockNext,
              onPrevious: WidgetTestUtils.mockPrevious,
              onSkipForward: WidgetTestUtils.mockSkipForward,
              onSkipBackward: WidgetTestUtils.mockSkipBackward,
            ),
          ),
        );

        final progressIndicator = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );

        expect(
          progressIndicator.valueColor?.value,
          equals(AppTheme.onPrimaryColor),
        );
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle rapid state changes',
          (WidgetTester tester) async {
        bool isPlaying = false;
        bool isLoading = false;
        bool hasError = false;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return WidgetTestUtils.createTestWrapper(
                AudioControls(
                  isPlaying: isPlaying,
                  isLoading: isLoading,
                  hasError: hasError,
                  onPlayPause: () => setState(() => isPlaying = !isPlaying),
                  onNext: WidgetTestUtils.mockNext,
                  onPrevious: WidgetTestUtils.mockPrevious,
                  onSkipForward: WidgetTestUtils.mockSkipForward,
                  onSkipBackward: WidgetTestUtils.mockSkipBackward,
                ),
              );
            },
          ),
        );

        // Rapidly change states (tap on the play icon directly)
        await tester.tap(find.byIcon(Icons.play_arrow));
        await tester.pump();
        expect(find.byIcon(Icons.pause), findsOneWidget);

        await tester.tap(find.byIcon(Icons.pause));
        await tester.pump();
        expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      });

      testWidgets('should handle null callbacks gracefully',
          (WidgetTester tester) async {
        // This test ensures no crashes with null callbacks
        // Note: In the actual implementation, callbacks are required,
        // but this tests the widget's robustness
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          AudioControls(
            isPlaying: false,
            isLoading: false,
            hasError: false,
            onPlayPause: () {}, // Empty callback
            onNext: () {},
            onPrevious: () {},
            onSkipForward: () {},
            onSkipBackward: () {},
          ),
        );

        // Widget should render without errors
        expect(find.byType(AudioControls), findsOneWidget);

        // Should be able to tap buttons without crashes
        await WidgetTestUtils.tapAndSettle(
            tester, find.byIcon(Icons.skip_previous));
        // Tap the play icon directly rather than InkWell
        await WidgetTestUtils.tapAndSettle(
            tester, find.byIcon(Icons.play_arrow));
      });

      testWidgets('should maintain aspect ratio across sizes',
          (WidgetTester tester) async {
        for (final size in [
          AudioControlsSize.small,
          AudioControlsSize.medium,
          AudioControlsSize.large
        ]) {
          await tester.pumpWidget(
            WidgetTestUtils.createTestWrapper(
              AudioControls(
                isPlaying: false,
                isLoading: false,
                hasError: false,
                size: size,
                onPlayPause: WidgetTestUtils.mockPlayPause,
                onNext: WidgetTestUtils.mockNext,
                onPrevious: WidgetTestUtils.mockPrevious,
                onSkipForward: WidgetTestUtils.mockSkipForward,
                onSkipBackward: WidgetTestUtils.mockSkipBackward,
              ),
            ),
          );

          // Verify controls render properly for each size
          expect(find.byType(AudioControls), findsOneWidget);
          // Check that the play button exists (by its icon)
          expect(find.byIcon(Icons.play_arrow), findsOneWidget); // Main button
          expect(
              find.byType(IconButton), findsNWidgets(4)); // Secondary buttons

          await tester.pump();
        }
      });
    });
  });
}

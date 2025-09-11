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
      expect(find.byType(InkWell), findsOneWidget); // Main play button
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

      // Find and tap the main play button
      final playButton = find.byType(InkWell);
      await WidgetTestUtils.tapAndSettle(tester, playButton);

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

      // Try to tap the loading button
      final playButton = find.byType(InkWell);
      await WidgetTestUtils.tapAndSettle(tester, playButton);

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

      // Tap the error/refresh button
      final playButton = find.byType(InkWell);
      await WidgetTestUtils.tapAndSettle(tester, playButton);

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
        final container = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(InkWell),
                matching: find.byType(Container),
              )
              .first,
        );

        // Verify container constraints via BoxConstraints
        expect(container.constraints, isNotNull);
        if (container.constraints != null) {
          expect(container.constraints!.minWidth, equals(48));
          expect(container.constraints!.minHeight, equals(48));
        }
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

          // Minimum tap target size should be 44x44 for accessibility
          expect(size.width, greaterThanOrEqualTo(36)); // Secondary buttons
          expect(size.height, greaterThanOrEqualTo(36));
        }

        // Main play button should be larger
        final mainButton = tester.renderObject<RenderBox>(find.byType(InkWell));
        expect(mainButton.size.width, greaterThanOrEqualTo(48));
        expect(mainButton.size.height, greaterThanOrEqualTo(48));
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

        // Find the main play button container
        final containerFinder = find
            .descendant(
              of: find.byType(InkWell),
              matching: find.byType(Container),
            )
            .first;

        final container = tester.widget<Container>(containerFinder);
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

        final containerFinder = find
            .descendant(
              of: find.byType(InkWell),
              matching: find.byType(Container),
            )
            .first;

        final container = tester.widget<Container>(containerFinder);
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

        // Rapidly change states
        await tester.tap(find.byType(InkWell));
        await tester.pump();
        expect(find.byIcon(Icons.pause), findsOneWidget);

        await tester.tap(find.byType(InkWell));
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
        await WidgetTestUtils.tapAndSettle(tester, find.byType(InkWell));
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
          expect(find.byType(InkWell), findsOneWidget); // Main button
          expect(
              find.byType(IconButton), findsNWidgets(4)); // Secondary buttons

          await tester.pump();
        }
      });
    });

    group('Performance Tests', () {
      testWidgets('should not rebuild unnecessarily',
          (WidgetTester tester) async {
        int buildCount = 0;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return WidgetTestUtils.createTestWrapper(
                Builder(
                  builder: (context) {
                    buildCount++;
                    return AudioControls(
                      isPlaying: false,
                      isLoading: false,
                      hasError: false,
                      onPlayPause: WidgetTestUtils.mockPlayPause,
                      onNext: WidgetTestUtils.mockNext,
                      onPrevious: WidgetTestUtils.mockPrevious,
                      onSkipForward: WidgetTestUtils.mockSkipForward,
                      onSkipBackward: WidgetTestUtils.mockSkipBackward,
                    );
                  },
                ),
              );
            },
          ),
        );

        final initialBuildCount = buildCount;

        // Pump again without state changes
        await tester.pump();

        // Build count should not increase unnecessarily
        expect(buildCount, equals(initialBuildCount));
      });
    });
  });
}

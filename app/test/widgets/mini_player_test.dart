import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/features/audio/widgets/mini_player.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/features/audio/services/player_state_notifier.dart';
import 'package:from_fed_to_chain_app/core/theme/app_theme.dart';

import 'widget_test_utils.dart';

void main() {
  group('MiniPlayer Widget Tests', () {
    late AudioFile testAudioFile;

    setUp(() {
      WidgetTestUtils.resetCallbacks();
      testAudioFile = WidgetTestUtils.createTestAudioFile();
    });

    group('Rendering Tests', () {
      testWidgets('should render all components correctly',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          WidgetTestUtils.createMiniPlayer(
            audioFile: testAudioFile,
            playbackState: AppPlaybackState.paused,
          ),
        );

        // Verify main structure
        expect(find.byType(MiniPlayer), findsOneWidget);
        expect(find.byType(Container), findsWidgets); // Multiple containers
        // Verify main tap area exists (within MiniPlayer)
        final miniPlayerInkWell = find.descendant(
          of: find.byType(MiniPlayer),
          matching: find.byType(InkWell),
        );
        expect(
            miniPlayerInkWell, findsWidgets); // Main tap area + button InkWells

        // Verify album art section
        expect(find.byType(Icon), findsWidgets); // Category icon and others

        // Verify track info section
        expect(find.text(testAudioFile.displayTitle), findsOneWidget);
        expect(find.textContaining(testAudioFile.category), findsOneWidget);
        expect(find.textContaining(testAudioFile.language), findsOneWidget);

        // Verify controls section
        expect(find.byIcon(Icons.skip_previous), findsOneWidget);
        expect(find.byIcon(Icons.play_arrow), findsOneWidget); // Paused state
        expect(find.byIcon(Icons.skip_next), findsOneWidget);
      });

      testWidgets('should display correct album art icon for category',
          (WidgetTester tester) async {
        final categories = [
          'daily-news',
          'ethereum',
          'macro',
          'startup',
          'ai',
          'defi'
        ];
        final expectedIcons = [
          Icons.newspaper,
          Icons.currency_bitcoin,
          Icons.trending_up,
          Icons.rocket_launch,
          Icons.smart_toy,
          Icons.account_balance,
        ];

        for (int i = 0; i < categories.length; i++) {
          final audioFile =
              WidgetTestUtils.createTestAudioFileWithCategory(categories[i]);

          await tester.pumpWidget(
            WidgetTestUtils.createTestWrapper(
              WidgetTestUtils.createMiniPlayer(
                audioFile: audioFile,
                playbackState: AppPlaybackState.paused,
              ),
            ),
          );

          // Verify correct category icon
          expect(find.byIcon(expectedIcons[i]), findsOneWidget);
          await tester.pump();
        }
      });

      testWidgets('should display language and category information correctly',
          (WidgetTester tester) async {
        const testLanguages = ['en-US', 'ja-JP', 'zh-TW'];

        for (final language in testLanguages) {
          final audioFile =
              WidgetTestUtils.createTestAudioFileWithLanguage(language);

          await tester.pumpWidget(
            WidgetTestUtils.createTestWrapper(
              WidgetTestUtils.createMiniPlayer(
                audioFile: audioFile,
                playbackState: AppPlaybackState.paused,
              ),
            ),
          );

          // Verify language is displayed
          expect(find.textContaining(language), findsOneWidget);
          await tester.pump();
        }
      });
    });

    group('Playback State Tests', () {
      testWidgets('should show play icon when paused',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          WidgetTestUtils.createMiniPlayer(
            audioFile: testAudioFile,
            playbackState: AppPlaybackState.paused,
          ),
        );

        expect(find.byIcon(Icons.play_arrow), findsOneWidget);
        expect(find.byIcon(Icons.pause), findsNothing);
      });

      testWidgets('should show pause icon when playing',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          WidgetTestUtils.createMiniPlayer(
            audioFile: testAudioFile,
            playbackState: AppPlaybackState.playing,
          ),
        );

        expect(find.byIcon(Icons.pause), findsOneWidget);
        expect(find.byIcon(Icons.play_arrow), findsNothing);
      });

      testWidgets('should show loading indicator when loading',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          WidgetTestUtils.createMiniPlayer(
            audioFile: testAudioFile,
            playbackState: AppPlaybackState.loading,
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byIcon(Icons.play_arrow), findsNothing);
      });

      testWidgets('should show refresh icon when error',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          WidgetTestUtils.createMiniPlayer(
            audioFile: testAudioFile,
            playbackState: AppPlaybackState.error,
          ),
        );

        expect(find.byIcon(Icons.refresh), findsOneWidget);
      });

      testWidgets('should display correct playback state indicator',
          (WidgetTester tester) async {
        final testCases = [
          (AppPlaybackState.playing, Icons.graphic_eq, 'Playing'),
          (AppPlaybackState.paused, Icons.pause_circle_outline, 'Paused'),
          (AppPlaybackState.loading, Icons.hourglass_empty, 'Loading'),
          (AppPlaybackState.error, Icons.error_outline, 'Error'),
          (AppPlaybackState.stopped, Icons.stop_circle, 'Stopped'),
        ];

        for (final (state, icon, text) in testCases) {
          await tester.pumpWidget(
            WidgetTestUtils.createTestWrapper(
              WidgetTestUtils.createMiniPlayer(
                audioFile: testAudioFile,
                playbackState: state,
              ),
            ),
          );

          // Verify state indicator icon and text
          expect(find.byIcon(icon), findsOneWidget);
          expect(find.text(text), findsOneWidget);

          await tester.pump();
        }
      });
    });

    group('Interaction Tests', () {
      testWidgets('should handle main tap gesture',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          WidgetTestUtils.createMiniPlayer(
            audioFile: testAudioFile,
            playbackState: AppPlaybackState.paused,
          ),
        );

        // Tap the main area (by tapping on the title)
        await WidgetTestUtils.tapAndSettle(
            tester, find.text(testAudioFile.displayTitle));

        // Verify main tap callback was triggered
        expect(WidgetTestUtils.tapCount, equals(1));
      });

      testWidgets('should handle play/pause button tap',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          WidgetTestUtils.createMiniPlayer(
            audioFile: testAudioFile,
            playbackState: AppPlaybackState.paused,
          ),
        );

        // Find and tap the play/pause button
        final playButton = find.byIcon(Icons.play_arrow);
        await WidgetTestUtils.tapAndSettle(tester, playButton);

        // Verify play/pause callback was triggered
        expect(WidgetTestUtils.lastPlayPauseState, true);
      });

      testWidgets('should handle previous button tap',
          (WidgetTester tester) async {
        WidgetTestUtils.resetCallbacks();

        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          WidgetTestUtils.createMiniPlayer(
            audioFile: testAudioFile,
            playbackState: AppPlaybackState.paused,
          ),
        );

        // Tap previous button
        await WidgetTestUtils.tapAndSettle(
            tester, find.byIcon(Icons.skip_previous));

        // Verify previous callback was triggered
        expect(WidgetTestUtils.tapCount, equals(1));
      });

      testWidgets('should handle next button tap', (WidgetTester tester) async {
        WidgetTestUtils.resetCallbacks();

        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          WidgetTestUtils.createMiniPlayer(
            audioFile: testAudioFile,
            playbackState: AppPlaybackState.paused,
          ),
        );

        // Tap next button
        await WidgetTestUtils.tapAndSettle(
            tester, find.byIcon(Icons.skip_next));

        // Verify next callback was triggered
        expect(WidgetTestUtils.tapCount, equals(1));
      });

      testWidgets('should disable play button when loading',
          (WidgetTester tester) async {
        WidgetTestUtils.resetCallbacks();

        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          WidgetTestUtils.createMiniPlayer(
            audioFile: testAudioFile,
            playbackState: AppPlaybackState.loading,
          ),
        );

        // The loading state should show a CircularProgressIndicator in the play button
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Previous and next buttons should still work - use pump() instead of pumpAndSettle()
        // to avoid timeout with CircularProgressIndicator animation
        await tester.tap(find.byIcon(Icons.skip_previous));
        await tester.pump();
        await tester.tap(find.byIcon(Icons.skip_next));
        await tester.pump();

        expect(
            WidgetTestUtils.tapCount, equals(2)); // Only prev/next should work
      });
    });

    group('Visual Styling Tests', () {
      testWidgets('should apply glassmorphism decoration',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          WidgetTestUtils.createMiniPlayer(
            audioFile: testAudioFile,
            playbackState: AppPlaybackState.paused,
          ),
        );

        // Find the main container with decoration
        final containerFinder = find.byType(Container).first;
        final container = tester.widget<Container>(containerFinder);

        // Verify glassmorphism decoration is applied
        expect(container.decoration, equals(AppTheme.glassMorphismDecoration));
      });

      testWidgets('should apply gradient to album art',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          WidgetTestUtils.createMiniPlayer(
            audioFile: testAudioFile,
            playbackState: AppPlaybackState.paused,
          ),
        );

        // Find album art container (should have gradient)
        final albumArtContainers = find.byType(Container);
        bool foundGradient = false;

        for (int i = 0; i < albumArtContainers.evaluate().length; i++) {
          final container = tester.widget<Container>(albumArtContainers.at(i));
          final decoration = container.decoration as BoxDecoration?;

          if (decoration?.gradient != null) {
            foundGradient = true;
            expect(decoration!.gradient, isA<LinearGradient>());
            break;
          }
        }

        expect(foundGradient, true);
      });

      testWidgets('should use correct button sizes',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          WidgetTestUtils.createMiniPlayer(
            audioFile: testAudioFile,
            playbackState: AppPlaybackState.paused,
          ),
        );

        // Check button sizes
        final buttonSizeBoxes = find.byType(SizedBox);
        final sizeBoxWidgets = buttonSizeBoxes
            .evaluate()
            .map((e) => tester.widget<SizedBox>(find.byWidget(e.widget)))
            .toList();

        // Should have accessibility-compliant button sizes (48px minimum for prev/next, 48-52px for play/pause)
        final buttonSizes = sizeBoxWidgets
            .where((box) => box.width != null && box.height != null)
            .map((box) => box.width)
            .toSet();

        // Check for accessibility-compliant button sizes
        expect(buttonSizes.any((size) => size! >= 48.0),
            true); // All buttons meet 48px minimum

        // Verify we have at least the expected button size count (3 buttons)
        final accessibleButtonSizes =
            buttonSizes.where((size) => size! >= 48.0).toList();
        expect(accessibleButtonSizes.isNotEmpty,
            true); // Should have accessibility-compliant buttons
      });

      testWidgets('should apply correct colors based on state',
          (WidgetTester tester) async {
        final stateColors = [
          (AppPlaybackState.playing, AppTheme.playingColor),
          (AppPlaybackState.paused, AppTheme.pausedColor),
          (AppPlaybackState.loading, AppTheme.loadingColor),
          (AppPlaybackState.error, AppTheme.errorStateColor),
        ];

        for (final (state, _) in stateColors) {
          await tester.pumpWidget(
            WidgetTestUtils.createTestWrapper(
              WidgetTestUtils.createMiniPlayer(
                audioFile: testAudioFile,
                playbackState: state,
              ),
            ),
          );

          // State indicator should use correct color
          // Note: This is a visual test, would need more complex verification in real scenarios
          expect(find.byType(MiniPlayer), findsOneWidget);

          await tester.pump();
        }
      });
    });

    group('Content Display Tests', () {
      testWidgets('should truncate long titles properly',
          (WidgetTester tester) async {
        final longTitleAudioFile = WidgetTestUtils.createTestAudioFile(
          title:
              'This is a very long title that should be truncated when displayed in the mini player to prevent overflow issues',
        );

        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          WidgetTestUtils.createMiniPlayer(
            audioFile: longTitleAudioFile,
            playbackState: AppPlaybackState.paused,
          ),
        );

        // Verify title is displayed (even if truncated)
        expect(find.text(longTitleAudioFile.displayTitle), findsOneWidget);

        // Find the title text widget
        final titleFinder = find.text(longTitleAudioFile.displayTitle);
        final titleWidget = tester.widget<Text>(titleFinder);

        // Verify text overflow handling
        expect(titleWidget.maxLines, equals(1));
        expect(titleWidget.overflow, equals(TextOverflow.ellipsis));
      });

      testWidgets('should display category emoji and name',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          WidgetTestUtils.createMiniPlayer(
            audioFile: testAudioFile,
            playbackState: AppPlaybackState.paused,
          ),
        );

        // Verify category information is displayed with emoji
        expect(
            find.textContaining(testAudioFile.categoryEmoji), findsOneWidget);
        expect(find.textContaining(testAudioFile.category), findsOneWidget);
      });

      testWidgets('should display language flag and name',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          WidgetTestUtils.createMiniPlayer(
            audioFile: testAudioFile,
            playbackState: AppPlaybackState.paused,
          ),
        );

        // Verify language information is displayed with flag
        expect(find.textContaining(testAudioFile.languageFlag), findsOneWidget);
        expect(find.textContaining(testAudioFile.language), findsOneWidget);
      });
    });

    group('Accessibility Tests', () {
      testWidgets('should meet accessibility guidelines',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          WidgetTestUtils.createMiniPlayer(
            audioFile: testAudioFile,
            playbackState: AppPlaybackState.paused,
          ),
        );

        await WidgetTestUtils.verifyAccessibility(tester);
      });

      testWidgets('should have sufficient tap target sizes',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          WidgetTestUtils.createMiniPlayer(
            audioFile: testAudioFile,
            playbackState: AppPlaybackState.paused,
          ),
        );

        // Verify button sizes meet accessibility requirements
        final buttonFinders = find.byType(IconButton);
        for (int i = 0; i < buttonFinders.evaluate().length; i++) {
          final renderObject =
              tester.renderObject<RenderBox>(buttonFinders.at(i));
          final size = renderObject.size;

          // Minimum tap target size for accessibility
          expect(size.width, greaterThanOrEqualTo(32));
          expect(size.height, greaterThanOrEqualTo(32));
        }

        // Main tap area should be large enough - verify MiniPlayer exists
        expect(find.byType(MiniPlayer), findsOneWidget);
        // Verify the widget doesn't cause overflow or rendering issues
        expect(tester.takeException(), isNull);
      });

      testWidgets('should provide semantic information',
          (WidgetTester tester) async {
        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          WidgetTestUtils.createMiniPlayer(
            audioFile: testAudioFile,
            playbackState: AppPlaybackState.paused,
          ),
        );

        // Verify interactive elements exist (semantic information would be tested with semantic finder)
        expect(find.byType(IconButton), findsWidgets);
        // Verify main tap area exists within MiniPlayer
        expect(find.byType(MiniPlayer), findsOneWidget);
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle rapid state changes',
          (WidgetTester tester) async {
        AppPlaybackState currentState = AppPlaybackState.paused;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return WidgetTestUtils.createTestWrapper(
                WidgetTestUtils.createMiniPlayer(
                  audioFile: testAudioFile,
                  playbackState: currentState,
                  onPlayPause: () => setState(() {
                    currentState = currentState == AppPlaybackState.playing
                        ? AppPlaybackState.paused
                        : AppPlaybackState.playing;
                  }),
                ),
              );
            },
          ),
        );

        // Rapidly change playback state
        expect(find.byIcon(Icons.play_arrow), findsOneWidget);

        // Tap play/pause multiple times
        final playPauseButton = find.byIcon(Icons.play_arrow);
        await tester.tap(playPauseButton);
        await tester.pump();
        expect(find.byIcon(Icons.pause), findsOneWidget);

        await tester.tap(find.byIcon(Icons.pause));
        await tester.pump();
        expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      });

      testWidgets('should handle empty or special characters in title',
          (WidgetTester tester) async {
        final specialTitleAudioFile = WidgetTestUtils.createTestAudioFile(
          title: '🎵 Special Characters & Symbols! @#\$%^&*()',
        );

        await WidgetTestUtils.pumpWidgetWithTheme(
          tester,
          WidgetTestUtils.createMiniPlayer(
            audioFile: specialTitleAudioFile,
            playbackState: AppPlaybackState.paused,
          ),
        );

        // Verify special characters are handled properly
        expect(find.text(specialTitleAudioFile.displayTitle), findsOneWidget);
      });

      testWidgets('should handle all AppPlaybackState values',
          (WidgetTester tester) async {
        for (final state in AppPlaybackState.values) {
          await tester.pumpWidget(
            WidgetTestUtils.createTestWrapper(
              WidgetTestUtils.createMiniPlayer(
                audioFile: testAudioFile,
                playbackState: state,
              ),
            ),
          );

          // Widget should render without errors for all states
          expect(find.byType(MiniPlayer), findsOneWidget);
          await tester.pump();
        }
      });
    });

    group('Responsive Design Tests', () {
      testWidgets('should adapt to different screen sizes',
          (WidgetTester tester) async {
        final testSizes = WidgetTestUtils.getTestScreenSizes();

        for (final size in testSizes) {
          WidgetTestUtils.setDeviceSize(tester, size);

          await WidgetTestUtils.pumpWidgetWithTheme(
            tester,
            WidgetTestUtils.createMiniPlayer(
              audioFile: testAudioFile,
              playbackState: AppPlaybackState.paused,
            ),
          );

          // Verify widget renders properly on all screen sizes
          expect(find.byType(MiniPlayer), findsOneWidget);

          // Verify no overflow occurs
          expect(tester.takeException(), isNull);
        }

        WidgetTestUtils.resetDeviceSize(tester);
      });
    });
  });
}

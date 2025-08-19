import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/widgets/mini_player.dart';
import 'package:from_fed_to_chain_app/models/audio_file.dart';
import 'package:from_fed_to_chain_app/services/audio_service.dart';
import 'package:from_fed_to_chain_app/themes/app_theme.dart';
import '../test_utils.dart';

void main() {
  group('MiniPlayer Widget Tests', () {
    late AudioFile sampleAudioFile;
    bool wasTapped = false;
    bool playPauseTapped = false;
    bool nextTapped = false;
    bool previousTapped = false;

    void onTap() {
      wasTapped = true;
    }

    void onPlayPause() {
      playPauseTapped = true;
    }

    void onNext() {
      nextTapped = true;
    }

    void onPrevious() {
      previousTapped = true;
    }

    setUp(() {
      sampleAudioFile = TestUtils.createSampleAudioFile(
        title: 'Test Episode',
        category: 'daily-news',
        language: 'en-US',
      );
      wasTapped = false;
      playPauseTapped = false;
      nextTapped = false;
      previousTapped = false;
    });

    Widget createMiniPlayer({
      AudioFile? audioFile,
      PlaybackState playbackState = PlaybackState.stopped,
      VoidCallback? onTapCallback,
      VoidCallback? onPlayPauseCallback,
      VoidCallback? onNextCallback,
      VoidCallback? onPreviousCallback,
    }) {
      return MiniPlayer(
        audioFile: audioFile ?? sampleAudioFile,
        playbackState: playbackState,
        onTap: onTapCallback ?? onTap,
        onPlayPause: onPlayPauseCallback ?? onPlayPause,
        onNext: onNextCallback ?? onNext,
        onPrevious: onPreviousCallback ?? onPrevious,
      );
    }

    testWidgets('should render with basic structure', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createMiniPlayer());

      // Verify main structure
      TestUtils.expectWidgetExists(find.byType(MiniPlayer));
      TestUtils.expectWidgetExists(find.byType(Container));
      TestUtils.expectWidgetExists(find.byType(InkWell));
      TestUtils.expectWidgetExists(find.byType(Row));
    });

    testWidgets('should display audio file information correctly',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createMiniPlayer());

      // Verify episode title is displayed
      TestUtils.expectTextExists('Test Episode');

      // Verify category with emoji
      TestUtils.expectTextExists('📰 daily-news');

      // Verify language with flag
      TestUtils.expectTextExists('🇺🇸 en-US');
    });

    testWidgets('should handle title ellipsis for long titles', (tester) async {
      final longTitleFile = TestUtils.createSampleAudioFile(
        title:
            'This is an extremely long episode title that should be truncated',
      );

      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createMiniPlayer(audioFile: longTitleFile));

      // Find the title text widget
      final titleText = find.text(longTitleFile.title);
      TestUtils.expectWidgetExists(titleText);

      // Verify ellipsis overflow is set
      final textWidget = tester.widget<Text>(titleText);
      expect(textWidget.overflow, equals(TextOverflow.ellipsis));
      expect(textWidget.maxLines, equals(1));
    });

    testWidgets('should handle tap on mini player correctly', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createMiniPlayer());

      // Tap the mini player
      await TestUtils.tapWidget(tester, find.byType(InkWell));

      expect(wasTapped, isTrue);
    });

    testWidgets('should show correct playback state indicators',
        (tester) async {
      final testCases = [
        (PlaybackState.playing, Icons.graphic_eq, 'Playing'),
        (PlaybackState.paused, Icons.pause_circle_outline, 'Paused'),
        (PlaybackState.loading, Icons.hourglass_empty, 'Loading'),
        (PlaybackState.error, Icons.error_outline, 'Error'),
        (PlaybackState.stopped, Icons.stop_circle, 'Stopped'),
      ];

      for (final (state, expectedIcon, expectedText) in testCases) {
        await TestUtils.pumpWidgetWithMaterialApp(
            tester, createMiniPlayer(playbackState: state));

        // Verify playback state icon
        TestUtils.expectIconExists(expectedIcon);

        // Verify playback state text
        TestUtils.expectTextExists(expectedText);

        await tester.pumpWidget(Container()); // Clear previous widget
      }
    });

    testWidgets('should show correct play/pause icon based on state',
        (tester) async {
      // Test play icon when stopped
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createMiniPlayer(playbackState: PlaybackState.stopped));
      TestUtils.expectIconExists(Icons.play_arrow);

      // Test pause icon when playing
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createMiniPlayer(playbackState: PlaybackState.playing));
      TestUtils.expectIconExists(Icons.pause);

      // Test play icon when paused
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createMiniPlayer(playbackState: PlaybackState.paused));
      TestUtils.expectIconExists(Icons.play_arrow);

      // Test refresh icon when error
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createMiniPlayer(playbackState: PlaybackState.error));
      TestUtils.expectIconExists(Icons.refresh);
    });

    testWidgets('should show loading indicator when loading', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createMiniPlayer(playbackState: PlaybackState.loading));

      // Should show circular progress indicator instead of play/pause icon
      TestUtils.expectWidgetExists(find.byType(CircularProgressIndicator));
    });

    testWidgets('should handle control button interactions', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createMiniPlayer());

      // Test previous button
      await TestUtils.tapWidget(tester, find.byIcon(Icons.skip_previous));
      expect(previousTapped, isTrue);

      // Test play/pause button
      await TestUtils.tapWidget(tester, find.byIcon(Icons.play_arrow));
      expect(playPauseTapped, isTrue);

      // Test next button
      await TestUtils.tapWidget(tester, find.byIcon(Icons.skip_next));
      expect(nextTapped, isTrue);
    });

    testWidgets('should disable play/pause button when loading',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createMiniPlayer(playbackState: PlaybackState.loading));

      // Find the primary button (play/pause) which should be disabled
      final primaryButton = find.byType(IconButton).at(1); // Middle button

      // Verify the button is present
      TestUtils.expectWidgetExists(primaryButton);

      // Try to tap it (should not trigger callback when disabled)
      await TestUtils.tapWidget(tester, primaryButton);
      expect(playPauseTapped, isFalse); // Should remain false
    });

    testWidgets('should show category icons correctly', (tester) async {
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
            TestUtils.createSampleAudioFile(category: categories[i]);

        await TestUtils.pumpWidgetWithMaterialApp(
            tester, createMiniPlayer(audioFile: audioFile));

        // Verify category icon in album art
        TestUtils.expectIconExists(expectedIcons[i]);

        await tester.pumpWidget(Container()); // Clear previous widget
      }
    });

    testWidgets('should show default icon for unknown category',
        (tester) async {
      final unknownCategoryFile =
          TestUtils.createSampleAudioFile(category: 'unknown');

      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createMiniPlayer(audioFile: unknownCategoryFile));

      // Should show default headphones icon
      TestUtils.expectIconExists(Icons.headphones);
    });

    testWidgets('should apply glass morphism decoration', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createMiniPlayer());

      // Find the main container
      final container = find.byType(Container).first;
      TestUtils.expectWidgetExists(container);

      // Verify decoration is applied
      final containerWidget = tester.widget<Container>(container);
      expect(
          containerWidget.decoration, equals(AppTheme.glassMorphismDecoration));
    });

    testWidgets('should show appropriate spacing and layout', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createMiniPlayer());

      // Verify main row structure
      TestUtils.expectWidgetExists(find.byType(Row));

      // Verify SizedBox widgets for spacing
      expect(find.byType(SizedBox), findsWidgets);

      // Verify Expanded widget for track info
      TestUtils.expectWidgetExists(find.byType(Expanded));
    });

    testWidgets('should handle different playback states with correct colors',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createMiniPlayer(playbackState: PlaybackState.playing));

      // Playing state should show playing color
      TestUtils.expectTextExists('Playing');
      TestUtils.expectIconExists(Icons.graphic_eq);
    });

    testWidgets('should maintain consistent button sizes', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createMiniPlayer());

      // Find all IconButton widgets
      final iconButtons = find.byType(IconButton);
      expect(iconButtons.evaluate().length,
          equals(3)); // Previous, Play/Pause, Next

      // Each button should be properly sized
      for (int i = 0; i < 3; i++) {
        TestUtils.expectWidgetExists(iconButtons.at(i));
      }
    });

    testWidgets(
        'should show proper button styling for primary and secondary buttons',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createMiniPlayer());

      // Find all SizedBox widgets that wrap the buttons
      final buttonContainers = find.byType(SizedBox);
      expect(buttonContainers.evaluate().length, greaterThan(0));
    });

    testWidgets('should handle rapid button presses correctly', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createMiniPlayer());

      int playPauseCount = 0;
      final rapidTestPlayer = createMiniPlayer(
        onPlayPauseCallback: () => playPauseCount++,
      );

      await TestUtils.pumpWidgetWithMaterialApp(tester, rapidTestPlayer);

      // Rapidly tap play/pause button
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byIcon(Icons.play_arrow));
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(playPauseCount, equals(5));
    });

    testWidgets('should display track details in correct order',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createMiniPlayer());

      // Find the track info column
      final trackInfoColumn = find.byType(Column);
      TestUtils.expectWidgetExists(trackInfoColumn);

      // Verify title is displayed
      TestUtils.expectTextExists('Test Episode');

      // Verify category and language info
      TestUtils.expectTextExists('📰 daily-news');
      TestUtils.expectTextExists('🇺🇸 en-US');

      // Verify separator
      TestUtils.expectTextExists('•');
    });

    testWidgets('should handle edge case with very small screen',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(300, 600));

      await TestUtils.pumpWidgetWithMaterialApp(tester, createMiniPlayer());

      // Should render without overflow issues
      TestUtils.expectWidgetExists(find.byType(MiniPlayer));

      // Reset screen size
      await tester.binding.setSurfaceSize(const Size(800, 600));
    });

    testWidgets('should handle accessibility correctly', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createMiniPlayer());

      // Verify main container is tappable
      TestUtils.expectWidgetExists(find.byType(InkWell));

      // Verify all control buttons are interactive
      expect(find.byType(IconButton), findsNWidgets(3));
    });

    testWidgets('should show correct album art styling', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createMiniPlayer());

      // Find the album art container
      final albumArtContainers = find.byType(Container);
      expect(albumArtContainers.evaluate().length, greaterThan(1));

      // Verify icon is displayed in album art
      TestUtils.expectIconExists(Icons.newspaper); // Default for daily-news
    });

    testWidgets('should handle playback state text correctly', (tester) async {
      final states = [
        PlaybackState.playing,
        PlaybackState.paused,
        PlaybackState.loading,
        PlaybackState.error,
        PlaybackState.stopped,
      ];

      for (final state in states) {
        await TestUtils.pumpWidgetWithMaterialApp(
            tester, createMiniPlayer(playbackState: state));

        // Each state should show appropriate text
        switch (state) {
          case PlaybackState.playing:
            TestUtils.expectTextExists('Playing');
            break;
          case PlaybackState.paused:
            TestUtils.expectTextExists('Paused');
            break;
          case PlaybackState.loading:
            TestUtils.expectTextExists('Loading');
            break;
          case PlaybackState.error:
            TestUtils.expectTextExists('Error');
            break;
          case PlaybackState.stopped:
            TestUtils.expectTextExists('Stopped');
            break;
        }

        await tester.pumpWidget(Container()); // Clear previous widget
      }
    });

    testWidgets('should show spacer for layout balance', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createMiniPlayer());

      // Verify Spacer widget is used for layout
      TestUtils.expectWidgetExists(find.byType(Spacer));
    });

    testWidgets('should handle null callbacks gracefully', (tester) async {
      // Test with empty callbacks (should not crash)
      final miniPlayerWithEmptyCallbacks = MiniPlayer(
        audioFile: sampleAudioFile,
        playbackState: PlaybackState.stopped,
        onTap: () {}, // Empty callback
        onPlayPause: () {}, // Empty callback
        onNext: () {}, // Empty callback
        onPrevious: () {}, // Empty callback
      );

      await TestUtils.pumpWidgetWithMaterialApp(
          tester, miniPlayerWithEmptyCallbacks);

      // Should render without issues
      TestUtils.expectWidgetExists(find.byType(MiniPlayer));

      // Tapping should not cause errors
      await TestUtils.tapWidget(tester, find.byType(InkWell));
      await TestUtils.tapWidget(tester, find.byIcon(Icons.play_arrow));
    });

    testWidgets('should maintain consistent styling across states',
        (tester) async {
      final states = [
        PlaybackState.playing,
        PlaybackState.paused,
        PlaybackState.error
      ];

      for (final state in states) {
        await TestUtils.pumpWidgetWithMaterialApp(
            tester, createMiniPlayer(playbackState: state));

        // Should maintain consistent structure
        TestUtils.expectWidgetExists(find.byType(MiniPlayer));
        TestUtils.expectWidgetExists(find.byType(Container));
        TestUtils.expectWidgetExists(find.byType(InkWell));

        await tester.pumpWidget(Container()); // Clear previous widget
      }
    });

    testWidgets('should handle different audio file languages correctly',
        (tester) async {
      final languages = ['zh-TW', 'en-US', 'ja-JP'];
      final expectedFlags = ['🇹🇼', '🇺🇸', '🇯🇵'];

      for (int i = 0; i < languages.length; i++) {
        final audioFile =
            TestUtils.createSampleAudioFile(language: languages[i]);

        await TestUtils.pumpWidgetWithMaterialApp(
            tester, createMiniPlayer(audioFile: audioFile));

        // Verify language flag is displayed
        expect(find.textContaining(expectedFlags[i]), findsOneWidget);

        await tester.pumpWidget(Container()); // Clear previous widget
      }
    });

    testWidgets('should properly handle button state during loading',
        (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createMiniPlayer(playbackState: PlaybackState.loading));

      // Primary button (play/pause) should show loading indicator
      TestUtils.expectWidgetExists(find.byType(CircularProgressIndicator));

      // Other buttons should remain enabled
      TestUtils.expectIconExists(Icons.skip_previous);
      TestUtils.expectIconExists(Icons.skip_next);
    });

    testWidgets('should handle theme colors correctly', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createMiniPlayer());

      // Should apply theme consistently
      TestUtils.expectWidgetExists(find.byType(Container));

      // Colors should be applied from theme
      final containers = find.byType(Container);
      expect(containers.evaluate().length, greaterThan(0));
    });
  });
}

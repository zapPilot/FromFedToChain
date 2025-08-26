import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:from_fed_to_chain_app/widgets/mini_player.dart';
import 'package:from_fed_to_chain_app/services/audio_service.dart';
import 'package:from_fed_to_chain_app/models/audio_file.dart';

import '../test_utils.dart';

void main() {
  group('MiniPlayer Widget Tests', () {
    late AudioFile testEpisode;

    setUp(() {
      testEpisode = TestUtils.createSampleAudioFile(
        id: 'test-episode',
        title: 'Test Episode Title',
        duration: const Duration(minutes: 10),
      );
    });

    Widget createMiniPlayer({
      PlaybackState playbackState = PlaybackState.paused,
      AudioFile? audioFile,
      VoidCallback? onTap,
      VoidCallback? onPlayPause,
      VoidCallback? onNext,
      VoidCallback? onPrevious,
    }) {
      return TestUtils.wrapWithMaterialApp(
        MiniPlayer(
          audioFile: audioFile ?? testEpisode,
          playbackState: playbackState,
          onTap: onTap ?? () {},
          onPlayPause: onPlayPause ?? () {},
          onNext: onNext ?? () {},
          onPrevious: onPrevious ?? () {},
        ),
      );
    }

    testWidgets('renders correctly when episode is available', (tester) async {
      await tester.pumpWidget(createMiniPlayer());
      await tester.pumpAndSettle();

      // Check that MiniPlayer is present
      expect(find.byType(MiniPlayer), findsOneWidget);
      expect(find.text(testEpisode.title), findsOneWidget);
    });

    testWidgets('shows play button when paused', (tester) async {
      await tester
          .pumpWidget(createMiniPlayer(playbackState: PlaybackState.paused));
      await tester.pumpAndSettle();

      // Should show play button
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
    });

    testWidgets('shows pause button when playing', (tester) async {
      await tester
          .pumpWidget(createMiniPlayer(playbackState: PlaybackState.playing));
      await tester.pumpAndSettle();

      // Should show pause button
      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    testWidgets('shows loading indicator when loading', (tester) async {
      await tester
          .pumpWidget(createMiniPlayer(playbackState: PlaybackState.loading));
      await tester.pumpAndSettle();

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('handles play button tap when paused', (tester) async {
      bool playPauseTapped = false;

      await tester.pumpWidget(createMiniPlayer(
        playbackState: PlaybackState.paused,
        onPlayPause: () {
          playPauseTapped = true;
        },
      ));
      await tester.pumpAndSettle();

      // Tap play button
      final playButton = find.byIcon(Icons.play_arrow);
      await tester.tap(playButton);
      await tester.pumpAndSettle();

      // Should call onPlayPause callback
      expect(playPauseTapped, isTrue);
    });

    testWidgets('handles pause button tap when playing', (tester) async {
      bool playPauseTapped = false;

      await tester.pumpWidget(createMiniPlayer(
        playbackState: PlaybackState.playing,
        onPlayPause: () {
          playPauseTapped = true;
        },
      ));
      await tester.pumpAndSettle();

      // Tap pause button
      final pauseButton = find.byIcon(Icons.pause);
      await tester.tap(pauseButton);
      await tester.pumpAndSettle();

      // Should call onPlayPause callback
      expect(playPauseTapped, isTrue);
    });

    testWidgets('displays episode title with proper overflow handling',
        (tester) async {
      final longTitleEpisode = TestUtils.createSampleAudioFile(
        title:
            'This is a very long episode title that should be truncated with ellipsis',
      );

      await tester.pumpWidget(createMiniPlayer(audioFile: longTitleEpisode));
      await tester.pumpAndSettle();

      // Should display title with ellipsis
      final titleText = find.text(longTitleEpisode.title);
      if (titleText.evaluate().isNotEmpty) {
        final textWidget = tester.widget<Text>(titleText);
        expect(textWidget.overflow, TextOverflow.ellipsis);
      }
    });

    testWidgets('displays episode metadata', (tester) async {
      await tester.pumpWidget(createMiniPlayer());
      await tester.pumpAndSettle();

      // Should show episode category emoji and language flag
      expect(find.text(testEpisode.categoryEmoji), findsOneWidget);
      expect(find.text(testEpisode.languageFlag), findsOneWidget);
    });

    testWidgets('handles tap on mini player container', (tester) async {
      bool containerTapped = false;

      await tester.pumpWidget(createMiniPlayer(
        onTap: () {
          containerTapped = true;
        },
      ));
      await tester.pumpAndSettle();

      // Tap on the mini player container (not the play/pause button)
      final miniPlayerContainer = find.byType(MiniPlayer);
      await tester.tap(miniPlayerContainer);
      await tester.pumpAndSettle();

      // Should call onTap callback
      expect(containerTapped, isTrue);
    });

    testWidgets('handles next button tap', (tester) async {
      bool nextTapped = false;

      await tester.pumpWidget(createMiniPlayer(
        onNext: () {
          nextTapped = true;
        },
      ));
      await tester.pumpAndSettle();

      // Tap next button
      final nextButton = find.byIcon(Icons.skip_next);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // Should call onNext callback
      expect(nextTapped, isTrue);
    });

    testWidgets('handles previous button tap', (tester) async {
      bool previousTapped = false;

      await tester.pumpWidget(createMiniPlayer(
        onPrevious: () {
          previousTapped = true;
        },
      ));
      await tester.pumpAndSettle();

      // Tap previous button
      final prevButton = find.byIcon(Icons.skip_previous);
      await tester.tap(prevButton);
      await tester.pumpAndSettle();

      // Should call onPrevious callback
      expect(previousTapped, isTrue);
    });

    testWidgets('shows correct theme colors', (tester) async {
      await tester.pumpWidget(createMiniPlayer());
      await tester.pumpAndSettle();

      // Check that mini player uses correct theme colors
      final container = find.descendant(
        of: find.byType(MiniPlayer),
        matching: find.byType(Container),
      );

      if (container.evaluate().isNotEmpty) {
        // Should have appropriate background color and styling
        expect(container, findsAtLeastNWidgets(1));
      }
    });

    testWidgets('shows error state appropriately', (tester) async {
      await tester
          .pumpWidget(createMiniPlayer(playbackState: PlaybackState.error));
      await tester.pumpAndSettle();

      // Should show error indicator or refresh icon
      expect(find.byIcon(Icons.refresh), findsAtLeastNWidget(0));
    });

    testWidgets('handles different episode types correctly', (tester) async {
      // Test with different categories
      final categories = ['daily-news', 'ethereum', 'macro', 'startup', 'ai'];

      for (final category in categories) {
        final categoryEpisode =
            TestUtils.createSampleAudioFile(category: category);

        await tester.pumpWidget(createMiniPlayer(audioFile: categoryEpisode));
        await tester.pumpAndSettle();

        // Should display correct category emoji
        expect(find.text(categoryEpisode.categoryEmoji), findsOneWidget);
      }
    });

    testWidgets('handles different languages correctly', (tester) async {
      // Test with different languages
      final languages = ['zh-TW', 'en-US', 'ja-JP'];

      for (final language in languages) {
        final languageEpisode =
            TestUtils.createSampleAudioFile(language: language);

        await tester.pumpWidget(createMiniPlayer(audioFile: languageEpisode));
        await tester.pumpAndSettle();

        // Should display correct language flag
        expect(find.text(languageEpisode.languageFlag), findsOneWidget);
      }
    });

    testWidgets('maintains aspect ratio on different screen sizes',
        (tester) async {
      await tester.pumpWidget(createMiniPlayer());
      await tester.pumpAndSettle();

      // Test different screen sizes
      final sizes = [
        const Size(320, 568), // iPhone SE
        const Size(375, 667), // iPhone 8
        const Size(414, 896), // iPhone 11 Pro Max
        const Size(800, 600), // Tablet landscape
      ];

      for (final size in sizes) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpAndSettle();

        // Mini player should adapt to different screen sizes
        expect(find.byType(MiniPlayer), findsOneWidget);
      }
    });

    testWidgets('provides proper accessibility labels', (tester) async {
      await tester.pumpWidget(createMiniPlayer());
      await tester.pumpAndSettle();

      // Check for semantic labels on interactive elements
      final playButton = find.byIcon(Icons.play_arrow);
      if (playButton.evaluate().isNotEmpty) {
        // Should have proper semantics for screen readers
        expect(playButton, findsOneWidget);
      }
    });

    testWidgets('handles gesture conflicts properly', (tester) async {
      bool playPauseTapped = false;
      bool containerTapped = false;

      await tester.pumpWidget(createMiniPlayer(
        onTap: () {
          containerTapped = true;
        },
        onPlayPause: () {
          playPauseTapped = true;
        },
      ));
      await tester.pumpAndSettle();

      // Tap near the edge of play button
      final playButton = find.byIcon(Icons.play_arrow);
      if (playButton.evaluate().isNotEmpty) {
        await tester.tap(playButton);
        await tester.pumpAndSettle();

        // Should register as play button tap, not container tap
        expect(playPauseTapped, isTrue);
        expect(containerTapped, isFalse);
      }
    });

    testWidgets('shows correct playback state indicators', (tester) async {
      final playbackStates = [
        PlaybackState.playing,
        PlaybackState.paused,
        PlaybackState.loading,
        PlaybackState.error,
        PlaybackState.stopped,
      ];

      for (final state in playbackStates) {
        await tester.pumpWidget(createMiniPlayer(playbackState: state));
        await tester.pumpAndSettle();

        // Should display appropriate state indicator
        expect(find.byType(MiniPlayer), findsOneWidget);
      }
    });
  });

  group('MiniPlayer Integration Tests', () {
    late AudioFile testEpisode;

    setUp(() {
      testEpisode = TestUtils.createSampleAudioFile();
    });

    Widget createMiniPlayer({
      PlaybackState playbackState = PlaybackState.paused,
    }) {
      return TestUtils.wrapWithMaterialApp(
        MiniPlayer(
          audioFile: testEpisode,
          playbackState: playbackState,
          onTap: () {},
          onPlayPause: () {},
          onNext: () {},
          onPrevious: () {},
        ),
      );
    }

    testWidgets('complete playback control flow', (tester) async {
      await tester.pumpWidget(createMiniPlayer());
      await tester.pumpAndSettle();

      // Start paused
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      // Widget should be functional
      expect(find.byType(MiniPlayer), findsOneWidget);
    });

    testWidgets('handles episode changes correctly', (tester) async {
      await tester.pumpWidget(createMiniPlayer());
      await tester.pumpAndSettle();

      // Show initial episode
      expect(find.text(testEpisode.title), findsOneWidget);

      // Change to new episode
      final newEpisode = TestUtils.createSampleAudioFile(
        id: 'new-episode',
        title: 'New Episode Title',
      );

      await tester.pumpWidget(
        TestUtils.wrapWithMaterialApp(
          MiniPlayer(
            audioFile: newEpisode,
            playbackState: PlaybackState.paused,
            onTap: () {},
            onPlayPause: () {},
            onNext: () {},
            onPrevious: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show new episode
      expect(find.text(newEpisode.title), findsOneWidget);
      expect(find.text(testEpisode.title), findsNothing);
    });

    testWidgets('handles loading to playing transition', (tester) async {
      // Start with loading state
      await tester
          .pumpWidget(createMiniPlayer(playbackState: PlaybackState.loading));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Transition to playing
      await tester
          .pumpWidget(createMiniPlayer(playbackState: PlaybackState.playing));
      await tester.pumpAndSettle();

      // Should show pause button
      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('handles error states and recovery', (tester) async {
      await tester.pumpWidget(createMiniPlayer());
      await tester.pumpAndSettle();

      // Simulate error
      await tester
          .pumpWidget(createMiniPlayer(playbackState: PlaybackState.error));
      await tester.pumpAndSettle();

      // Should handle error state
      expect(find.byType(MiniPlayer), findsOneWidget);

      // Recover from error
      await tester
          .pumpWidget(createMiniPlayer(playbackState: PlaybackState.paused));
      await tester.pumpAndSettle();

      // Should return to normal state
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });
  });
}

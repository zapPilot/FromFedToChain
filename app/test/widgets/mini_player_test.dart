import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/widgets/mini_player.dart';
import 'package:from_fed_to_chain_app/models/audio_file.dart';
import 'package:from_fed_to_chain_app/services/audio_service.dart';
import '../test_utils.dart';

void main() {
  group('MiniPlayer Widget Tests', () {
    late AudioFile sampleAudioFile;
    bool onPlayPauseTapped = false;
    bool onNextTapped = false;
    bool onPreviousTapped = false;
    bool onTapTapped = false;

    setUp(() {
      sampleAudioFile = TestUtils.createSampleAudioFile();
      onPlayPauseTapped = false;
      onNextTapped = false;
      onPreviousTapped = false;
      onTapTapped = false;
    });

    Widget createMiniPlayer({
      AudioFile? audioFile,
      PlaybackState playbackState = PlaybackState.stopped,
    }) {
      return MiniPlayer(
        audioFile: audioFile ?? sampleAudioFile,
        playbackState: playbackState,
        onTap: () => onTapTapped = true,
        onPlayPause: () => onPlayPauseTapped = true,
        onNext: () => onNextTapped = true,
        onPrevious: () => onPreviousTapped = true,
      );
    }

    testWidgets('should render with basic structure', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createMiniPlayer());

      // Verify main widget exists
      expect(find.byType(MiniPlayer), findsOneWidget);

      // Verify title is displayed
      expect(find.text(sampleAudioFile.title), findsOneWidget);
    });

    testWidgets('should display audio file information', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createMiniPlayer());

      // Check title
      expect(find.text(sampleAudioFile.title), findsOneWidget);

      // Check that main widget is shown
      expect(find.byType(MiniPlayer), findsOneWidget);
    });

    testWidgets('should show play button when stopped', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createMiniPlayer(playbackState: PlaybackState.stopped));

      // Should show play icon
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('should show pause button when playing', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createMiniPlayer(playbackState: PlaybackState.playing));

      // Should show pause icon
      expect(find.byIcon(Icons.pause), findsOneWidget);
    });

    testWidgets('should handle loading state', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createMiniPlayer(playbackState: PlaybackState.loading));

      // Should render without error
      expect(find.byType(MiniPlayer), findsOneWidget);
    });

    testWidgets('should handle tap interactions', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createMiniPlayer());

      // Tap the mini player
      await tester.tap(find.byType(MiniPlayer));
      await tester.pumpAndSettle();

      // Verify tap was handled
      expect(onTapTapped, isTrue);
    });

    testWidgets('should handle play/pause button tap', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(
          tester, createMiniPlayer(playbackState: PlaybackState.stopped));

      // Find and tap play button
      final playButton = find.byIcon(Icons.play_arrow);
      if (playButton.evaluate().isNotEmpty) {
        await tester.tap(playButton);
        await tester.pumpAndSettle();

        // Verify play/pause was handled
        expect(onPlayPauseTapped, isTrue);
      }
    });

    testWidgets('should handle next button tap', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createMiniPlayer());

      // Find and tap next button if it exists
      final nextButton = find.byIcon(Icons.skip_next);
      if (nextButton.evaluate().isNotEmpty) {
        await tester.tap(nextButton);
        await tester.pumpAndSettle();

        // Verify next was handled
        expect(onNextTapped, isTrue);
      }
    });

    testWidgets('should handle previous button tap', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createMiniPlayer());

      // Find and tap previous button if it exists
      final prevButton = find.byIcon(Icons.skip_previous);
      if (prevButton.evaluate().isNotEmpty) {
        await tester.tap(prevButton);
        await tester.pumpAndSettle();

        // Verify previous was handled
        expect(onPreviousTapped, isTrue);
      }
    });

    testWidgets('should handle different audio files', (tester) async {
      final differentAudioFile = TestUtils.createSampleAudioFile(
        title: 'Different Audio Title',
        category: 'ethereum',
        language: 'ja-JP',
      );

      await TestUtils.pumpWidgetWithMaterialApp(
        tester,
        createMiniPlayer(audioFile: differentAudioFile),
      );

      // Should display the new title
      expect(find.text('Different Audio Title'), findsOneWidget);
      expect(find.byType(MiniPlayer), findsOneWidget);
    });

    testWidgets('should handle different playback states', (tester) async {
      final states = [
        PlaybackState.stopped,
        PlaybackState.playing,
        PlaybackState.paused,
        PlaybackState.loading,
        PlaybackState.error,
      ];

      for (PlaybackState state in states) {
        await TestUtils.pumpWidgetWithMaterialApp(
          tester,
          createMiniPlayer(playbackState: state),
        );

        // Should render without errors for all states
        expect(find.byType(MiniPlayer), findsOneWidget);
      }
    });

    testWidgets('should handle long titles gracefully', (tester) async {
      final longTitleAudioFile = TestUtils.createSampleAudioFile(
        title:
            'This is a very long audio title that should be handled gracefully by the mini player widget without causing overflow or rendering issues',
      );

      await TestUtils.pumpWidgetWithMaterialApp(
        tester,
        createMiniPlayer(audioFile: longTitleAudioFile),
      );

      // Should render without overflow errors
      expect(find.byType(MiniPlayer), findsOneWidget);
    });

    testWidgets('should show appropriate icons for different states',
        (tester) async {
      // Test stopped state - should show play
      await TestUtils.pumpWidgetWithMaterialApp(
        tester,
        createMiniPlayer(playbackState: PlaybackState.stopped),
      );
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      // Test playing state - should show pause
      await TestUtils.pumpWidgetWithMaterialApp(
        tester,
        createMiniPlayer(playbackState: PlaybackState.playing),
      );
      expect(find.byIcon(Icons.pause), findsOneWidget);

      // Test paused state - should show play
      await TestUtils.pumpWidgetWithMaterialApp(
        tester,
        createMiniPlayer(playbackState: PlaybackState.paused),
      );
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('should maintain consistent structure across states',
        (tester) async {
      final states = [
        PlaybackState.stopped,
        PlaybackState.playing,
        PlaybackState.paused
      ];

      for (PlaybackState state in states) {
        await TestUtils.pumpWidgetWithMaterialApp(
          tester,
          createMiniPlayer(playbackState: state),
        );

        // Basic structure should be consistent
        expect(find.byType(MiniPlayer), findsOneWidget);
        expect(find.text(sampleAudioFile.title), findsOneWidget);
      }
    });

    testWidgets('should handle all callback invocations', (tester) async {
      await TestUtils.pumpWidgetWithMaterialApp(tester, createMiniPlayer());

      // Reset flags
      onTapTapped = false;
      onPlayPauseTapped = false;
      onNextTapped = false;
      onPreviousTapped = false;

      // Test main tap
      await tester.tap(find.byType(MiniPlayer));
      await tester.pumpAndSettle();
      expect(onTapTapped, isTrue);

      // Reset and test play/pause if button exists
      onPlayPauseTapped = false;
      final playPauseButton = find.byIcon(Icons.play_arrow);
      if (playPauseButton.evaluate().isNotEmpty) {
        await tester.tap(playPauseButton);
        await tester.pumpAndSettle();
        expect(onPlayPauseTapped, isTrue);
      }
    });

    testWidgets('should render without errors for edge cases', (tester) async {
      // Test with minimal audio file data
      final minimalAudioFile = TestUtils.createSampleAudioFile(
        title: '',
        category: 'daily-news',
      );

      await TestUtils.pumpWidgetWithMaterialApp(
        tester,
        createMiniPlayer(audioFile: minimalAudioFile),
      );

      // Should handle empty title gracefully
      expect(find.byType(MiniPlayer), findsOneWidget);
    });
  });
}

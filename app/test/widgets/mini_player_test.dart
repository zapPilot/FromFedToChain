import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:from_fed_to_chain_app/widgets/mini_player.dart';
import 'package:from_fed_to_chain_app/models/audio_file.dart';
import 'package:from_fed_to_chain_app/services/audio_service.dart';
import '../test_utils.dart';
import '../helpers/widget_test_helpers.dart';

void main() {
  group('MiniPlayer Widget Tests', () {
    late AudioFile testAudioFile;
    late VoidCallback mockOnTap;
    late VoidCallback mockOnPlayPause;
    late VoidCallback mockOnNext;
    late VoidCallback mockOnPrevious;

    setUp(() {
      testAudioFile = TestUtils.createSampleAudioFile(
        id: 'test-episode',
        title: 'Bitcoin Market Analysis',
        category: 'daily-news',
        language: 'en-US',
      );

      mockOnTap = () {};
      mockOnPlayPause = () {};
      mockOnNext = () {};
      mockOnPrevious = () {};
    });

    testWidgets('displays audio file information correctly', (tester) async {
      await tester.pumpWidget(
        WidgetTestHelpers.createMinimalTestWrapper(
          child: MiniPlayer(
            audioFile: testAudioFile,
            playbackState: PlaybackState.paused,
            onTap: mockOnTap,
            onPlayPause: mockOnPlayPause,
            onNext: mockOnNext,
            onPrevious: mockOnPrevious,
          ),
        ),
      );

      // Verify audio file information is displayed
      expect(find.text(testAudioFile.displayTitle), findsOneWidget);
      expect(find.text('📰 daily-news'), findsOneWidget);
      expect(find.text('🇺🇸 en-US'), findsOneWidget);
    });

    testWidgets('displays correct playback state - playing', (tester) async {
      await tester.pumpWidget(
        WidgetTestHelpers.createMinimalTestWrapper(
          child: MiniPlayer(
            audioFile: testAudioFile,
            playbackState: PlaybackState.playing,
            onTap: mockOnTap,
            onPlayPause: mockOnPlayPause,
            onNext: mockOnNext,
            onPrevious: mockOnPrevious,
          ),
        ),
      );

      // Verify playing state indicators
      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.graphic_eq), findsOneWidget);
      expect(find.text('Playing'), findsOneWidget);
    });

    testWidgets('displays correct playback state - paused', (tester) async {
      await tester.pumpWidget(
        WidgetTestHelpers.createMinimalTestWrapper(
          child: MiniPlayer(
            audioFile: testAudioFile,
            playbackState: PlaybackState.paused,
            onTap: mockOnTap,
            onPlayPause: mockOnPlayPause,
            onNext: mockOnNext,
            onPrevious: mockOnPrevious,
          ),
        ),
      );

      // Verify paused state indicators
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause_circle_outline), findsOneWidget);
      expect(find.text('Paused'), findsOneWidget);
    });

    testWidgets('displays correct playback state - loading', (tester) async {
      await tester.pumpWidget(
        WidgetTestHelpers.createMinimalTestWrapper(
          child: MiniPlayer(
            audioFile: testAudioFile,
            playbackState: PlaybackState.loading,
            onTap: mockOnTap,
            onPlayPause: mockOnPlayPause,
            onNext: mockOnNext,
            onPrevious: mockOnPrevious,
          ),
        ),
      );

      // Verify loading state indicators
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
      expect(find.text('Loading'), findsOneWidget);
    });

    testWidgets('displays correct playback state - error', (tester) async {
      await tester.pumpWidget(
        WidgetTestHelpers.createMinimalTestWrapper(
          child: MiniPlayer(
            audioFile: testAudioFile,
            playbackState: PlaybackState.error,
            onTap: mockOnTap,
            onPlayPause: mockOnPlayPause,
            onNext: mockOnNext,
            onPrevious: mockOnPrevious,
          ),
        ),
      );

      // Verify error state indicators
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Error'), findsOneWidget);
    });

    testWidgets('handles tap gesture correctly', (tester) async {
      bool onTapCalled = false;
      
      await tester.pumpWidget(
        WidgetTestHelpers.createMinimalTestWrapper(
          child: MiniPlayer(
            audioFile: testAudioFile,
            playbackState: PlaybackState.paused,
            onTap: () => onTapCalled = true,
            onPlayPause: mockOnPlayPause,
            onNext: mockOnNext,
            onPrevious: mockOnPrevious,
          ),
        ),
      );

      // Tap on the mini player (not on control buttons)
      await tester.tap(find.text(testAudioFile.displayTitle));
      await tester.pumpAndSettle();

      // Verify callback was called
      expect(onTapCalled, isTrue);
    });

    testWidgets('handles play/pause button correctly', (tester) async {
      bool onPlayPauseCalled = false;
      
      await tester.pumpWidget(
        WidgetTestHelpers.createMinimalTestWrapper(
          child: MiniPlayer(
            audioFile: testAudioFile,
            playbackState: PlaybackState.paused,
            onTap: mockOnTap,
            onPlayPause: () => onPlayPauseCalled = true,
            onNext: mockOnNext,
            onPrevious: mockOnPrevious,
          ),
        ),
      );

      // Tap on play/pause button
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();

      // Verify callback was called
      expect(onPlayPauseCalled, isTrue);
    });

    testWidgets('handles next button correctly', (tester) async {
      bool onNextCalled = false;
      
      await tester.pumpWidget(
        WidgetTestHelpers.createMinimalTestWrapper(
          child: MiniPlayer(
            audioFile: testAudioFile,
            playbackState: PlaybackState.playing,
            onTap: mockOnTap,
            onPlayPause: mockOnPlayPause,
            onNext: () => onNextCalled = true,
            onPrevious: mockOnPrevious,
          ),
        ),
      );

      // Tap on next button
      await tester.tap(find.byIcon(Icons.skip_next));
      await tester.pumpAndSettle();

      // Verify callback was called
      expect(onNextCalled, isTrue);
    });

    testWidgets('handles previous button correctly', (tester) async {
      bool onPreviousCalled = false;
      
      await tester.pumpWidget(
        WidgetTestHelpers.createMinimalTestWrapper(
          child: MiniPlayer(
            audioFile: testAudioFile,
            playbackState: PlaybackState.playing,
            onTap: mockOnTap,
            onPlayPause: mockOnPlayPause,
            onNext: mockOnNext,
            onPrevious: () => onPreviousCalled = true,
          ),
        ),
      );

      // Tap on previous button
      await tester.tap(find.byIcon(Icons.skip_previous));
      await tester.pumpAndSettle();

      // Verify callback was called
      expect(onPreviousCalled, isTrue);
    });

    testWidgets('disables play/pause button when loading', (tester) async {
      bool onPlayPauseCalled = false;
      
      await tester.pumpWidget(
        WidgetTestHelpers.createMinimalTestWrapper(
          child: MiniPlayer(
            audioFile: testAudioFile,
            playbackState: PlaybackState.loading,
            onTap: mockOnTap,
            onPlayPause: () => onPlayPauseCalled = true,
            onNext: mockOnNext,
            onPrevious: mockOnPrevious,
          ),
        ),
      );

      // Try to tap on play/pause button (should be disabled)
      await tester.tap(find.byType(CircularProgressIndicator));
      await tester.pumpAndSettle();

      // Verify callback was not called
      expect(onPlayPauseCalled, isFalse);
    });

    testWidgets('displays different category icons correctly', (tester) async {
      final categories = [
        ('daily-news', Icons.newspaper),
        ('ethereum', Icons.currency_bitcoin),
        ('macro', Icons.trending_up),
        ('startup', Icons.rocket_launch),
        ('ai', Icons.smart_toy),
        ('defi', Icons.account_balance),
        ('unknown', Icons.headphones),
      ];

      for (final (category, expectedIcon) in categories) {
        final audioFile = TestUtils.createSampleAudioFile(
          category: category,
          title: 'Test $category',
        );

        await tester.pumpWidget(
          WidgetTestHelpers.createMinimalTestWrapper(
            child: MiniPlayer(
              audioFile: audioFile,
              playbackState: PlaybackState.paused,
              onTap: mockOnTap,
              onPlayPause: mockOnPlayPause,
              onNext: mockOnNext,
              onPrevious: mockOnPrevious,
            ),
          ),
        );

        // Verify correct category icon is displayed
        expect(find.byIcon(expectedIcon), findsOneWidget);
      }
    });

    testWidgets('truncates long titles correctly', (tester) async {
      final longTitleAudioFile = TestUtils.createSampleAudioFile(
        title: 'This is a very long title that should be truncated because it exceeds the available space in the mini player widget',
      );

      await tester.pumpWidget(
        WidgetTestHelpers.createMinimalTestWrapper(
          child: MiniPlayer(
            audioFile: longTitleAudioFile,
            playbackState: PlaybackState.paused,
            onTap: mockOnTap,
            onPlayPause: mockOnPlayPause,
            onNext: mockOnNext,
            onPrevious: mockOnPrevious,
          ),
        ),
      );

      // Verify title is displayed (Flutter will handle text overflow)
      expect(find.textContaining('This is a very long title'), findsOneWidget);
      
      // Verify the Text widget has overflow property set
      final titleText = tester.widget<Text>(
        find.textContaining('This is a very long title'),
      );
      expect(titleText.overflow, equals(TextOverflow.ellipsis));
      expect(titleText.maxLines, equals(1));
    });

    testWidgets('applies correct theme styling', (tester) async {
      await WidgetTestHelpers.testBothThemes(
        tester,
        (theme) => WidgetTestHelpers.createMinimalTestWrapper(
          theme: theme,
          child: MiniPlayer(
            audioFile: testAudioFile,
            playbackState: PlaybackState.playing,
            onTap: mockOnTap,
            onPlayPause: mockOnPlayPause,
            onNext: mockOnNext,
            onPrevious: mockOnPrevious,
          ),
        ),
        (tester, theme) async {
          // Verify mini player is displayed with theme-appropriate styling
          expect(find.byType(Container), findsAtLeastNWidgets(1));
          expect(find.byType(Material), findsOneWidget);
        },
      );
    });

    testWidgets('supports accessibility features', (tester) async {
      await tester.pumpWidget(
        WidgetTestHelpers.createMinimalTestWrapper(
          child: MiniPlayer(
            audioFile: testAudioFile,
            playbackState: PlaybackState.playing,
            onTap: mockOnTap,
            onPlayPause: mockOnPlayPause,
            onNext: mockOnNext,
            onPrevious: mockOnPrevious,
          ),
        ),
      );

      await WidgetTestHelpers.verifyAccessibility(tester);

      // Verify control buttons are accessible
      final playButton = find.byIcon(Icons.pause);
      final nextButton = find.byIcon(Icons.skip_next);
      final previousButton = find.byIcon(Icons.skip_previous);

      expect(playButton, findsOneWidget);
      expect(nextButton, findsOneWidget);
      expect(previousButton, findsOneWidget);
    });

    testWidgets('handles different screen sizes correctly', (tester) async {
      await WidgetTestHelpers.testMultipleScreenSizes(
        tester,
        WidgetTestHelpers.createMinimalTestWrapper(
          child: MiniPlayer(
            audioFile: testAudioFile,
            playbackState: PlaybackState.playing,
            onTap: mockOnTap,
            onPlayPause: mockOnPlayPause,
            onNext: mockOnNext,
            onPrevious: mockOnPrevious,
          ),
        ),
        (tester, size) async {
          // Verify mini player adapts to different screen sizes
          expect(find.text(testAudioFile.displayTitle), findsOneWidget);
          expect(find.byIcon(Icons.pause), findsOneWidget);
          expect(find.byIcon(Icons.skip_next), findsOneWidget);
          expect(find.byIcon(Icons.skip_previous), findsOneWidget);
        },
      );
    });

    testWidgets('handles edge cases gracefully', (tester) async {
      final edgeAudioFile = TestUtils.createEdgeCaseAudioFile();

      await tester.pumpWidget(
        WidgetTestHelpers.createMinimalTestWrapper(
          child: MiniPlayer(
            audioFile: edgeAudioFile,
            playbackState: PlaybackState.stopped,
            onTap: mockOnTap,
            onPlayPause: mockOnPlayPause,
            onNext: mockOnNext,
            onPrevious: mockOnPrevious,
          ),
        ),
      );

      // Verify widget doesn't crash with edge case data
      expect(find.byType(MiniPlayer), findsOneWidget);
    });

    testWidgets('shows glass morphism effect correctly', (tester) async {
      await tester.pumpWidget(
        WidgetTestHelpers.createMinimalTestWrapper(
          child: MiniPlayer(
            audioFile: testAudioFile,
            playbackState: PlaybackState.playing,
            onTap: mockOnTap,
            onPlayPause: mockOnPlayPause,
            onNext: mockOnNext,
            onPrevious: mockOnPrevious,
          ),
        ),
      );

      // Verify container with decoration is present (glass morphism effect)
      final container = tester.widget<Container>(
        find.byType(Container).first,
      );
      expect(container.decoration, isNotNull);
      expect(container.margin, isNotNull);
    });
  });
}
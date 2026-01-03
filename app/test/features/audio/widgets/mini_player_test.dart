import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/features/audio/widgets/mini_player.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';

import '../../../test_utils.dart';

void main() {
  group('MiniPlayer', () {
    late AudioFile testAudioFile;

    setUp(() {
      testAudioFile = TestUtils.createSampleAudioFile(
        id: 'mini-1',
        title: 'Mini Episode',
        category: 'defi',
      );
    });

    Future<void> pumpMiniPlayer(
      WidgetTester tester, {
      bool isPlaying = false,
      bool isPaused = false,
      bool isLoading = false,
      bool hasError = false,
      String stateText = '',
      VoidCallback? onPlayPause,
      VoidCallback? onNext,
      VoidCallback? onPrevious,
    }) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MiniPlayer(
            audioFile: testAudioFile,
            isPlaying: isPlaying,
            isPaused: isPaused,
            isLoading: isLoading,
            hasError: hasError,
            stateText: stateText,
            onTap: () {},
            onPlayPause: onPlayPause ?? () {},
            onNext: onNext ?? () {},
            onPrevious: onPrevious ?? () {},
          ),
        ),
      ));
    }

    testWidgets('renders track info correctly', (tester) async {
      await pumpMiniPlayer(tester, stateText: 'Stopped');

      expect(find.text('Mini Episode'), findsOneWidget);
      expect(find.byIcon(Icons.account_balance), findsOneWidget); // defi icon
      expect(find.textContaining('defi'),
          findsOneWidget); // Category text inside Row
    });

    testWidgets('shows loading state correctly', (tester) async {
      await pumpMiniPlayer(
        tester,
        isLoading: true,
        stateText: 'Buffering...',
      );

      // Loading indicator replaces play icon inside primary button
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Buffering...'), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_empty),
          findsOneWidget); // State indicator
    });

    testWidgets('shows playing state correctly', (tester) async {
      await pumpMiniPlayer(
        tester,
        isPlaying: true,
        stateText: 'Playing',
      );

      expect(find.byIcon(Icons.pause),
          findsOneWidget); // Pause button needed to stop
      expect(
          find.byIcon(Icons.graphic_eq), findsOneWidget); // Playing indicator
      expect(find.text('Playing'), findsOneWidget);
    });

    testWidgets('shows paused state correctly', (tester) async {
      await pumpMiniPlayer(
        tester,
        isPaused: true,
        stateText: 'Paused',
      );

      expect(find.byIcon(Icons.play_arrow),
          findsOneWidget); // Play button needed to resume
      expect(find.byIcon(Icons.pause_circle_outline),
          findsOneWidget); // Paused indicator
    });

    testWidgets('shows error state correctly', (tester) async {
      await pumpMiniPlayer(
        tester,
        hasError: true,
        stateText: 'Error',
      );

      expect(find.byIcon(Icons.refresh), findsOneWidget); // Retry button
      expect(
          find.byIcon(Icons.error_outline), findsOneWidget); // Error indicator
      expect(find.text('Error'), findsOneWidget);
    });

    testWidgets('callbacks work', (tester) async {
      bool playPauseCalled = false;
      bool nextCalled = false;
      bool prevCalled = false;

      await pumpMiniPlayer(
        tester,
        onPlayPause: () => playPauseCalled = true,
        onNext: () => nextCalled = true,
        onPrevious: () => prevCalled = true,
      );

      // Find buttons by icon
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      expect(playPauseCalled, isTrue);

      await tester.tap(find.byIcon(Icons.skip_next));
      await tester.pump();
      expect(nextCalled, isTrue);

      await tester.tap(find.byIcon(Icons.skip_previous));
      await tester.pump();
      expect(prevCalled, isTrue);
    });
  });
}

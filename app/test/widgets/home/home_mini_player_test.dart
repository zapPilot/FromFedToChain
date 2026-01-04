import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:from_fed_to_chain_app/features/content/widgets/home/home_mini_player.dart';
import 'package:from_fed_to_chain_app/features/audio/services/audio_player_service.dart';
import 'package:from_fed_to_chain_app/features/audio/services/player_state_notifier.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/features/audio/widgets/mini_player.dart';

import '../screens/home_screen_coverage_test.mocks.dart';

void main() {
  group('HomeMiniPlayer Tests', () {
    late MockAudioPlayerService mockAudioService;
    late AudioFile testAudioFile;

    setUp(() {
      mockAudioService = MockAudioPlayerService();
      testAudioFile = AudioFile(
        id: 'test-1',
        title: 'Test Episode',
        language: 'zh-TW',
        category: 'daily-news',
        streamingUrl: 'url',
        path: 'path',
        duration: const Duration(minutes: 5),
        lastModified: DateTime.now(),
      );

      when(mockAudioService.currentAudioFile).thenReturn(testAudioFile);
      when(mockAudioService.playbackState).thenReturn(AppPlaybackState.playing);
      when(mockAudioService.isPlaying).thenReturn(true);
      when(mockAudioService.isPaused).thenReturn(false);
      when(mockAudioService.isLoading).thenReturn(false);
      when(mockAudioService.hasError).thenReturn(false);
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<AudioPlayerService>.value(
            value: mockAudioService,
            child: const HomeMiniPlayer(),
          ),
        ),
      );
    }

    testWidgets('renders MiniPlayer when audio is present', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(MiniPlayer), findsOneWidget);
      expect(find.text('Test Episode'), findsOneWidget);
    });

    testWidgets('renders nothing when currentAudioFile is null',
        (tester) async {
      when(mockAudioService.currentAudioFile).thenReturn(null);
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(MiniPlayer), findsNothing);
    });

    testWidgets('shows correct state text: Loading', (tester) async {
      when(mockAudioService.isLoading).thenReturn(true);
      await tester.pumpWidget(createTestWidget());
      expect(find.text('Loading'), findsOneWidget);
    });

    testWidgets('shows correct state text: Error', (tester) async {
      when(mockAudioService.hasError).thenReturn(true);
      await tester.pumpWidget(createTestWidget());
      expect(find.text('Error'), findsOneWidget);
    });

    testWidgets('shows correct state text: Paused', (tester) async {
      when(mockAudioService.isPlaying).thenReturn(false);
      when(mockAudioService.isPaused).thenReturn(true);
      await tester.pumpWidget(createTestWidget());
      expect(find.text('Paused'), findsOneWidget);
    });

    testWidgets('shows correct state text: Stopped', (tester) async {
      when(mockAudioService.isPlaying).thenReturn(false);
      when(mockAudioService.isPaused).thenReturn(false);
      when(mockAudioService.isLoading).thenReturn(false);
      when(mockAudioService.hasError).thenReturn(false);
      await tester.pumpWidget(createTestWidget());
      expect(find.text('Stopped'), findsOneWidget);
    });

    testWidgets('calls service methods on controls', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Tap play/pause
      await tester.tap(find.byIcon(Icons.pause));
      verify(mockAudioService.togglePlayPause()).called(1);

      // Tap next
      await tester.tap(find.byIcon(Icons.skip_next));
      verify(mockAudioService.skipToNextEpisode()).called(1);

      // Tap previous
      await tester.tap(find.byIcon(Icons.skip_previous));
      verify(mockAudioService.skipToPreviousEpisode()).called(1);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:from_fed_to_chain_app/features/audio/widgets/player/player_progress_bar.dart';
import 'package:from_fed_to_chain_app/features/audio/widgets/player/player_main_controls.dart';
import 'package:from_fed_to_chain_app/features/audio/services/audio_player_service.dart';
import 'package:from_fed_to_chain_app/features/audio/services/player_state_notifier.dart';
import 'package:from_fed_to_chain_app/features/content/widgets/episode_options_sheet.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/features/content/services/playlist_service.dart';
import 'package:from_fed_to_chain_app/features/content/services/content_service.dart';

import '../screens/home_screen_coverage_test.mocks.dart';

void main() {
  group('PlayerWidgets Coverage Tests', () {
    late MockAudioPlayerService mockAudioService;
    late MockContentService mockContentService;
    late MockPlaylistService mockPlaylistService;
    late AudioFile testAudioFile;

    setUp(() {
      mockAudioService = MockAudioPlayerService();
      mockContentService = MockContentService();
      mockPlaylistService = MockPlaylistService();

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
      when(mockAudioService.playbackState).thenReturn(AppPlaybackState.paused);
      when(mockAudioService.isPlaying).thenReturn(false);
      when(mockAudioService.isPaused).thenReturn(true);
      when(mockAudioService.isLoading).thenReturn(false);
      when(mockAudioService.hasError).thenReturn(false);
      when(mockAudioService.currentPosition).thenReturn(Duration.zero);
      when(mockAudioService.totalDuration)
          .thenReturn(const Duration(minutes: 5));
      when(mockAudioService.progress).thenReturn(0.0);
      when(mockAudioService.formattedCurrentPosition).thenReturn('0:00');
      when(mockAudioService.formattedTotalDuration).thenReturn('5:00');
      when(mockAudioService.playbackSpeed).thenReturn(1.0);
      when(mockAudioService.repeatEnabled).thenReturn(false);
      when(mockAudioService.autoplayEnabled).thenReturn(false);
      when(mockAudioService.addListener(any)).thenReturn(null);
      when(mockAudioService.removeListener(any)).thenReturn(null);
    });

    Widget createTestWidget(Widget child) {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AudioPlayerService>.value(
                value: mockAudioService),
            ChangeNotifierProvider<ContentService>.value(
                value: mockContentService),
            ChangeNotifierProvider<PlaylistService>.value(
                value: mockPlaylistService),
          ],
          child: Scaffold(body: child),
        ),
      );
    }

    testWidgets('PlayerProgressBar interactions', (tester) async {
      await tester.pumpWidget(createTestWidget(PlayerProgressBar(
        audioService: mockAudioService,
        onSeek: (pos) => mockAudioService.seekTo(pos),
      )));

      // Verify initial state
      expect(find.text('0:00'), findsOneWidget);
      expect(find.text('5:00'), findsOneWidget);

      // Tap slider (middle)
      final slider = find.byType(Slider);
      await tester.tap(slider);
      await tester.pump();

      verify(mockAudioService.seekTo(any)).called(1);
    });

    testWidgets('PlayerMainControls state changes', (tester) async {
      await tester.pumpWidget(createTestWidget(PlayerMainControls(
        audioService: mockAudioService,
      )));

      // Play/Pause toggle
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      verify(mockAudioService.togglePlayPause()).called(1);

      // Next/Previous
      await tester.tap(find.byIcon(Icons.skip_next));
      await tester.pump();
      verify(mockAudioService.skipToNextEpisode()).called(1);

      await tester.tap(find.byIcon(Icons.skip_previous));
      await tester.pump();
      verify(mockAudioService.skipToPreviousEpisode()).called(1);

      // Forward/Backward
      await tester.tap(find.byIcon(Icons.forward_30));
      await tester.pump();
      verify(mockAudioService.skipForward()).called(1);

      await tester.tap(find.byIcon(Icons.replay_10));
      await tester.pump();
      verify(mockAudioService.skipBackward()).called(1);
    });

    testWidgets('EpisodeOptionsSheet items', (tester) async {
      when(mockContentService.getContentForAudioFile(any))
          .thenAnswer((_) async => null);

      await tester.pumpWidget(
          createTestWidget(EpisodeOptionsSheet(episode: testAudioFile)));
      await tester.pumpAndSettle();

      // Check common items
      expect(find.text('Play'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Add to Favorites'), findsOneWidget);

      // Tap Play
      await tester.tap(find.text('Play'));
      await tester.pumpAndSettle();
      verify(mockAudioService.playAudio(testAudioFile)).called(1);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:from_fed_to_chain_app/features/audio/services/audio_player_service.dart';
import 'package:from_fed_to_chain_app/features/audio/services/player_state_notifier.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/features/content/screens/home_screen.dart';
import 'package:from_fed_to_chain_app/features/content/services/content_service.dart';
import 'package:from_fed_to_chain_app/features/content/services/playlist_service.dart';

import 'home_screen_test.mocks.dart';

@GenerateMocks([ContentService, AudioPlayerService, PlaylistService])
void main() {
  group('HomeScreen - Basic Tests', () {
    late MockContentService mockContentService;
    late MockAudioPlayerService mockAudioService;
    late MockPlaylistService mockPlaylistService;
    late AudioFile testAudioFile;

    setUp(() {
      mockContentService = MockContentService();
      mockAudioService = MockAudioPlayerService();
      mockPlaylistService = MockPlaylistService();

      testAudioFile = AudioFile(
        id: 'test-1',
        title: 'Test Episode',
        language: 'zh-TW',
        category: 'daily-news',
        streamingUrl: 'https://test.com/audio.m3u8',
        path: 'audio/test.m3u8',
        lastModified: DateTime.now(),
        duration: const Duration(minutes: 10),
        fileSizeBytes: 1024000,
      );

      when(mockContentService.selectedLanguage).thenReturn('zh-TW');
      when(mockContentService.selectedCategory).thenReturn('all');
      when(mockContentService.searchQuery).thenReturn('');
      when(mockContentService.sortOrder).thenReturn('newest');
      when(mockContentService.isLoading).thenReturn(false);
      when(mockContentService.hasError).thenReturn(false);
      when(mockContentService.errorMessage).thenReturn(null);
      when(mockContentService.allEpisodes).thenReturn([testAudioFile]);
      when(mockContentService.filteredEpisodes).thenReturn([testAudioFile]);
      when(mockContentService.hasEpisodes).thenReturn(true);
      when(mockContentService.hasFilteredResults).thenReturn(true);
      when(mockContentService.getStatistics()).thenReturn({
        'totalEpisodes': 1,
        'filteredEpisodes': 1,
        'languages': <String, int>{'zh-TW': 1},
        'categories': <String, int>{'daily-news': 1},
      });
      when(mockContentService.getUnfinishedEpisodes()).thenReturn([]);
      when(mockContentService.getEpisodeCompletion(any)).thenReturn(0.0);
      when(mockContentService.getEpisodeVersions(any))
          .thenReturn([testAudioFile]);
      when(mockContentService.isEpisodeUnfinished(any)).thenReturn(false);
      when(mockContentService.listenHistory).thenReturn(<String, DateTime>{});
      when(mockContentService.getFocusQueue(any)).thenReturn([testAudioFile]);

      when(mockAudioService.currentAudioFile).thenReturn(null);
      when(mockAudioService.playbackState).thenReturn(AppPlaybackState.stopped);
      when(mockAudioService.currentPosition).thenReturn(Duration.zero);
      when(mockAudioService.totalDuration)
          .thenReturn(const Duration(minutes: 10));
      when(mockAudioService.isPlaying).thenReturn(false);
      when(mockAudioService.isPaused).thenReturn(false);
      when(mockAudioService.isLoading).thenReturn(false);
      when(mockAudioService.hasError).thenReturn(false);
      when(mockAudioService.errorMessage).thenReturn(null);
      when(mockAudioService.playAudio(any)).thenAnswer((_) async {});
    });

    tearDown(() {
      reset(mockContentService);
      reset(mockAudioService);
      reset(mockPlaylistService);
    });

    Widget createTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<ContentService>.value(
              value: mockContentService),
          ChangeNotifierProvider<AudioPlayerService>.value(
              value: mockAudioService),
          ChangeNotifierProvider<PlaylistService>.value(
              value: mockPlaylistService),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: const HomeScreen(),
        ),
      );
    }

    void configureLargeViewport(
      WidgetTester tester, {
      double devicePixelRatio = 1.0,
    }) {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = devicePixelRatio;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }

    Future<void> pumpHomeScreen(
      WidgetTester tester, {
      bool settle = false,
      double devicePixelRatio = 1.0,
    }) async {
      configureLargeViewport(tester, devicePixelRatio: devicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      if (settle) {
        await tester.pumpAndSettle();
        return;
      }
      await tester.pump();
    }

    group('Basic Widget Creation', () {
      testWidgets('should render HomeScreen without crashing', (tester) async {
        await pumpHomeScreen(tester);
        expect(find.byType(HomeScreen), findsOneWidget);
      });

      testWidgets('should display app title', (tester) async {
        await pumpHomeScreen(tester);
        expect(find.text('Queue'), findsOneWidget);
      });

      testWidgets('should display episode when available', (tester) async {
        await pumpHomeScreen(tester);
        expect(find.text(testAudioFile.title), findsOneWidget);
      });
    });

    group('Audio Playback', () {
      testWidgets('should handle episode tap for playback', (tester) async {
        await pumpHomeScreen(tester);
        final episodeCard = find.text(testAudioFile.title);
        expect(episodeCard, findsOneWidget);
        await tester.tap(episodeCard);
        await tester.pumpAndSettle();
      });

      testWidgets('should show mini player when audio is playing',
          (tester) async {
        when(mockAudioService.currentAudioFile).thenReturn(testAudioFile);
        when(mockAudioService.isPlaying).thenReturn(true);

        await pumpHomeScreen(tester);

        expect(find.text(testAudioFile.title), findsAtLeastNWidgets(1));
      });
    });

    group('Loading and Error States', () {
      testWidgets('should show loading indicator when loading', (tester) async {
        when(mockContentService.isLoading).thenReturn(true);
        when(mockContentService.allEpisodes).thenReturn([]);

        await pumpHomeScreen(tester);

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should show error message when error occurs',
          (tester) async {
        when(mockContentService.hasError).thenReturn(true);
        when(mockContentService.errorMessage).thenReturn('Network error');

        await pumpHomeScreen(tester);

        expect(find.text('Network error'), findsOneWidget);
      });

      testWidgets('should show empty state when no episodes', (tester) async {
        when(mockContentService.getFocusQueue('zh-TW')).thenReturn([]);

        await pumpHomeScreen(tester);

        expect(find.text('All Caught Up!'), findsOneWidget);
      });
    });

    group('Statistics Display', () {
      testWidgets('should render without statistics dependency',
          (tester) async {
        await pumpHomeScreen(tester);

        expect(find.byType(HomeScreen), findsOneWidget);
      });
    });

    group('Episode Options', () {
      testWidgets('should show options on long press', (tester) async {
        await pumpHomeScreen(tester, devicePixelRatio: 2.0);

        final episodeTile = find.text(testAudioFile.title);
        expect(episodeTile, findsOneWidget);
        await tester.longPress(episodeTile);
        await tester.pumpAndSettle();

        expect(find.text('Add to Playlist'), findsOneWidget);
        expect(find.text('Share'), findsOneWidget);

        await tester.tap(find.text('Add to Playlist'));
        await tester.pumpAndSettle();
      });
    });

    group('MiniPlayer State Text', () {
      testWidgets('should show Loading state text', (tester) async {
        when(mockAudioService.currentAudioFile).thenReturn(testAudioFile);
        when(mockAudioService.isLoading).thenReturn(true);

        await pumpHomeScreen(tester, devicePixelRatio: 2.0);

        expect(find.text('Loading'), findsOneWidget);
      });

      testWidgets('should show Error state text', (tester) async {
        when(mockAudioService.currentAudioFile).thenReturn(testAudioFile);
        when(mockAudioService.hasError).thenReturn(true);

        await pumpHomeScreen(tester, devicePixelRatio: 2.0);

        expect(find.text('Error'), findsOneWidget);
      });

      testWidgets('should show Paused state text', (tester) async {
        when(mockAudioService.currentAudioFile).thenReturn(testAudioFile);
        when(mockAudioService.isPaused).thenReturn(true);

        await pumpHomeScreen(tester, devicePixelRatio: 2.0);

        expect(find.text('Paused'), findsOneWidget);
      });
    });
  });
}

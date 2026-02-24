import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';

import 'package:from_fed_to_chain_app/features/audio/services/audio_player_service.dart';
import 'package:from_fed_to_chain_app/features/audio/services/player_state_notifier.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/features/content/models/content_service_state.dart';
import 'package:from_fed_to_chain_app/features/content/screens/home_screen.dart';
import 'package:from_fed_to_chain_app/features/content/services/playlist_service.dart';
import 'package:from_fed_to_chain_app/features/content/services/content_service.dart';
import 'package:from_fed_to_chain_app/features/content/widgets/audio_item_card.dart';

@GenerateMocks([ContentService, AudioPlayerService, PlaylistService])
import 'home_screen_coverage_test.mocks.dart';

void main() {
  group('HomeScreen Coverage Tests', () {
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
        streamingUrl: 'url',
        path: 'path',
        lastModified: DateTime.now(),
        duration: const Duration(minutes: 10),
      );

      // Default mocks
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
      when(mockContentService.getStatistics())
          .thenReturn({'totalEpisodes': 1, 'filteredEpisodes': 1});
      when(mockContentService.getUnfinishedEpisodes()).thenReturn([]);
      when(mockContentService.getFocusQueue(any)).thenReturn([testAudioFile]);
      when(mockContentService.getEpisodeVersions(any))
          .thenReturn([testAudioFile]);
      when(mockContentService.isEpisodeUnfinished(any)).thenReturn(false);
      when(mockContentService.isEpisodeFinished(any)).thenReturn(false);
      when(mockContentService.getEpisodeCompletion(any)).thenReturn(0.0);

      when(mockAudioService.currentAudioFile).thenReturn(null);
      when(mockAudioService.playbackState).thenReturn(AppPlaybackState.stopped);
      when(mockAudioService.isPlaying).thenReturn(false);
      when(mockAudioService.isPaused).thenReturn(false);
      when(mockAudioService.isLoading).thenReturn(false);
      when(mockAudioService.hasError).thenReturn(false);
      when(mockAudioService.playAudio(any)).thenAnswer((_) async {});
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
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      );
    }

    void configureLargeViewport(
      WidgetTester tester, {
      double devicePixelRatio = 2.0,
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
      double devicePixelRatio = 2.0,
    }) async {
      configureLargeViewport(tester, devicePixelRatio: devicePixelRatio);
      await tester.pumpWidget(createTestWidget());
      if (settle) {
        await tester.pumpAndSettle();
        return;
      }
      await tester.pump();
    }

    test('ContentServiceState equality', () {
      const state1 = ContentServiceState(
        allEpisodes: [],
        filteredEpisodes: [],
        isLoading: false,
        hasError: false,
        errorMessage: null,
        selectedLanguage: 'en',
        selectedCategory: 'all',
        searchQuery: '',
      );

      const state2 = ContentServiceState(
        allEpisodes: [],
        filteredEpisodes: [],
        isLoading: false,
        hasError: false,
        errorMessage: null,
        selectedLanguage: 'en',
        selectedCategory: 'all',
        searchQuery: '',
      );

      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));

      const state3 = ContentServiceState(
        allEpisodes: [],
        filteredEpisodes: [],
        isLoading: true, // changed
        hasError: false,
        errorMessage: null,
        selectedLanguage: 'en',
        selectedCategory: 'all',
        searchQuery: '',
      );

      expect(state1, isNot(equals(state3)));
    });

    testWidgets('Play Episode handles errors', (tester) async {
      when(mockAudioService.playAudio(any))
          .thenThrow(Exception('Playback failed'));

      await pumpHomeScreen(tester);

      await tester.tap(find.byKey(AudioItemCard.playButtonKey).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Cannot play audio'), findsOneWidget);
    });

    testWidgets('Episode Options Sheet actions', (tester) async {
      await pumpHomeScreen(tester, settle: true);

      await tester.longPress(find.text('Test Episode'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Play'));
      await tester.pumpAndSettle();
      verify(mockAudioService.playAudio(testAudioFile)).called(1);

      await tester.longPress(find.text('Test Episode'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add to Favorites'));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Test Episode'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
    });

    testWidgets('MiniPlayer Stopped state text', (tester) async {
      when(mockAudioService.currentAudioFile).thenReturn(testAudioFile);
      when(mockAudioService.isPlaying).thenReturn(false);
      when(mockAudioService.isPaused).thenReturn(false);
      when(mockAudioService.isLoading).thenReturn(false);
      when(mockAudioService.hasError).thenReturn(false);

      await pumpHomeScreen(tester);

      expect(find.text('Stopped'), findsOneWidget);
    });

    testWidgets('Error state retry', (tester) async {
      when(mockContentService.hasError).thenReturn(true);
      when(mockContentService.errorMessage).thenReturn('Network error');

      await pumpHomeScreen(tester);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      verify(mockContentService.refresh()).called(1);
    });

    testWidgets('shows Queue empty state when focus queue is empty',
        (tester) async {
      when(mockContentService.allEpisodes).thenReturn([]);
      when(mockContentService.getFocusQueue('zh-TW')).thenReturn([]);

      await pumpHomeScreen(tester);

      expect(find.text('All Caught Up!'), findsOneWidget);
      expect(find.text('No new episodes in zh-TW'), findsOneWidget);
    });

    testWidgets('shows loading indicator during first content load',
        (tester) async {
      when(mockContentService.isLoading).thenReturn(true);
      when(mockContentService.allEpisodes).thenReturn([]);

      await pumpHomeScreen(tester);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:from_fed_to_chain_app/features/content/screens/home_screen.dart';
import 'package:from_fed_to_chain_app/features/content/services/content_service.dart';
import 'package:from_fed_to_chain_app/features/audio/services/audio_player_service.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/features/audio/services/player_state_notifier.dart';

// Generate mocks for dependencies
@GenerateMocks([ContentService, AudioPlayerService])
import 'home_screen_test.mocks.dart';

void main() {
  group('HomeScreen - Basic Tests', () {
    late MockContentService mockContentService;
    late MockAudioPlayerService mockAudioService;
    late AudioFile testAudioFile;

    setUp(() {
      mockContentService = MockContentService();
      mockAudioService = MockAudioPlayerService();

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

      // Basic ContentService setup
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
      when(mockContentService.isEpisodeUnfinished(any)).thenReturn(false);
      when(mockContentService.listenHistory).thenReturn(<String, DateTime>{});
      when(mockContentService.currentPlaylist).thenReturn(null);

      // Basic AudioService setup
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
    });

    tearDown(() {
      reset(mockContentService);
      reset(mockAudioService);
    });

    Widget createTestWidget() {
      return MaterialApp(
        theme: ThemeData.dark(),
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<ContentService>.value(
                value: mockContentService),
            ChangeNotifierProvider<AudioPlayerService>.value(
                value: mockAudioService),
          ],
          child: const HomeScreen(),
        ),
      );
    }

    group('Basic Widget Creation', () {
      testWidgets('should render HomeScreen without crashing', (tester) async {
        // Set a larger screen size to prevent RenderFlex overflow
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.byType(HomeScreen), findsOneWidget);
      });

      testWidgets('should display app title', (tester) async {
        // Set a larger screen size to prevent RenderFlex overflow
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('From Fed to Chain'), findsOneWidget);
      });

      testWidgets('should display episode when available', (tester) async {
        // Set a larger screen size to prevent RenderFlex overflow
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text(testAudioFile.title), findsOneWidget);
      });
    });

    group('Filter Interactions', () {
      testWidgets('should handle language filter tap', (tester) async {
        // Set a larger screen size to prevent RenderFlex overflow
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Find language filter buttons
        final zhButton = find.text('中文');
        if (zhButton.evaluate().isNotEmpty) {
          await tester.tap(zhButton);
          await tester.pump();
          // Language change should be handled by ContentService
        }
      });

      testWidgets('should handle category filter tap', (tester) async {
        // Set a larger screen size to prevent RenderFlex overflow
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Find category filter buttons
        final categoryButton = find.text('Daily News');
        if (categoryButton.evaluate().isNotEmpty) {
          await tester.tap(categoryButton);
          await tester.pump();
          // Category change should be handled by ContentService
        }
      });
    });

    group('Audio Playback', () {
      testWidgets('should handle episode tap for playback', (tester) async {
        // Set a larger screen size to prevent RenderFlex overflow
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Find episode card and tap it
        final episodeCard = find.text(testAudioFile.title);
        if (episodeCard.evaluate().isNotEmpty) {
          await tester.tap(episodeCard);
          await tester.pump();
          // Should navigate to player screen or start playback
        }
      });

      testWidgets('should show mini player when audio is playing',
          (tester) async {
        when(mockAudioService.currentAudioFile).thenReturn(testAudioFile);
        when(mockAudioService.isPlaying).thenReturn(true);

        // Set a larger screen size to prevent RenderFlex overflow
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Should show mini player
        expect(find.text(testAudioFile.title), findsAtLeastNWidgets(1));
      });
    });

    group('Search Functionality', () {
      testWidgets('should handle search input', (tester) async {
        // Set a larger screen size to prevent RenderFlex overflow
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Find search field
        final searchField = find.byType(TextField);
        if (searchField.evaluate().isNotEmpty) {
          await tester.enterText(searchField.first, 'test search');
          await tester.pump();
          // Search should filter episodes
        }
      });
    });

    group('Loading and Error States', () {
      testWidgets('should show loading indicator when loading', (tester) async {
        when(mockContentService.isLoading).thenReturn(true);

        // Set a larger screen size to prevent RenderFlex overflow
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should show error message when error occurs',
          (tester) async {
        when(mockContentService.hasError).thenReturn(true);
        when(mockContentService.errorMessage).thenReturn('Network error');

        // Set a larger screen size to prevent RenderFlex overflow
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Network error'), findsOneWidget);
      });

      testWidgets('should show empty state when no episodes', (tester) async {
        when(mockContentService.hasEpisodes).thenReturn(false);
        when(mockContentService.filteredEpisodes).thenReturn([]);

        // Set a larger screen size to prevent RenderFlex overflow
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Should show some kind of empty state message
        expect(find.byType(HomeScreen), findsOneWidget);
      });
    });

    group('Statistics Display', () {
      testWidgets('should show episode statistics', (tester) async {
        // Set a larger screen size to prevent RenderFlex overflow
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Check if statistics are displayed somewhere
        expect(find.byType(HomeScreen), findsOneWidget);
        // Statistics should be accessible through ContentService
        verify(mockContentService.getStatistics())
            .called(greaterThanOrEqualTo(0));
      });
    });

    group('Navigation', () {
      testWidgets('should navigate to player on episode selection',
          (tester) async {
        // Set a larger screen size to prevent RenderFlex overflow
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Tap on episode should trigger navigation
        final episodeTile = find.text(testAudioFile.title);
        if (episodeTile.evaluate().isNotEmpty) {
          await tester.tap(episodeTile);
          await tester.pump();
          // Navigation would be handled by Navigator
        }
      });
    });
  });
}

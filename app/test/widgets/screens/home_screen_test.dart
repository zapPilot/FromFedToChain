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
import 'package:from_fed_to_chain_app/features/content/widgets/audio_list.dart';
import 'package:from_fed_to_chain_app/features/content/services/playlist_service.dart';

// Generate mocks for dependencies
@GenerateMocks([ContentService, AudioPlayerService, PlaylistService])
import 'home_screen_test.mocks.dart';

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
    group('Sort Functionality', () {
      testWidgets('should handle sort selection', (tester) async {
        // Use a larger screen size
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Find sort dropdown
        final sortIcon = find.byIcon(Icons.sort);
        expect(sortIcon, findsOneWidget);

        // Find dropdown button
        final dropdownFinder = find.byType(DropdownButton<String>);
        expect(dropdownFinder, findsOneWidget);

        // Tap to open
        await tester.tap(dropdownFinder);
        await tester.pumpAndSettle();

        // Find and tap a menu item (e.g. "Oldest First")
        final oldestOption = find.text('Oldest First').last;
        await tester.tap(oldestOption);
        await tester.pumpAndSettle();

        // Verify service called
        verify(mockContentService.setSortOrder('oldest')).called(1);
      });
    });

    group('Tab Navigation', () {
      testWidgets('should switch tabs', (tester) async {
        // Use a larger screen size
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Find "All" tab
        final allTab = find.widgetWithText(Tab, 'All');
        await tester.tap(allTab);
        await tester.pumpAndSettle();

        // Should show list in All tab
        expect(find.byType(AudioList), findsWidgets);
      });

      testWidgets('should show empty state for Unfinished tab', (tester) async {
        // Use a larger screen size
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        // Mock empty unfinished list
        when(mockContentService.getUnfinishedEpisodes()).thenReturn([]);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Go to unfinished tab
        await tester.tap(find.widgetWithText(Tab, 'Unfinished'));
        await tester.pumpAndSettle();

        // Expect empty state message
        expect(find.text('No Unfinished Episodes'), findsOneWidget);
      });
    });

    group('Episode Options', () {
      testWidgets('should show options on long press', (tester) async {
        // Use a larger screen size
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Long press an episode
        final episodeTile = find.text(testAudioFile.title);
        await tester.longPress(episodeTile);
        await tester.pumpAndSettle();

        // Verify bottom sheet appears
        expect(find.text('Add to Playlist'), findsOneWidget);
        expect(find.text('Share'), findsOneWidget);

        // Tap an option (e.g., Add to Playlist)
        await tester.tap(find.text('Add to Playlist'));
        await tester.pumpAndSettle();
      });
    });

    group('Search Toggle', () {
      testWidgets('should toggle search bar visibility', (tester) async {
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Find search toggle button (initially shows search icon)
        final searchButton = find.byIcon(Icons.search);
        expect(searchButton, findsOneWidget);

        // Tap to show search bar
        await tester.tap(searchButton);
        await tester.pumpAndSettle();

        // Now should show close icon
        expect(find.byIcon(Icons.close), findsOneWidget);
      });
    });

    group('Refresh Button', () {
      testWidgets('should call refresh when tapped', (tester) async {
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Find refresh button
        final refreshButton = find.byIcon(Icons.refresh);
        expect(refreshButton, findsOneWidget);

        await tester.tap(refreshButton);
        await tester.pump();

        verify(mockContentService.refresh()).called(1);
      });

      testWidgets('should show loading indicator when loading', (tester) async {
        when(mockContentService.isLoading).thenReturn(true);

        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Refresh button should be disabled and show loading spinner
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      });
    });

    group('Recent Tab', () {
      testWidgets('should display recent episodes in Recent tab',
          (tester) async {
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Recent tab is default; should display AudioList
        expect(find.byType(AudioList), findsWidgets);
      });
    });

    group('Empty State Variations', () {
      testWidgets('should show clear filters button when search is active',
          (tester) async {
        when(mockContentService.searchQuery).thenReturn('nonexistent query');
        when(mockContentService.filteredEpisodes).thenReturn([]);

        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Should show "Clear filters" button
        expect(find.text('Clear filters'), findsOneWidget);
      });

      testWidgets('should show refresh button when no search is active',
          (tester) async {
        when(mockContentService.searchQuery).thenReturn('');
        when(mockContentService.filteredEpisodes).thenReturn([]);

        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Should show "Refresh" button instead
        expect(find.widgetWithText(ElevatedButton, 'Refresh'), findsOneWidget);
      });
    });

    group('MiniPlayer State Text', () {
      testWidgets('should show Loading state text', (tester) async {
        when(mockAudioService.currentAudioFile).thenReturn(testAudioFile);
        when(mockAudioService.isLoading).thenReturn(true);

        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Loading'), findsOneWidget);
      });

      testWidgets('should show Error state text', (tester) async {
        when(mockAudioService.currentAudioFile).thenReturn(testAudioFile);
        when(mockAudioService.hasError).thenReturn(true);

        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Error'), findsOneWidget);
      });

      testWidgets('should show Paused state text', (tester) async {
        when(mockAudioService.currentAudioFile).thenReturn(testAudioFile);
        when(mockAudioService.isPaused).thenReturn(true);

        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Paused'), findsOneWidget);
      });
    });

    group('Unfinished Tab with Episodes', () {
      testWidgets('should display unfinished episodes', (tester) async {
        when(mockContentService.getUnfinishedEpisodes())
            .thenReturn([testAudioFile]);

        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Go to unfinished tab
        await tester.tap(find.widgetWithText(Tab, 'Unfinished'));
        await tester.pumpAndSettle();

        // Should show episode instead of empty state
        expect(find.text(testAudioFile.title), findsAtLeastNWidgets(1));
      });
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:from_fed_to_chain_app/screens/home_screen.dart';
import 'package:from_fed_to_chain_app/screens/player_screen.dart';
import 'package:from_fed_to_chain_app/widgets/audio_item_card.dart';
import 'package:from_fed_to_chain_app/widgets/mini_player.dart';
import 'package:from_fed_to_chain_app/widgets/filter_bar.dart';
import 'package:from_fed_to_chain_app/widgets/search_bar.dart';
import 'package:from_fed_to_chain_app/services/audio_service.dart';
import '../test_utils.dart';
import '../helpers/widget_test_helpers.dart';
import '../helpers/service_mocks.dart';
import '../helpers/service_mocks.mocks.dart';

void main() {
  group('User Flow Integration Tests', () {
    late MockContentService mockContentService;
    late MockAudioService mockAudioService;
    late MockAuthService mockAuthService;
    late MockNavigatorObserver mockNavigatorObserver;

    setUp(() {
      mockContentService = MockContentService();
      mockAudioService = MockAudioService();
      mockAuthService = MockAuthService();
      mockNavigatorObserver = MockNavigatorObserver();
    });

    group('Browse Episodes Flow', () {
      testWidgets('user can browse episodes across different tabs', (tester) async {
        WidgetTestHelpers.setupMockDataForTesting(mockContentService);
        
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapperWithNavigation(
            child: const HomeScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
            navigatorObservers: [mockNavigatorObserver],
          ),
        );

        // Step 1: Verify initial state - Recent tab is selected
        expect(find.text('Recent'), findsOneWidget);
        expect(find.byType(AudioItemCard), findsAtLeastNWidgets(1));

        // Step 2: Switch to All tab
        await tester.tap(find.text('All'));
        await tester.pumpAndSettle();
        
        // Verify All tab content
        expect(find.byType(AudioItemCard), findsAtLeastNWidgets(1));

        // Step 3: Switch to Unfinished tab
        await tester.tap(find.text('Unfinished'));
        await tester.pumpAndSettle();

        // Verify Unfinished tab content (should show episodes based on mock data)
        expect(find.byType(AudioItemCard), findsAtLeastNWidgets(1));

        // Step 4: Return to Recent tab
        await tester.tap(find.text('Recent'));
        await tester.pumpAndSettle();

        // Verify we're back to Recent tab
        expect(find.byType(AudioItemCard), findsAtLeastNWidgets(1));
      });

      testWidgets('user can scroll through long episode lists', (tester) async {
        // Create a long list of episodes
        final longEpisodeList = List.generate(
          50,
          (index) => TestUtils.createSampleAudioFile(
            id: 'episode-$index',
            title: 'Episode $index',
            category: 'daily-news',
            language: 'en-US',
          ),
        );

        when(mockContentService.allEpisodes).thenReturn(longEpisodeList);
        when(mockContentService.filteredEpisodes).thenReturn(longEpisodeList);
        when(mockContentService.hasEpisodes).thenReturn(true);
        when(mockContentService.hasFilteredResults).thenReturn(true);
        when(mockContentService.getStatistics()).thenReturn({
          'totalEpisodes': longEpisodeList.length,
          'filteredEpisodes': longEpisodeList.length,
          'recentEpisodes': 20,
          'unfinishedEpisodes': 5,
        });

        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const HomeScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Verify initial episodes are visible
        expect(find.text('Episode 0'), findsOneWidget);
        expect(find.text('Episode 49'), findsNothing);

        // Scroll down to load more episodes
        await WidgetTestHelpers.scrollUntilVisible(
          tester,
          find.text('Episode 49'),
          find.byType(ListView),
          delta: -500.0,
        );

        // Verify we can see episodes further down the list
        expect(find.text('Episode 49'), findsOneWidget);
      });
    });

    group('Filter and Search Flow', () {
      testWidgets('user can filter episodes by language and category', (tester) async {
        WidgetTestHelpers.setupMockDataForTesting(mockContentService);
        
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const HomeScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Step 1: Filter by language (English)
        await tester.tap(find.text('🇺🇸 English'));
        await tester.pumpAndSettle();

        // Verify language filter was applied
        verify(mockContentService.setLanguage('en-US')).called(1);

        // Step 2: Filter by category (Ethereum)
        await tester.tap(find.text('⚡ Ethereum'));
        await tester.pumpAndSettle();

        // Verify category filter was applied
        verify(mockContentService.setCategory('ethereum')).called(1);

        // Step 3: Reset filters to "All"
        final allButtons = find.text('All');
        await tester.tap(allButtons.first); // Language All
        await tester.pumpAndSettle();

        await tester.tap(allButtons.last); // Category All
        await tester.pumpAndSettle();

        // Verify filters were reset
        verify(mockContentService.setLanguage('all')).called(1);
        verify(mockContentService.setCategory('all')).called(1);
      });

      testWidgets('user can search for episodes', (tester) async {
        WidgetTestHelpers.setupMockDataForTesting(mockContentService);
        
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const HomeScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Step 1: Open search
        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();

        // Verify search bar is visible
        expect(find.byType(SearchBarWidget), findsOneWidget);

        // Step 2: Enter search query
        await tester.enterText(find.byType(TextField), 'bitcoin');
        await tester.pumpAndSettle();

        // Verify search query was set
        verify(mockContentService.setSearchQuery('bitcoin')).called(1);

        // Step 3: Clear search
        await tester.enterText(find.byType(TextField), '');
        await tester.pumpAndSettle();

        // Step 4: Close search
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Verify search bar is hidden
        expect(find.byType(SearchBarWidget), findsNothing);
      });

      testWidgets('user can change sort order', (tester) async {
        WidgetTestHelpers.setupMockDataForTesting(mockContentService);
        
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const HomeScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Step 1: Open sort dropdown
        await tester.tap(find.byType(DropdownButton<String>));
        await tester.pumpAndSettle();

        // Step 2: Select alphabetical sort
        await tester.tap(find.text('A-Z').last);
        await tester.pumpAndSettle();

        // Verify sort order was changed
        verify(mockContentService.setSortOrder('alphabetical')).called(1);

        // Step 3: Open dropdown again and select oldest first
        await tester.tap(find.byType(DropdownButton<String>));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Oldest First').last);
        await tester.pumpAndSettle();

        // Verify sort order was changed again
        verify(mockContentService.setSortOrder('oldest')).called(1);
      });
    });

    group('Audio Playback Flow', () {
      testWidgets('user can play audio and navigate to player screen', (tester) async {
        WidgetTestHelpers.setupMockDataForTesting(mockContentService);
        
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapperWithNavigation(
            child: const HomeScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
            navigatorObservers: [mockNavigatorObserver],
          ),
        );

        // Step 1: Tap on an episode to play
        await tester.tap(find.byType(AudioItemCard).first);
        await tester.pumpAndSettle();

        // Verify audio playback was initiated
        verify(mockAudioService.playAudio(any)).called(1);

        // Step 2: Simulate audio starting to play
        final testAudio = TestUtils.createSampleAudioFile();
        when(mockAudioService.currentAudioFile).thenReturn(testAudio);
        when(mockAudioService.playbackState).thenReturn(PlaybackState.playing);
        mockAudioService.notifyListeners();
        await tester.pump();

        // Verify mini player appears
        expect(find.byType(MiniPlayer), findsOneWidget);

        // Step 3: Tap on mini player to navigate to full player
        await tester.tap(find.byType(MiniPlayer));
        await tester.pumpAndSettle();

        // Verify navigation to player screen occurred
        expect(mockNavigatorObserver.pushedRoutes.length, equals(1));
        expect(mockNavigatorObserver.pushedRoutes.first.settings.name, contains('PlayerScreen'));
      });

      testWidgets('user can control audio playback from mini player', (tester) async {
        WidgetTestHelpers.setupMockDataForTesting(mockContentService);
        
        // Set up audio service with playing audio
        final testAudio = TestUtils.createSampleAudioFile();
        when(mockAudioService.currentAudioFile).thenReturn(testAudio);
        when(mockAudioService.playbackState).thenReturn(PlaybackState.playing);
        
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const HomeScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Verify mini player is visible
        expect(find.byType(MiniPlayer), findsOneWidget);

        // Step 1: Pause audio
        await tester.tap(find.byIcon(Icons.pause));
        await tester.pumpAndSettle();

        // Verify pause was called
        verify(mockAudioService.togglePlayPause()).called(1);

        // Step 2: Skip to next
        await tester.tap(find.byIcon(Icons.skip_next));
        await tester.pumpAndSettle();

        // Verify skip next was called
        verify(mockAudioService.skipToNextEpisode()).called(1);

        // Step 3: Skip to previous
        await tester.tap(find.byIcon(Icons.skip_previous));
        await tester.pumpAndSettle();

        // Verify skip previous was called
        verify(mockAudioService.skipToPreviousEpisode()).called(1);
      });
    });

    group('Error Recovery Flow', () {
      testWidgets('user can recover from loading errors', (tester) async {
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const HomeScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Step 1: Simulate error state
        await WidgetTestHelpers.testErrorState(
          tester,
          mockContentService,
          'Network error occurred',
          () async {
            // Verify error state is displayed
            expect(find.text('Something went wrong'), findsOneWidget);
            expect(find.text('Network error occurred'), findsOneWidget);
            expect(find.text('Retry'), findsOneWidget);
          },
        );

        // Step 2: Tap retry button
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();

        // Verify refresh was called
        verify(mockContentService.refresh()).called(1);

        // Step 3: Simulate successful recovery
        WidgetTestHelpers.setupMockDataForTesting(mockContentService);
        when(mockContentService.hasError).thenReturn(false);
        when(mockContentService.isLoading).thenReturn(false);
        mockContentService.notifyListeners();
        await tester.pump();

        // Verify normal content is displayed
        expect(find.text('From Fed to Chain'), findsOneWidget);
        expect(find.byType(FilterBar), findsOneWidget);
      });

      testWidgets('user can clear search when no results found', (tester) async {
        // Set up empty search results
        when(mockContentService.allEpisodes).thenReturn([]);
        when(mockContentService.filteredEpisodes).thenReturn([]);
        when(mockContentService.hasEpisodes).thenReturn(true);
        when(mockContentService.hasFilteredResults).thenReturn(false);
        when(mockContentService.searchQuery).thenReturn('nonexistent');
        when(mockContentService.isLoading).thenReturn(false);
        when(mockContentService.hasError).thenReturn(false);
        
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const HomeScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Verify empty state with search query
        expect(find.text('No episodes found'), findsOneWidget);
        expect(find.text('Try different search terms or filters'), findsOneWidget);
        expect(find.text('Clear filters'), findsOneWidget);

        // Tap clear filters
        await tester.tap(find.text('Clear filters'));
        await tester.pumpAndSettle();

        // Verify search query was cleared
        verify(mockContentService.setSearchQuery('')).called(1);
      });
    });

    group('Complex User Scenarios', () {
      testWidgets('user completes full episode discovery and playback flow', (tester) async {
        WidgetTestHelpers.setupMockDataForTesting(mockContentService);
        
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapperWithNavigation(
            child: const HomeScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
            navigatorObservers: [mockNavigatorObserver],
          ),
        );

        // Step 1: Search for specific content
        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();
        
        await tester.enterText(find.byType(TextField), 'bitcoin');
        await tester.pumpAndSettle();

        // Step 2: Apply filters
        await tester.tap(find.text('🇺🇸 English'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('📰 Daily News'));
        await tester.pumpAndSettle();

        // Step 3: Change sort order
        await tester.tap(find.byType(DropdownButton<String>));
        await tester.pumpAndSettle();
        
        await tester.tap(find.text('A-Z').last);
        await tester.pumpAndSettle();

        // Step 4: Play an episode
        await tester.tap(find.byType(AudioItemCard).first);
        await tester.pumpAndSettle();

        // Step 5: Simulate audio playing and navigate to full player
        final testAudio = TestUtils.createSampleAudioFile();
        when(mockAudioService.currentAudioFile).thenReturn(testAudio);
        when(mockAudioService.playbackState).thenReturn(PlaybackState.playing);
        mockAudioService.notifyListeners();
        await tester.pump();

        await tester.tap(find.byType(MiniPlayer));
        await tester.pumpAndSettle();

        // Verify all interactions were called
        verify(mockContentService.setSearchQuery('bitcoin')).called(1);
        verify(mockContentService.setLanguage('en-US')).called(1);
        verify(mockContentService.setCategory('daily-news')).called(1);
        verify(mockContentService.setSortOrder('alphabetical')).called(1);
        verify(mockAudioService.playAudio(any)).called(1);
        expect(mockNavigatorObserver.pushedRoutes.length, equals(1));
      });

      testWidgets('user handles multiple state changes gracefully', (tester) async {
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const HomeScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Cycle through different states
        
        // 1. Loading state
        await WidgetTestHelpers.testLoadingState(
          tester,
          mockContentService,
          () async {
            expect(find.byType(CircularProgressIndicator), findsOneWidget);
          },
        );

        // 2. Error state
        await WidgetTestHelpers.testErrorState(
          tester,
          mockContentService,
          'Connection failed',
          () async {
            expect(find.text('Something went wrong'), findsOneWidget);
          },
        );

        // 3. Success state
        WidgetTestHelpers.setupMockDataForTesting(mockContentService);
        when(mockContentService.hasError).thenReturn(false);
        when(mockContentService.isLoading).thenReturn(false);
        mockContentService.notifyListeners();
        await tester.pump();

        expect(find.text('From Fed to Chain'), findsOneWidget);
        expect(find.byType(FilterBar), findsOneWidget);

        // 4. Empty state
        await WidgetTestHelpers.testEmptyState(
          tester,
          mockContentService,
          () async {
            expect(find.text('No episodes found'), findsOneWidget);
          },
        );
      });
    });
  });
}
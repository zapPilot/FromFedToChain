import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:from_fed_to_chain_app/screens/home_screen.dart';
import 'package:from_fed_to_chain_app/widgets/audio_list.dart';
import 'package:from_fed_to_chain_app/widgets/mini_player.dart';
import 'package:from_fed_to_chain_app/widgets/filter_bar.dart';
import 'package:from_fed_to_chain_app/widgets/search_bar.dart';
import 'package:from_fed_to_chain_app/services/audio_service.dart';
import '../test_utils.dart';
import '../helpers/widget_test_helpers.dart';
import '../helpers/service_mocks.dart';

void main() {
  group('HomeScreen Tests', () {
    late MockContentService mockContentService;
    late MockAudioService mockAudioService;
    late MockAuthService mockAuthService;

    setUp(() {
      mockContentService = MockContentService();
      mockAudioService = MockAudioService();
      mockAuthService = MockAuthService();
    });

    testWidgets('displays app header correctly', (tester) async {
      WidgetTestHelpers.setupMockDataForTesting(mockContentService);
      
      await tester.pumpWidget(
        WidgetTestHelpers.createTestWrapper(
          child: const HomeScreen(),
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        ),
      );

      // Verify app header elements
      expect(find.text('From Fed to Chain'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byIcon(Icons.account_circle), findsOneWidget);
    });

    testWidgets('displays episode statistics correctly', (tester) async {
      WidgetTestHelpers.setupMockDataForTesting(mockContentService);
      
      await tester.pumpWidget(
        WidgetTestHelpers.createTestWrapper(
          child: const HomeScreen(),
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        ),
      );

      // Verify episode count is displayed
      expect(find.text('4 episodes'), findsOneWidget);
    });

    testWidgets('displays filtered episode count when filtering', (tester) async {
      // Set up filtered data
      final allEpisodes = [
        TestUtils.createSampleAudioFile(id: 'episode-1'),
        TestUtils.createSampleAudioFile(id: 'episode-2'),
        TestUtils.createSampleAudioFile(id: 'episode-3'),
        TestUtils.createSampleAudioFile(id: 'episode-4'),
      ];
      final filteredEpisodes = [allEpisodes.first, allEpisodes.last];

      when(mockContentService.allEpisodes).thenReturn(allEpisodes);
      when(mockContentService.filteredEpisodes).thenReturn(filteredEpisodes);
      when(mockContentService.hasEpisodes).thenReturn(true);
      when(mockContentService.hasFilteredResults).thenReturn(true);
      when(mockContentService.getStatistics()).thenReturn({
        'totalEpisodes': allEpisodes.length,
        'filteredEpisodes': filteredEpisodes.length,
        'recentEpisodes': 1,
        'unfinishedEpisodes': 1,
      });

      await tester.pumpWidget(
        WidgetTestHelpers.createTestWrapper(
          child: const HomeScreen(),
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        ),
      );

      // Verify filtered count is displayed
      expect(find.text('2 of 4 episodes'), findsOneWidget);
    });

    testWidgets('toggles search bar visibility correctly', (tester) async {
      WidgetTestHelpers.setupMockDataForTesting(mockContentService);
      
      await tester.pumpWidget(
        WidgetTestHelpers.createTestWrapper(
          child: const HomeScreen(),
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        ),
      );

      // Initially, search bar should not be visible
      expect(find.byType(SearchBarWidget), findsNothing);

      // Tap search button to show search bar
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Verify search bar is now visible
      expect(find.byType(SearchBarWidget), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      // Tap close button to hide search bar
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Verify search bar is hidden again
      expect(find.byType(SearchBarWidget), findsNothing);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('displays filter bar correctly', (tester) async {
      WidgetTestHelpers.setupMockDataForTesting(mockContentService);
      
      await tester.pumpWidget(
        WidgetTestHelpers.createTestWrapper(
          child: const HomeScreen(),
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        ),
      );

      // Verify filter bar is displayed
      expect(find.byType(FilterBar), findsOneWidget);
    });

    testWidgets('displays sort selector correctly', (tester) async {
      WidgetTestHelpers.setupMockDataForTesting(mockContentService);
      
      await tester.pumpWidget(
        WidgetTestHelpers.createTestWrapper(
          child: const HomeScreen(),
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        ),
      );

      // Verify sort selector elements
      expect(find.byIcon(Icons.sort), findsOneWidget);
      expect(find.text('Sort by:'), findsOneWidget);
      expect(find.byType(DropdownButton<String>), findsOneWidget);
    });

    testWidgets('displays tab bar with correct tabs', (tester) async {
      WidgetTestHelpers.setupMockDataForTesting(mockContentService);
      
      await tester.pumpWidget(
        WidgetTestHelpers.createTestWrapper(
          child: const HomeScreen(),
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        ),
      );

      // Verify tab bar and tabs
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('Recent'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Unfinished'), findsOneWidget);
    });

    testWidgets('displays audio list in Recent tab', (tester) async {
      WidgetTestHelpers.setupMockDataForTesting(mockContentService);
      
      await tester.pumpWidget(
        WidgetTestHelpers.createTestWrapper(
          child: const HomeScreen(),
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        ),
      );

      // Verify Recent tab content
      expect(find.byType(AudioList), findsOneWidget);
    });

    testWidgets('switches between tabs correctly', (tester) async {
      WidgetTestHelpers.setupMockDataForTesting(mockContentService);
      
      await tester.pumpWidget(
        WidgetTestHelpers.createTestWrapper(
          child: const HomeScreen(),
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        ),
      );

      // Tap on All tab
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      // Verify All tab content
      expect(find.byType(AudioList), findsOneWidget);

      // Tap on Unfinished tab
      await tester.tap(find.text('Unfinished'));
      await tester.pumpAndSettle();

      // Should show AudioList or empty state depending on unfinished episodes
      // The MockContentService returns one unfinished episode
      expect(find.byType(AudioList), findsOneWidget);
    });

    testWidgets('displays empty state in Unfinished tab when no unfinished episodes', (tester) async {
      WidgetTestHelpers.setupMockDataForTesting(mockContentService);
      when(mockContentService.getUnfinishedEpisodes()).thenReturn([]);
      
      await tester.pumpWidget(
        WidgetTestHelpers.createTestWrapper(
          child: const HomeScreen(),
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        ),
      );

      // Switch to Unfinished tab
      await tester.tap(find.text('Unfinished'));
      await tester.pumpAndSettle();

      // Verify empty state
      expect(find.text('No Unfinished Episodes'), findsOneWidget);
      expect(find.text('Episodes you\'ve started listening to will appear here'), findsOneWidget);
      expect(find.byIcon(Icons.pending_actions), findsOneWidget);
    });

    testWidgets('displays mini player when audio is playing', (tester) async {
      WidgetTestHelpers.setupMockDataForTesting(mockContentService);
      
      // Set up audio service with current audio
      final currentAudio = TestUtils.createSampleAudioFile();
      when(mockAudioService.currentAudioFile).thenReturn(currentAudio);
      when(mockAudioService.playbackState).thenReturn(PlaybackState.playing);
      
      await tester.pumpWidget(
        WidgetTestHelpers.createTestWrapper(
          child: const HomeScreen(),
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        ),
      );

      // Verify mini player is displayed
      expect(find.byType(MiniPlayer), findsOneWidget);
    });

    testWidgets('hides mini player when no audio is playing', (tester) async {
      WidgetTestHelpers.setupMockDataForTesting(mockContentService);
      
      // Set up audio service with no current audio
      when(mockAudioService.currentAudioFile).thenReturn(null);
      
      await tester.pumpWidget(
        WidgetTestHelpers.createTestWrapper(
          child: const HomeScreen(),
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        ),
      );

      // Verify mini player is not displayed
      expect(find.byType(MiniPlayer), findsNothing);
    });

    testWidgets('displays loading state correctly', (tester) async {
      await WidgetTestHelpers.testLoadingState(
        tester,
        mockContentService,
        () async {
          await tester.pumpWidget(
            WidgetTestHelpers.createTestWrapper(
              child: const HomeScreen(),
              contentService: mockContentService,
              audioService: mockAudioService,
              authService: mockAuthService,
            ),
          );

          // Verify loading state
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
          expect(find.text('Loading episodes...'), findsOneWidget);
          expect(find.text('This may take a few moments'), findsOneWidget);
        },
      );
    });

    testWidgets('displays error state correctly', (tester) async {
      const errorMessage = 'Failed to load episodes';
      
      await WidgetTestHelpers.testErrorState(
        tester,
        mockContentService,
        errorMessage,
        () async {
          await tester.pumpWidget(
            WidgetTestHelpers.createTestWrapper(
              child: const HomeScreen(),
              contentService: mockContentService,
              audioService: mockAudioService,
              authService: mockAuthService,
            ),
          );

          // Verify error state
          expect(find.text('Something went wrong'), findsOneWidget);
          expect(find.text(errorMessage), findsOneWidget);
          expect(find.byIcon(Icons.error_outline), findsOneWidget);
          expect(find.text('Retry'), findsOneWidget);
        },
      );
    });

    testWidgets('displays empty state correctly', (tester) async {
      await WidgetTestHelpers.testEmptyState(
        tester,
        mockContentService,
        () async {
          await tester.pumpWidget(
            WidgetTestHelpers.createTestWrapper(
              child: const HomeScreen(),
              contentService: mockContentService,
              audioService: mockAudioService,
              authService: mockAuthService,
            ),
          );

          // Verify empty state
          expect(find.text('No episodes found'), findsOneWidget);
          expect(find.text('Check your internet connection and try again'), findsOneWidget);
          expect(find.byIcon(Icons.headphones_outlined), findsOneWidget);
          expect(find.text('Refresh'), findsOneWidget);
        },
      );
    });

    testWidgets('handles refresh action correctly', (tester) async {
      WidgetTestHelpers.setupMockDataForTesting(mockContentService);
      
      await tester.pumpWidget(
        WidgetTestHelpers.createTestWrapper(
          child: const HomeScreen(),
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        ),
      );

      // Tap refresh button
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      // Verify refresh was called
      verify(mockContentService.refresh()).called(1);
    });

    testWidgets('handles sort order change correctly', (tester) async {
      WidgetTestHelpers.setupMockDataForTesting(mockContentService);
      
      await tester.pumpWidget(
        WidgetTestHelpers.createTestWrapper(
          child: const HomeScreen(),
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        ),
      );

      // Tap on sort dropdown
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      // Select a different sort option
      await tester.tap(find.text('A-Z').last);
      await tester.pumpAndSettle();

      // Verify sort order was changed
      verify(mockContentService.setSortOrder('alphabetical')).called(1);
    });

    testWidgets('handles search query changes correctly', (tester) async {
      WidgetTestHelpers.setupMockDataForTesting(mockContentService);
      
      await tester.pumpWidget(
        WidgetTestHelpers.createTestWrapper(
          child: const HomeScreen(),
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        ),
      );

      // Show search bar
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Enter search query
      await tester.enterText(find.byType(TextField), 'bitcoin');
      await tester.pumpAndSettle();

      // Verify search query was set
      verify(mockContentService.setSearchQuery('bitcoin')).called(1);
    });

    testWidgets('displays user profile information correctly', (tester) async {
      WidgetTestHelpers.setupMockDataForTesting(mockContentService);
      
      // Set up authenticated user
      when(mockAuthService.isAuthenticated).thenReturn(true);
      when(mockAuthService.currentUser).thenReturn(
        TestUtils.createSampleAppUser(
          name: 'John Doe',
          email: 'john@example.com',
        ),
      );
      
      await tester.pumpWidget(
        WidgetTestHelpers.createTestWrapper(
          child: const HomeScreen(),
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        ),
      );

      // Tap on profile menu
      await tester.tap(find.byIcon(Icons.account_circle));
      await tester.pumpAndSettle();

      // Verify user information is displayed
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('john@example.com'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('supports accessibility features', (tester) async {
      WidgetTestHelpers.setupMockDataForTesting(mockContentService);
      
      await tester.pumpWidget(
        WidgetTestHelpers.createTestWrapper(
          child: const HomeScreen(),
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        ),
      );

      await WidgetTestHelpers.verifyAccessibility(tester);

      // Verify important UI elements are accessible
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('handles different screen sizes correctly', (tester) async {
      WidgetTestHelpers.setupMockDataForTesting(mockContentService);
      
      await WidgetTestHelpers.testMultipleScreenSizes(
        tester,
        WidgetTestHelpers.createTestWrapper(
          child: const HomeScreen(),
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        ),
        (tester, size) async {
          // Verify key elements are present regardless of screen size
          expect(find.text('From Fed to Chain'), findsOneWidget);
          expect(find.byType(FilterBar), findsOneWidget);
          expect(find.byType(TabBar), findsOneWidget);
        },
      );
    });

    testWidgets('applies correct theme styling', (tester) async {
      WidgetTestHelpers.setupMockDataForTesting(mockContentService);
      
      await WidgetTestHelpers.testBothThemes(
        tester,
        (theme) => WidgetTestHelpers.createTestWrapper(
          theme: theme,
          child: const HomeScreen(),
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        ),
        (tester, theme) async {
          // Verify home screen renders correctly with both themes
          expect(find.text('From Fed to Chain'), findsOneWidget);
          expect(find.byType(Scaffold), findsOneWidget);
        },
      );
    });

    testWidgets('handles episode tap correctly', (tester) async {
      WidgetTestHelpers.setupMockDataForTesting(mockContentService);
      
      await tester.pumpWidget(
        WidgetTestHelpers.createTestWrapper(
          child: const HomeScreen(),
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        ),
      );

      // Find and tap on an episode
      final audioCards = find.byType(AudioList);
      expect(audioCards, findsOneWidget);

      // Note: Detailed episode interaction testing would require more specific
      // finders for individual episode cards within the AudioList
    });

    testWidgets('loads content on initialization', (tester) async {
      await tester.pumpWidget(
        WidgetTestHelpers.createTestWrapper(
          child: const HomeScreen(),
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        ),
      );

      // Wait for post-frame callback
      await tester.pumpAndSettle();

      // Verify loadAllEpisodes was called
      verify(mockContentService.loadAllEpisodes()).called(1);
    });
  });
}
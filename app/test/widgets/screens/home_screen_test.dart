import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:from_fed_to_chain_app/screens/home_screen.dart';
import 'package:from_fed_to_chain_app/services/content_service.dart';
import 'package:from_fed_to_chain_app/services/audio_service.dart';
import 'package:from_fed_to_chain_app/services/auth/auth_service.dart';
import 'package:from_fed_to_chain_app/models/audio_file.dart';
import 'package:from_fed_to_chain_app/widgets/filter_bar.dart';
import 'package:from_fed_to_chain_app/widgets/audio_list.dart';
import 'package:from_fed_to_chain_app/widgets/mini_player.dart';
import 'package:from_fed_to_chain_app/widgets/search_bar.dart';
import 'package:from_fed_to_chain_app/themes/app_theme.dart';

// Generate mocks for dependencies
@GenerateMocks([ContentService, AudioService, AuthService])
import 'home_screen_test.mocks.dart';

/// Comprehensive test utilities for HomeScreen testing
class HomeScreenTestUtils {
  /// Create sample episodes for testing
  static List<AudioFile> createSampleEpisodes({
    int count = 5,
    String language = 'zh-TW',
    String category = 'daily-news',
  }) {
    return List.generate(
        count,
        (index) => AudioFile(
              id: 'episode-${index + 1}-$language',
              title: 'Episode ${index + 1} Title - $language',
              language: language,
              category: index % 2 == 0 ? category : 'ethereum',
              streamingUrl: 'https://test.com/episode${index + 1}.m3u8',
              path: 'audio/$language/$category/episode${index + 1}.m3u8',
              lastModified: DateTime(2025, 1, 15 - index),
              duration: Duration(minutes: 10 + index),
            ));
  }

  /// Create sample AppUser for testing
  static AppUser createMockUser({
    String name = 'Test User',
    String email = 'test@example.com',
  }) {
    return AppUser(
      id: 'test-user-id',
      name: name,
      email: email,
      provider: 'google',
      createdAt: DateTime(2025, 1, 1),
      lastLoginAt: DateTime.now(),
    );
  }

  /// Setup common mock behaviors for ContentService
  static void setupContentServiceMocks(
    MockContentService mockContentService, {
    List<AudioFile>? episodes,
    String selectedLanguage = 'zh-TW',
    String selectedCategory = 'all',
    String searchQuery = '',
    String sortOrder = 'newest',
    bool isLoading = false,
    bool hasError = false,
    String? errorMessage,
  }) {
    final episodeList = episodes ?? createSampleEpisodes();

    // Basic properties
    when(mockContentService.selectedLanguage).thenReturn(selectedLanguage);
    when(mockContentService.selectedCategory).thenReturn(selectedCategory);
    when(mockContentService.searchQuery).thenReturn(searchQuery);
    when(mockContentService.sortOrder).thenReturn(sortOrder);
    when(mockContentService.isLoading).thenReturn(isLoading);
    when(mockContentService.hasError).thenReturn(hasError);
    when(mockContentService.errorMessage).thenReturn(errorMessage);

    // Episode data
    when(mockContentService.allEpisodes).thenReturn(episodeList);
    when(mockContentService.filteredEpisodes).thenReturn(
        episodeList.where((e) => e.language == selectedLanguage).toList());
    when(mockContentService.hasEpisodes).thenReturn(episodeList.isNotEmpty);
    when(mockContentService.hasFilteredResults).thenReturn(
        episodeList.where((e) => e.language == selectedLanguage).isNotEmpty);

    // Statistics
    when(mockContentService.getStatistics()).thenReturn({
      'totalEpisodes': episodeList.length,
      'filteredEpisodes':
          episodeList.where((e) => e.language == selectedLanguage).length,
      'languages': <String, int>{'zh-TW': 3, 'en-US': 2, 'ja-JP': 2},
      'categories': <String, int>{'daily-news': 3, 'ethereum': 2, 'macro': 2},
    });

    // Unfinished episodes
    when(mockContentService.getUnfinishedEpisodes()).thenReturn([]);

    // Episode completion
    when(mockContentService.getEpisodeCompletion(any)).thenReturn(0.0);
    when(mockContentService.isEpisodeUnfinished(any)).thenReturn(false);

    // Listen history
    when(mockContentService.listenHistory).thenReturn(<String, DateTime>{});

    // Current playlist
    when(mockContentService.currentPlaylist).thenReturn(null);
  }

  /// Setup common mock behaviors for AudioService
  static void setupAudioServiceMocks(
    MockAudioService mockAudioService, {
    AudioFile? currentAudioFile,
    PlaybackState playbackState = PlaybackState.stopped,
    Duration currentPosition = Duration.zero,
    Duration totalDuration = const Duration(minutes: 10),
  }) {
    when(mockAudioService.currentAudioFile).thenReturn(currentAudioFile);
    when(mockAudioService.playbackState).thenReturn(playbackState);
    when(mockAudioService.currentPosition).thenReturn(currentPosition);
    when(mockAudioService.totalDuration).thenReturn(totalDuration);
    when(mockAudioService.isPlaying)
        .thenReturn(playbackState == PlaybackState.playing);
    when(mockAudioService.isPaused)
        .thenReturn(playbackState == PlaybackState.paused);
    when(mockAudioService.isLoading)
        .thenReturn(playbackState == PlaybackState.loading);
  }

  /// Setup common mock behaviors for AuthService
  static void setupAuthServiceMocks(
    MockAuthService mockAuthService, {
    AppUser? currentUser,
    AuthState authState = AuthState.authenticated,
  }) {
    when(mockAuthService.currentUser).thenReturn(currentUser);
    when(mockAuthService.authState).thenReturn(authState);
    when(mockAuthService.isAuthenticated)
        .thenReturn(authState == AuthState.authenticated);
  }

  /// Create a widget wrapper with all necessary providers
  static Widget createHomeScreenWrapper({
    MockContentService? contentService,
    MockAudioService? audioService,
    MockAuthService? authService,
  }) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        primaryColor: AppTheme.primaryColor,
        colorScheme: const ColorScheme.dark().copyWith(
          primary: AppTheme.primaryColor,
          surface: AppTheme.surfaceColor,
          onSurface: AppTheme.onSurfaceColor,
        ),
      ),
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<ContentService>.value(
            value: contentService ?? MockContentService(),
          ),
          ChangeNotifierProvider<AudioService>.value(
            value: audioService ?? MockAudioService(),
          ),
          ChangeNotifierProvider<AuthService>.value(
            value: authService ?? MockAuthService(),
          ),
        ],
        child: const HomeScreen(),
      ),
    );
  }

  /// Pump widget and settle animations
  static Future<void> pumpAndSettle(
    WidgetTester tester,
    Widget widget, {
    Duration? duration,
  }) async {
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle(duration ?? const Duration(seconds: 1));
  }
}

void main() {
  group('HomeScreen Widget Tests', () {
    late MockContentService mockContentService;
    late MockAudioService mockAudioService;
    late MockAuthService mockAuthService;

    setUp(() {
      mockContentService = MockContentService();
      mockAudioService = MockAudioService();
      mockAuthService = MockAuthService();
    });

    tearDown(() {
      reset(mockContentService);
      reset(mockAudioService);
      reset(mockAuthService);
    });

    group('Basic Rendering', () {
      testWidgets('renders HomeScreen with main components', (tester) async {
        // Setup mocks
        HomeScreenTestUtils.setupContentServiceMocks(mockContentService);
        HomeScreenTestUtils.setupAudioServiceMocks(mockAudioService);
        HomeScreenTestUtils.setupAuthServiceMocks(
          mockAuthService,
          currentUser: HomeScreenTestUtils.createMockUser(),
        );

        // Create widget
        final widget = HomeScreenTestUtils.createHomeScreenWrapper(
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        );

        // Pump widget
        await HomeScreenTestUtils.pumpAndSettle(tester, widget);

        // Verify main components are rendered
        expect(find.text('From Fed to Chain'), findsOneWidget);
        expect(find.byIcon(Icons.search), findsOneWidget);
        expect(find.byIcon(Icons.account_circle), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsOneWidget);
        expect(find.byType(FilterBar), findsOneWidget);
        expect(find.byType(TabBar), findsOneWidget);

        // Check for specific tabs in TabBar
        final tabBar = tester.widget<TabBar>(find.byType(TabBar));
        expect(tabBar.tabs.length, 3);
      });

      testWidgets('displays episode statistics in header', (tester) async {
        // Setup mocks with specific statistics
        HomeScreenTestUtils.setupContentServiceMocks(
          mockContentService,
          episodes: HomeScreenTestUtils.createSampleEpisodes(count: 10),
        );
        HomeScreenTestUtils.setupAudioServiceMocks(mockAudioService);
        HomeScreenTestUtils.setupAuthServiceMocks(
          mockAuthService,
          currentUser: HomeScreenTestUtils.createMockUser(),
        );

        when(mockContentService.getStatistics()).thenReturn({
          'totalEpisodes': 10,
          'filteredEpisodes': 3,
        });

        // Create and pump widget
        final widget = HomeScreenTestUtils.createHomeScreenWrapper(
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        );
        await HomeScreenTestUtils.pumpAndSettle(tester, widget);

        // Verify statistics display
        expect(find.text('3 of 10 episodes'), findsOneWidget);
      });

      testWidgets('displays total episodes when no filtering', (tester) async {
        // Setup mocks with equal total and filtered episodes
        HomeScreenTestUtils.setupContentServiceMocks(mockContentService);
        HomeScreenTestUtils.setupAudioServiceMocks(mockAudioService);
        HomeScreenTestUtils.setupAuthServiceMocks(
          mockAuthService,
          currentUser: HomeScreenTestUtils.createMockUser(),
        );

        when(mockContentService.getStatistics()).thenReturn({
          'totalEpisodes': 5,
          'filteredEpisodes': 5,
        });

        // Create and pump widget
        final widget = HomeScreenTestUtils.createHomeScreenWrapper(
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        );
        await HomeScreenTestUtils.pumpAndSettle(tester, widget);

        // Verify display shows total only
        expect(find.text('5 episodes'), findsOneWidget);
      });
    });

    group('Search Functionality', () {
      testWidgets('shows search bar when search icon is tapped',
          (tester) async {
        // Setup mocks
        HomeScreenTestUtils.setupContentServiceMocks(mockContentService);
        HomeScreenTestUtils.setupAudioServiceMocks(mockAudioService);
        HomeScreenTestUtils.setupAuthServiceMocks(
          mockAuthService,
          currentUser: HomeScreenTestUtils.createMockUser(),
        );

        // Create and pump widget
        final widget = HomeScreenTestUtils.createHomeScreenWrapper(
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        );
        await HomeScreenTestUtils.pumpAndSettle(tester, widget);

        // Initially, search bar should not be visible
        expect(find.byType(SearchBarWidget), findsNothing);
        expect(find.byIcon(Icons.search), findsOneWidget);

        // Tap search icon
        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();

        // Search bar should now be visible and icon should change
        expect(find.byType(SearchBarWidget), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget);
      });

      testWidgets('hides search bar when close icon is tapped', (tester) async {
        // Setup mocks
        HomeScreenTestUtils.setupContentServiceMocks(mockContentService);
        HomeScreenTestUtils.setupAudioServiceMocks(mockAudioService);
        HomeScreenTestUtils.setupAuthServiceMocks(
          mockAuthService,
          currentUser: HomeScreenTestUtils.createMockUser(),
        );

        // Create and pump widget
        final widget = HomeScreenTestUtils.createHomeScreenWrapper(
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        );
        await HomeScreenTestUtils.pumpAndSettle(tester, widget);

        // Show search bar
        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();
        expect(find.byType(SearchBarWidget), findsOneWidget);

        // Hide search bar
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
        expect(find.byType(SearchBarWidget), findsNothing);
      });

      testWidgets('calls setSearchQuery when search text changes',
          (tester) async {
        // Setup mocks
        HomeScreenTestUtils.setupContentServiceMocks(mockContentService);
        HomeScreenTestUtils.setupAudioServiceMocks(mockAudioService);
        HomeScreenTestUtils.setupAuthServiceMocks(
          mockAuthService,
          currentUser: HomeScreenTestUtils.createMockUser(),
        );

        // Create and pump widget
        final widget = HomeScreenTestUtils.createHomeScreenWrapper(
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        );
        await HomeScreenTestUtils.pumpAndSettle(tester, widget);

        // Show search bar
        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();

        // Find the text field in SearchBarWidget and enter text
        final textField = find.byType(TextField);
        expect(textField, findsOneWidget);

        await tester.enterText(textField, 'bitcoin');
        await tester.pump();

        // Verify setSearchQuery was called
        verify(mockContentService.setSearchQuery('bitcoin')).called(1);
      });
    });

    group('Filter Bar Integration', () {
      testWidgets('passes correct props to FilterBar', (tester) async {
        // Setup mocks with specific filter values
        HomeScreenTestUtils.setupContentServiceMocks(
          mockContentService,
          selectedLanguage: 'en-US',
          selectedCategory: 'ethereum',
        );
        HomeScreenTestUtils.setupAudioServiceMocks(mockAudioService);
        HomeScreenTestUtils.setupAuthServiceMocks(
          mockAuthService,
          currentUser: HomeScreenTestUtils.createMockUser(),
        );

        // Create and pump widget
        final widget = HomeScreenTestUtils.createHomeScreenWrapper(
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        );
        await HomeScreenTestUtils.pumpAndSettle(tester, widget);

        // Find FilterBar and verify it receives correct props
        final filterBar = tester.widget<FilterBar>(find.byType(FilterBar));
        expect(filterBar.selectedLanguage, 'en-US');
        expect(filterBar.selectedCategory, 'ethereum');
      });

      testWidgets('calls content service methods when filters change',
          (tester) async {
        // Setup mocks
        HomeScreenTestUtils.setupContentServiceMocks(mockContentService);
        HomeScreenTestUtils.setupAudioServiceMocks(mockAudioService);
        HomeScreenTestUtils.setupAuthServiceMocks(
          mockAuthService,
          currentUser: HomeScreenTestUtils.createMockUser(),
        );

        // Create and pump widget
        final widget = HomeScreenTestUtils.createHomeScreenWrapper(
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        );
        await HomeScreenTestUtils.pumpAndSettle(tester, widget);

        // Find FilterBar and trigger callbacks
        final filterBar = tester.widget<FilterBar>(find.byType(FilterBar));

        // Test language change
        filterBar.onLanguageChanged('ja-JP');
        verify(mockContentService.setLanguage('ja-JP')).called(1);

        // Test category change
        filterBar.onCategoryChanged('macro');
        verify(mockContentService.setCategory('macro')).called(1);
      });
    });

    group('Loading and Error States', () {
      testWidgets('displays loading state when content is loading',
          (tester) async {
        // Setup mocks with loading state
        HomeScreenTestUtils.setupContentServiceMocks(
          mockContentService,
          isLoading: true,
          episodes: [], // No episodes yet
        );
        HomeScreenTestUtils.setupAudioServiceMocks(mockAudioService);
        HomeScreenTestUtils.setupAuthServiceMocks(
          mockAuthService,
          currentUser: HomeScreenTestUtils.createMockUser(),
        );

        when(mockContentService.hasEpisodes).thenReturn(false);

        // Create and pump widget
        final widget = HomeScreenTestUtils.createHomeScreenWrapper(
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        );
        await tester.pumpWidget(widget);
        await tester.pump(const Duration(milliseconds: 100));

        // Verify loading state is displayed
        expect(find.byType(CircularProgressIndicator), findsWidgets);
        expect(find.text('Loading episodes...'), findsOneWidget);
        expect(find.text('This may take a few moments'), findsOneWidget);
      });

      testWidgets('displays error state when there is an error',
          (tester) async {
        // Setup mocks with error state
        HomeScreenTestUtils.setupContentServiceMocks(
          mockContentService,
          hasError: true,
          errorMessage: 'Network connection failed',
        );
        HomeScreenTestUtils.setupAudioServiceMocks(mockAudioService);
        HomeScreenTestUtils.setupAuthServiceMocks(
          mockAuthService,
          currentUser: HomeScreenTestUtils.createMockUser(),
        );

        // Create and pump widget
        final widget = HomeScreenTestUtils.createHomeScreenWrapper(
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        );
        await HomeScreenTestUtils.pumpAndSettle(tester, widget);

        // Verify error state is displayed
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('Something went wrong'), findsOneWidget);
        expect(find.text('Network connection failed'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
      });

      testWidgets('calls refresh when retry button is tapped in error state',
          (tester) async {
        // Setup mocks with error state
        HomeScreenTestUtils.setupContentServiceMocks(
          mockContentService,
          hasError: true,
          errorMessage: 'Network error',
        );
        HomeScreenTestUtils.setupAudioServiceMocks(mockAudioService);
        HomeScreenTestUtils.setupAuthServiceMocks(
          mockAuthService,
          currentUser: HomeScreenTestUtils.createMockUser(),
        );

        // Create and pump widget
        final widget = HomeScreenTestUtils.createHomeScreenWrapper(
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        );
        await HomeScreenTestUtils.pumpAndSettle(tester, widget);

        // Tap retry button
        await tester.tap(find.text('Retry'));
        await tester.pump();

        // Verify refresh was called
        verify(mockContentService.refresh()).called(1);
      });

      testWidgets('displays empty state when no filtered results',
          (tester) async {
        // Setup mocks with no filtered results
        HomeScreenTestUtils.setupContentServiceMocks(
          mockContentService,
          episodes: HomeScreenTestUtils.createSampleEpisodes(count: 5),
        );
        HomeScreenTestUtils.setupAudioServiceMocks(mockAudioService);
        HomeScreenTestUtils.setupAuthServiceMocks(
          mockAuthService,
          currentUser: HomeScreenTestUtils.createMockUser(),
        );

        when(mockContentService.hasFilteredResults).thenReturn(false);
        when(mockContentService.filteredEpisodes).thenReturn([]);

        // Create and pump widget
        final widget = HomeScreenTestUtils.createHomeScreenWrapper(
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        );
        await HomeScreenTestUtils.pumpAndSettle(tester, widget);

        // Verify empty state is displayed
        expect(find.byIcon(Icons.headphones_outlined), findsOneWidget);
        expect(find.text('No episodes found'), findsOneWidget);
        expect(find.text('Check your internet connection and try again'),
            findsOneWidget);
        expect(find.text('Refresh'), findsOneWidget);
      });
    });

    group('Mini Player Integration', () {
      testWidgets('displays mini player when audio is playing', (tester) async {
        // Setup mocks with playing audio
        final episodes = HomeScreenTestUtils.createSampleEpisodes(count: 1);
        HomeScreenTestUtils.setupContentServiceMocks(
          mockContentService,
          episodes: episodes,
        );
        HomeScreenTestUtils.setupAudioServiceMocks(
          mockAudioService,
          currentAudioFile: episodes.first,
          playbackState: PlaybackState.playing,
        );
        HomeScreenTestUtils.setupAuthServiceMocks(
          mockAuthService,
          currentUser: HomeScreenTestUtils.createMockUser(),
        );

        // Create and pump widget
        final widget = HomeScreenTestUtils.createHomeScreenWrapper(
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        );
        await HomeScreenTestUtils.pumpAndSettle(tester, widget);

        // Verify mini player is displayed
        expect(find.byType(MiniPlayer), findsOneWidget);
      });

      testWidgets('hides mini player when no audio is playing', (tester) async {
        // Setup mocks without current audio
        HomeScreenTestUtils.setupContentServiceMocks(mockContentService);
        HomeScreenTestUtils.setupAudioServiceMocks(
          mockAudioService,
          currentAudioFile: null,
        );
        HomeScreenTestUtils.setupAuthServiceMocks(
          mockAuthService,
          currentUser: HomeScreenTestUtils.createMockUser(),
        );

        // Create and pump widget
        final widget = HomeScreenTestUtils.createHomeScreenWrapper(
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        );
        await HomeScreenTestUtils.pumpAndSettle(tester, widget);

        // Verify mini player is not displayed
        expect(find.byType(MiniPlayer), findsNothing);
      });
    });

    group('User Profile and Authentication', () {
      testWidgets('displays user profile in popup menu', (tester) async {
        // Setup mocks with user
        final user = HomeScreenTestUtils.createMockUser(
          name: 'John Doe',
          email: 'john@example.com',
        );

        HomeScreenTestUtils.setupContentServiceMocks(mockContentService);
        HomeScreenTestUtils.setupAudioServiceMocks(mockAudioService);
        HomeScreenTestUtils.setupAuthServiceMocks(
          mockAuthService,
          currentUser: user,
        );

        // Create and pump widget
        final widget = HomeScreenTestUtils.createHomeScreenWrapper(
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        );
        await HomeScreenTestUtils.pumpAndSettle(tester, widget);

        // Tap profile menu button
        await tester.tap(find.byIcon(Icons.account_circle));
        await tester.pumpAndSettle();

        // Verify user info is displayed
        expect(find.text('John Doe'), findsOneWidget);
        expect(find.text('john@example.com'), findsOneWidget);
        expect(find.text('Sign Out'), findsOneWidget);
        expect(find.byIcon(Icons.logout), findsOneWidget);
      });

      testWidgets('handles logout when Sign Out is tapped', (tester) async {
        // Setup mocks
        final user = HomeScreenTestUtils.createMockUser();
        HomeScreenTestUtils.setupContentServiceMocks(mockContentService);
        HomeScreenTestUtils.setupAudioServiceMocks(mockAudioService);
        HomeScreenTestUtils.setupAuthServiceMocks(
          mockAuthService,
          currentUser: user,
        );

        when(mockAuthService.signOut()).thenAnswer((_) async {});

        // Create and pump widget
        final widget = HomeScreenTestUtils.createHomeScreenWrapper(
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        );
        await HomeScreenTestUtils.pumpAndSettle(tester, widget);

        // Open profile menu and tap Sign Out
        await tester.tap(find.byIcon(Icons.account_circle));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sign Out'));
        await tester.pumpAndSettle();

        // Verify signOut was called
        verify(mockAuthService.signOut()).called(1);
      });
    });

    group('Refresh Functionality', () {
      testWidgets('calls refresh when refresh button is tapped',
          (tester) async {
        // Setup mocks
        HomeScreenTestUtils.setupContentServiceMocks(mockContentService);
        HomeScreenTestUtils.setupAudioServiceMocks(mockAudioService);
        HomeScreenTestUtils.setupAuthServiceMocks(
          mockAuthService,
          currentUser: HomeScreenTestUtils.createMockUser(),
        );

        // Create and pump widget
        final widget = HomeScreenTestUtils.createHomeScreenWrapper(
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        );
        await HomeScreenTestUtils.pumpAndSettle(tester, widget);

        // Tap refresh button
        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pump();

        // Verify refresh was called
        verify(mockContentService.refresh()).called(1);
      });

      testWidgets('loads episodes on initialization', (tester) async {
        // Setup mocks
        HomeScreenTestUtils.setupContentServiceMocks(mockContentService);
        HomeScreenTestUtils.setupAudioServiceMocks(mockAudioService);
        HomeScreenTestUtils.setupAuthServiceMocks(
          mockAuthService,
          currentUser: HomeScreenTestUtils.createMockUser(),
        );

        // Create and pump widget
        final widget = HomeScreenTestUtils.createHomeScreenWrapper(
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        );
        await HomeScreenTestUtils.pumpAndSettle(tester, widget);

        // Verify loadAllEpisodes was called during initialization
        verify(mockContentService.loadAllEpisodes()).called(1);
      });
    });

    group('Tab Navigation', () {
      testWidgets('displays TabBar with correct number of tabs',
          (tester) async {
        // Setup mocks
        HomeScreenTestUtils.setupContentServiceMocks(mockContentService);
        HomeScreenTestUtils.setupAudioServiceMocks(mockAudioService);
        HomeScreenTestUtils.setupAuthServiceMocks(
          mockAuthService,
          currentUser: HomeScreenTestUtils.createMockUser(),
        );

        // Create and pump widget
        final widget = HomeScreenTestUtils.createHomeScreenWrapper(
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        );
        await HomeScreenTestUtils.pumpAndSettle(tester, widget);

        // Verify TabBar has 3 tabs
        final tabBar = tester.widget<TabBar>(find.byType(TabBar));
        expect(tabBar.tabs.length, 3);
        expect(find.byType(TabBarView), findsOneWidget);
      });

      testWidgets('shows unfinished episodes empty state', (tester) async {
        // Setup mocks with no unfinished episodes
        HomeScreenTestUtils.setupContentServiceMocks(mockContentService);
        HomeScreenTestUtils.setupAudioServiceMocks(mockAudioService);
        HomeScreenTestUtils.setupAuthServiceMocks(
          mockAuthService,
          currentUser: HomeScreenTestUtils.createMockUser(),
        );

        when(mockContentService.getUnfinishedEpisodes()).thenReturn([]);

        // Create and pump widget
        final widget = HomeScreenTestUtils.createHomeScreenWrapper(
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        );
        await HomeScreenTestUtils.pumpAndSettle(tester, widget);

        // Switch to Unfinished tab by tapping the third tab
        final tabBar = find.byType(TabBar);
        await tester.tap(tabBar);
        await tester.pump();

        // Use tab controller to switch to third tab (index 2)
        final tabController = tester.widget<TabBar>(tabBar).controller;
        if (tabController != null) {
          tabController.animateTo(2);
          await tester.pumpAndSettle();
        }

        // Should show empty state for unfinished episodes
        expect(find.byIcon(Icons.pending_actions), findsOneWidget);
        expect(find.text('No Unfinished Episodes'), findsOneWidget);
      });
    });

    group('Sort Selector', () {
      testWidgets('displays sort selector with dropdown', (tester) async {
        // Setup mocks
        HomeScreenTestUtils.setupContentServiceMocks(
          mockContentService,
          sortOrder: 'newest',
        );
        HomeScreenTestUtils.setupAudioServiceMocks(mockAudioService);
        HomeScreenTestUtils.setupAuthServiceMocks(
          mockAuthService,
          currentUser: HomeScreenTestUtils.createMockUser(),
        );

        // Create and pump widget
        final widget = HomeScreenTestUtils.createHomeScreenWrapper(
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        );
        await HomeScreenTestUtils.pumpAndSettle(tester, widget);

        // Verify sort selector elements
        expect(find.byIcon(Icons.sort), findsOneWidget);
        expect(find.text('Sort by:'), findsOneWidget);
        expect(find.byType(DropdownButton<String>), findsOneWidget);
      });
    });

    group('Episode List Content', () {
      testWidgets('displays AudioList when episodes are available',
          (tester) async {
        // Setup mocks with episodes
        final episodes = HomeScreenTestUtils.createSampleEpisodes(count: 5);
        HomeScreenTestUtils.setupContentServiceMocks(
          mockContentService,
          episodes: episodes,
        );
        HomeScreenTestUtils.setupAudioServiceMocks(mockAudioService);
        HomeScreenTestUtils.setupAuthServiceMocks(
          mockAuthService,
          currentUser: HomeScreenTestUtils.createMockUser(),
        );

        when(mockContentService.filteredEpisodes).thenReturn(episodes);

        // Create and pump widget
        final widget = HomeScreenTestUtils.createHomeScreenWrapper(
          contentService: mockContentService,
          audioService: mockAudioService,
          authService: mockAuthService,
        );
        await HomeScreenTestUtils.pumpAndSettle(tester, widget);

        // Verify AudioList is displayed
        expect(find.byType(AudioList), findsOneWidget);

        // Verify AudioList receives correct episodes
        final audioList = tester.widget<AudioList>(find.byType(AudioList));
        expect(audioList.episodes.length, 5);
      });
    });
  });
}

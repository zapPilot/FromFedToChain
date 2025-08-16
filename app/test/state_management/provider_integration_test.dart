import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';

import 'package:from_fed_to_chain_app/screens/home_screen.dart';
import 'package:from_fed_to_chain_app/screens/player_screen.dart';
import 'package:from_fed_to_chain_app/widgets/mini_player.dart';
import 'package:from_fed_to_chain_app/widgets/audio_list.dart';
import 'package:from_fed_to_chain_app/widgets/filter_bar.dart';
import 'package:from_fed_to_chain_app/services/audio_service.dart';
import 'package:from_fed_to_chain_app/services/content_service.dart';
import 'package:from_fed_to_chain_app/services/auth/auth_service.dart';
import '../test_utils.dart';
import '../helpers/widget_test_helpers.dart';
import '../helpers/service_mocks.dart';
import '../helpers/service_mocks.mocks.dart';

void main() {
  group('Provider Integration Tests', () {
    late MockContentService mockContentService;
    late MockAudioService mockAudioService;
    late MockAuthService mockAuthService;

    setUp(() {
      mockContentService = MockContentService();
      mockAudioService = MockAudioService();
      mockAuthService = MockAuthService();
    });

    group('ContentService Provider Integration', () {
      testWidgets('HomeScreen responds to ContentService state changes', (tester) async {
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const HomeScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Initial state - loading should show loading indicator
        when(mockContentService.isLoading).thenReturn(true);
        when(mockContentService.hasEpisodes).thenReturn(false);
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsWidgets);

        // State change - success with data
        WidgetTestHelpers.setupMockDataForTesting(mockContentService);
        when(mockContentService.isLoading).thenReturn(false);
        when(mockContentService.hasEpisodes).thenReturn(true);
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.byType(FilterBar), findsOneWidget);
        expect(find.byType(AudioList), findsOneWidget);

        // State change - error
        when(mockContentService.hasError).thenReturn(true);
        when(mockContentService.errorMessage).thenReturn('Network error');
        when(mockContentService.hasEpisodes).thenReturn(false);
        await tester.pump();

        expect(find.text('Something went wrong'), findsWidgets);
        expect(find.text('Network error'), findsWidgets);
      });

      testWidgets('FilterBar responds to ContentService filter changes', (tester) async {
        WidgetTestHelpers.setupMockDataForTesting(mockContentService);

        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const HomeScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Test language filter change
        when(mockContentService.selectedLanguage).thenReturn('en-US');
        await tester.pump();

        // Test category filter change
        when(mockContentService.selectedCategory).thenReturn('ethereum');
        await tester.pump();

        // Test search query change
        when(mockContentService.searchQuery).thenReturn('bitcoin');
        await tester.pump();
      });

      testWidgets('AudioList updates when ContentService episodes change', (tester) async {
        // Start with empty episodes
        when(mockContentService.filteredEpisodes).thenReturn([]);
        when(mockContentService.hasFilteredResults).thenReturn(false);

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

        // Add episodes
        final testEpisodes = [
          TestUtils.createSampleAudioFile(id: 'episode-1', title: 'Test Episode 1'),
          TestUtils.createSampleAudioFile(id: 'episode-2', title: 'Test Episode 2'),
        ];

        when(mockContentService.filteredEpisodes).thenReturn(testEpisodes);
        when(mockContentService.hasFilteredResults).thenReturn(true);
        await tester.pump();

        // Verify episodes are displayed
        expect(find.text('Test Episode 1'), findsOneWidget);
        expect(find.text('Test Episode 2'), findsOneWidget);
      });
    });

    group('AudioService Provider Integration', () {
      testWidgets('MiniPlayer appears when AudioService starts playing', (tester) async {
        WidgetTestHelpers.setupMockDataForTesting(mockContentService);

        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const HomeScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Initially no audio playing
        expect(find.byType(MiniPlayer), findsNothing);

        // Start playing audio
        final testAudio = TestUtils.createSampleAudioFile();
        when(mockAudioService.currentAudioFile).thenReturn(testAudio);
        when(mockAudioService.playbackState).thenReturn(PlaybackState.playing);
        await tester.pump();

        // Verify MiniPlayer appears
        expect(find.byType(MiniPlayer), findsOneWidget);

        // Stop audio
        when(mockAudioService.currentAudioFile).thenReturn(null);
        when(mockAudioService.playbackState).thenReturn(PlaybackState.stopped);
        await tester.pump();

        // Verify MiniPlayer disappears
        expect(find.byType(MiniPlayer), findsNothing);
      });

      testWidgets('PlayerScreen updates with AudioService playback state changes', (tester) async {
        final testAudio = TestUtils.createSampleAudioFile();
        when(mockAudioService.currentAudioFile).thenReturn(testAudio);

        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const PlayerScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Test playing state
        when(mockAudioService.playbackState).thenReturn(PlaybackState.playing);
        when(mockAudioService.isPlaying).thenReturn(true);
        await tester.pump();

        expect(find.text('Playing'), findsWidgets);

        // Test paused state
        when(mockAudioService.playbackState).thenReturn(PlaybackState.paused);
        when(mockAudioService.isPlaying).thenReturn(false);
        await tester.pump();

        expect(find.text('Paused'), findsWidgets);

        // Test loading state
        when(mockAudioService.playbackState).thenReturn(PlaybackState.loading);
        await tester.pump();

        expect(find.text('Loading...'), findsWidgets);

        // Test error state
        when(mockAudioService.playbackState).thenReturn(PlaybackState.error);
        await tester.pump();

        expect(find.text('Error'), findsWidgets);
      });

      testWidgets('PlayerScreen progress updates with AudioService position changes', (tester) async {
        final testAudio = TestUtils.createSampleAudioFile();
        when(mockAudioService.currentAudioFile).thenReturn(testAudio);
        when(mockAudioService.playbackState).thenReturn(PlaybackState.playing);

        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const PlayerScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Test position update
        when(mockAudioService.currentPosition).thenReturn(const Duration(minutes: 2));
        when(mockAudioService.totalDuration).thenReturn(const Duration(minutes: 10));
        when(mockAudioService.progress).thenReturn(0.2);
        when(mockAudioService.formattedCurrentPosition).thenReturn('2:00');
        when(mockAudioService.formattedTotalDuration).thenReturn('10:00');
        await tester.pump();

        expect(find.text('2:00'), findsWidgets);
        expect(find.text('10:00'), findsWidgets);

        // Test another position update
        when(mockAudioService.currentPosition).thenReturn(const Duration(minutes: 5));
        when(mockAudioService.progress).thenReturn(0.5);
        when(mockAudioService.formattedCurrentPosition).thenReturn('5:00');
        await tester.pump();

        expect(find.text('5:00'), findsWidgets);
      });

      testWidgets('MiniPlayer updates with AudioService playback speed changes', (tester) async {
        WidgetTestHelpers.setupMockDataForTesting(mockContentService);
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

        // Test speed change
        when(mockAudioService.playbackSpeed).thenReturn(1.5);
        await tester.pump();

        // Verify MiniPlayer is still present with updated speed
        expect(find.byType(MiniPlayer), findsOneWidget);

        // Test another speed change
        when(mockAudioService.playbackSpeed).thenReturn(2.0);
        await tester.pump();

        expect(find.byType(MiniPlayer), findsOneWidget);
      });
    });

    group('AuthService Provider Integration', () {
      testWidgets('UI responds to AuthService authentication state changes', (tester) async {
        WidgetTestHelpers.setupMockDataForTesting(mockContentService);

        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const HomeScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Test sign in
        when(mockAuthService.isAuthenticated).thenReturn(true);
        await tester.pump();

        // Test sign out
        when(mockAuthService.isAuthenticated).thenReturn(false);
        await tester.pump();

        // Test loading state
        when(mockAuthService.isLoading).thenReturn(true);
        await tester.pump();
      });
    });

    group('Multi-Service Provider Integration', () {
      testWidgets('Complex interactions between multiple services work correctly', (tester) async {
        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: const HomeScreen(),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Step 1: Load content
        WidgetTestHelpers.setupMockDataForTesting(mockContentService);
        when(mockContentService.isLoading).thenReturn(false);
        when(mockContentService.hasEpisodes).thenReturn(true);
        await tester.pump();

        expect(find.byType(AudioList), findsOneWidget);

        // Step 2: Start playing audio
        final testAudio = TestUtils.createSampleAudioFile();
        when(mockAudioService.currentAudioFile).thenReturn(testAudio);
        when(mockAudioService.playbackState).thenReturn(PlaybackState.playing);
        await tester.pump();

        expect(find.byType(MiniPlayer), findsOneWidget);

        // Step 3: Apply filters while audio is playing
        when(mockContentService.selectedLanguage).thenReturn('en-US');
        await tester.pump();

        // Both MiniPlayer and filtered content should be visible
        expect(find.byType(MiniPlayer), findsOneWidget);
        expect(find.byType(AudioList), findsOneWidget);

        // Step 4: Sign in user while audio is playing and filters are applied
        when(mockAuthService.isAuthenticated).thenReturn(true);
        await tester.pump();

        // All states should coexist
        expect(find.byType(MiniPlayer), findsOneWidget);
        expect(find.byType(AudioList), findsOneWidget);
      });

      testWidgets('Provider dependency injection works correctly', (tester) async {
        // Test that all providers are correctly injected and accessible
        late BuildContext capturedContext;

        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: Builder(
              builder: (context) {
                capturedContext = context;
                return const HomeScreen();
              },
            ),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Verify all services are accessible through Provider
        final contentService = Provider.of<ContentService>(capturedContext, listen: false);
        final audioService = Provider.of<AudioService>(capturedContext, listen: false);
        final authService = Provider.of<AuthService>(capturedContext, listen: false);

        expect(contentService, isA<MockContentService>());
        expect(audioService, isA<MockAudioService>());
        expect(authService, isA<MockAuthService>());
      });

      testWidgets('Provider context watching works correctly', (tester) async {
        int contentServiceNotifications = 0;
        int audioServiceNotifications = 0;

        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: Builder(
              builder: (context) {
                // Watch for changes
                context.watch<ContentService>();
                context.watch<AudioService>();
                
                return const HomeScreen();
              },
            ),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Trigger content service change
        when(mockContentService.isLoading).thenReturn(false);
        await tester.pump();

        // Trigger audio service change
        when(mockAudioService.isPlaying).thenReturn(true);
        await tester.pump();
      });

      testWidgets('Provider.of without context works correctly', (tester) async {
        late ContentService contentService;
        late AudioService audioService;
        late AuthService authService;

        await tester.pumpWidget(
          WidgetTestHelpers.createTestWrapper(
            child: Builder(
              builder: (context) {
                contentService = Provider.of<ContentService>(context, listen: false);
                audioService = Provider.of<AudioService>(context, listen: false);
                authService = Provider.of<AuthService>(context, listen: false);
                return const HomeScreen();
              },
            ),
            contentService: mockContentService,
            audioService: mockAudioService,
            authService: mockAuthService,
          ),
        );

        // Verify services are the same instances we provided
        expect(contentService, equals(mockContentService));
        expect(audioService, equals(mockAudioService));
        expect(authService, equals(mockAuthService));
      });
    });

    group('Consumer Widget Integration', () {
      testWidgets('Consumer widgets rebuild when provider state changes', (tester) async {
        int contentConsumerBuilds = 0;
        int audioConsumerBuilds = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider<ContentService>.value(value: mockContentService),
                ChangeNotifierProvider<AudioService>.value(value: mockAudioService),
                ChangeNotifierProvider<AuthService>.value(value: mockAuthService),
              ],
              child: Scaffold(
                body: Column(
                  children: [
                    Consumer<ContentService>(
                      builder: (context, contentService, child) {
                        contentConsumerBuilds++;
                        return Text('Content builds: $contentConsumerBuilds');
                      },
                    ),
                    Consumer<AudioService>(
                      builder: (context, audioService, child) {
                        audioConsumerBuilds++;
                        return Text('Audio builds: $audioConsumerBuilds');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // Initial build
        expect(find.text('Content builds: 1'), findsOneWidget);
        expect(find.text('Audio builds: 1'), findsOneWidget);

        // Trigger content service change
        when(mockContentService.isLoading).thenReturn(true);
        await tester.pump();

        expect(find.text('Content builds: 2'), findsOneWidget);
        expect(find.text('Audio builds: 1'), findsOneWidget); // Should not rebuild

        // Trigger audio service change
        when(mockAudioService.isPlaying).thenReturn(true);
        await tester.pump();

        expect(find.text('Content builds: 2'), findsOneWidget); // Should not rebuild
        expect(find.text('Audio builds: 2'), findsOneWidget);
      });

      testWidgets('Selector widgets optimize rebuilds correctly', (tester) async {
        int selectorBuilds = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider<ContentService>.value(value: mockContentService),
                ChangeNotifierProvider<AudioService>.value(value: mockAudioService),
                ChangeNotifierProvider<AuthService>.value(value: mockAuthService),
              ],
              child: Scaffold(
                body: Selector<ContentService, bool>(
                  selector: (context, contentService) => contentService.isLoading,
                  builder: (context, isLoading, child) {
                    selectorBuilds++;
                    return Text('Loading: $isLoading, Builds: $selectorBuilds');
                  },
                ),
              ),
            ),
          ),
        );

        // Initial build
        expect(find.textContaining('Builds: 1'), findsOneWidget);

        // Change loading state
        when(mockContentService.isLoading).thenReturn(true);
        await tester.pump();

        expect(find.textContaining('Builds: 2'), findsOneWidget);

        // Change unrelated property (should not rebuild)
        when(mockContentService.selectedLanguage).thenReturn('ja-JP');
        await tester.pump();

        expect(find.textContaining('Builds: 2'), findsOneWidget); // Should not rebuild
      });
    });
  });
}
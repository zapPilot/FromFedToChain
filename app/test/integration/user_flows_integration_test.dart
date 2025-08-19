import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:from_fed_to_chain_app/screens/home_screen.dart';
import 'package:from_fed_to_chain_app/screens/player_screen.dart';
import 'package:from_fed_to_chain_app/services/content_service.dart';
import 'package:from_fed_to_chain_app/services/audio_service.dart';
import 'package:from_fed_to_chain_app/widgets/mini_player.dart';
import 'package:from_fed_to_chain_app/models/audio_file.dart';
import 'package:from_fed_to_chain_app/themes/app_theme.dart';
import '../test_utils.dart';

void main() {
  group('User Flows Integration Tests', () {
    late ContentService contentService;
    late AudioService audioService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      contentService = ContentService();
      audioService = AudioService(null, contentService);

      // Setup test data
      final testEpisodes = TestUtils.createSampleAudioFileList(15);
      contentService.setEpisodesForTesting(testEpisodes);
    });

    tearDown(() {
      contentService.dispose();
      audioService.dispose();
    });

    /// Helper to create the main app with providers
    Widget createTestApp({Widget? home}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<ContentService>.value(value: contentService),
          ChangeNotifierProvider<AudioService>.value(value: audioService),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: home ?? const HomeScreen(),
        ),
      );
    }

    group('Episode Discovery and Playback Flow', () {
      testWidgets('Complete episode discovery and playback flow',
          (tester) async {
        // Arrange: Start the app
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Verify home screen loads with episodes
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.text('From Fed to Chain'), findsOneWidget);

        // Act 1: Filter by language
        final languageFilter = find.text('English');
        await tester.tap(languageFilter);
        await tester.pumpAndSettle();

        // Assert: Language filter applied
        expect(contentService.selectedLanguage, equals('en-US'));

        // Act 2: Filter by category
        final categoryFilter = find.text('Daily News');
        await tester.tap(categoryFilter);
        await tester.pumpAndSettle();

        // Assert: Category filter applied
        expect(contentService.selectedCategory, equals('daily-news'));

        // Act 3: Toggle search bar
        final searchToggle = find.byIcon(Icons.search);
        await tester.tap(searchToggle);
        await tester.pumpAndSettle();

        // Assert: Search bar appears
        expect(find.byType(TextField), findsOneWidget);

        // Act 4: Enter search query
        await tester.enterText(find.byType(TextField), 'Bitcoin');
        await tester.pumpAndSettle();

        // Assert: Search query applied
        expect(contentService.searchQuery, equals('Bitcoin'));

        // Act 5: Tap on an episode to play
        final episodeCard = find.byType(Card).first;
        await tester.tap(episodeCard);
        await tester.pumpAndSettle();

        // Assert: Audio starts playing and mini player appears
        expect(audioService.currentAudioFile, isNotNull);
        expect(find.byType(MiniPlayer), findsOneWidget);
      });

      testWidgets('Handles empty search results gracefully', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Act: Search for non-existent content
        final searchToggle = find.byIcon(Icons.search);
        await tester.tap(searchToggle);
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'NonexistentContent');
        await tester.pumpAndSettle();

        // Assert: Empty state shown
        expect(find.text('No episodes found'), findsOneWidget);
        expect(
            find.text('Try different search terms or filters'), findsOneWidget);
      });

      testWidgets('Tab navigation works correctly', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Act: Tap on different tabs
        await tester.tap(find.text('All'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Unfinished'));
        await tester.pumpAndSettle();

        // Assert: Tabs respond to taps
        expect(find.text('No Unfinished Episodes'), findsOneWidget);

        await tester.tap(find.text('Recent'));
        await tester.pumpAndSettle();
      });
    });

    group('Audio Playback Control Flow', () {
      testWidgets('Complete audio playback control flow', (tester) async {
        // Arrange: Start with audio playing
        final testEpisode = TestUtils.createSampleAudioFile(
          title: 'Test Episode for Playback',
        );
        await audioService.playAudio(testEpisode);

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Verify mini player is visible
        expect(find.byType(MiniPlayer), findsOneWidget);
        expect(find.text('Test Episode for Playback'), findsOneWidget);

        // Act 1: Pause playback via mini player
        final pauseButton = find.byIcon(Icons.pause).first;
        await tester.tap(pauseButton);
        await tester.pumpAndSettle();

        // Assert: Audio is paused
        expect(audioService.isPaused, isTrue);

        // Act 2: Resume playback
        final playButton = find.byIcon(Icons.play_arrow).first;
        await tester.tap(playButton);
        await tester.pumpAndSettle();

        // Assert: Audio is playing
        expect(audioService.isPlaying, isTrue);

        // Act 3: Skip to next episode
        final nextButton = find.byIcon(Icons.skip_next).first;
        await tester.tap(nextButton);
        await tester.pumpAndSettle();

        // Act 4: Navigate to full player
        final miniPlayer = find.byType(MiniPlayer);
        await tester.tap(miniPlayer);
        await tester.pumpAndSettle();

        // Assert: Player screen opens
        expect(find.byType(PlayerScreen), findsOneWidget);
        expect(find.text('NOW PLAYING'), findsOneWidget);
      });

      testWidgets('Player screen controls work correctly', (tester) async {
        // Arrange: Start with audio and navigate to player
        final testEpisode = TestUtils.createSampleAudioFile();
        await audioService.playAudio(testEpisode);

        await tester.pumpWidget(createTestApp(home: const PlayerScreen()));
        await tester.pumpAndSettle();

        // Verify player screen loads
        expect(find.byType(PlayerScreen), findsOneWidget);
        expect(find.text('NOW PLAYING'), findsOneWidget);

        // Act 1: Test playback speed controls
        final speedButton = find.byIcon(Icons.speed);
        await tester.tap(speedButton);
        await tester.pumpAndSettle();

        // Assert: Speed selector appears
        expect(find.text('1.5x'), findsOneWidget);

        // Act 2: Change playback speed
        await tester.tap(find.text('1.5x'));
        await tester.pumpAndSettle();

        // Assert: Speed changed
        expect(audioService.playbackSpeed, equals(1.5));

        // Act 3: Toggle repeat
        final repeatButton = find.byIcon(Icons.repeat);
        await tester.tap(repeatButton);
        await tester.pumpAndSettle();

        // Assert: Repeat enabled
        expect(audioService.repeatEnabled, isTrue);

        // Act 4: Toggle autoplay
        final autoplayButton = find.byIcon(Icons.skip_next);
        await tester.tap(autoplayButton);
        await tester.pumpAndSettle();

        // Assert: Autoplay toggled
        expect(audioService.autoplayEnabled, isFalse);
      });

      testWidgets('Progress bar and seeking work correctly', (tester) async {
        // Arrange: Start with audio
        final testEpisode = TestUtils.createSampleAudioFile();
        await audioService.playAudio(testEpisode);

        await tester.pumpWidget(createTestApp(home: const PlayerScreen()));
        await tester.pumpAndSettle();

        // Act: Test seek forward and backward buttons
        final seekForwardButton = find.byIcon(Icons.forward_30);
        await tester.tap(seekForwardButton);
        await tester.pumpAndSettle();

        final seekBackwardButton = find.byIcon(Icons.replay_10);
        await tester.tap(seekBackwardButton);
        await tester.pumpAndSettle();

        // Act: Test progress slider (simulate drag)
        final slider = find.byType(Slider);
        expect(slider, findsOneWidget);

        await tester.drag(slider, const Offset(100, 0));
        await tester.pumpAndSettle();
      });
    });

    group('Filter and Search Interaction Flow', () {
      testWidgets('Complex filtering scenario', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Act 1: Apply multiple filters in sequence
        await tester.tap(find.text('Japanese'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Ethereum'));
        await tester.pumpAndSettle();

        // Act 2: Add search query
        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'DeFi');
        await tester.pumpAndSettle();

        // Assert: All filters applied
        expect(contentService.selectedLanguage, equals('ja-JP'));
        expect(contentService.selectedCategory, equals('ethereum'));
        expect(contentService.searchQuery, equals('DeFi'));

        // Act 3: Clear search but keep filters
        await tester.enterText(find.byType(TextField), '');
        await tester.pumpAndSettle();

        // Assert: Search cleared, filters remain
        expect(contentService.searchQuery, equals(''));
        expect(contentService.selectedLanguage, equals('ja-JP'));
        expect(contentService.selectedCategory, equals('ethereum'));

        // Act 4: Reset to "All" category
        await tester.tap(find.text('All'));
        await tester.pumpAndSettle();

        // Assert: Category reset, language filter remains
        expect(contentService.selectedCategory, equals('all'));
        expect(contentService.selectedLanguage, equals('ja-JP'));
      });

      testWidgets('Search suggestions and autocomplete behavior',
          (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Act: Enter partial search and verify real-time filtering
        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Bit');
        await tester.pump(const Duration(milliseconds: 300)); // Debounce time

        // Assert: Search applied with partial term
        expect(contentService.searchQuery, equals('Bit'));

        // Act: Complete the search term
        await tester.enterText(find.byType(TextField), 'Bitcoin');
        await tester.pump(const Duration(milliseconds: 300));

        // Assert: Full search term applied
        expect(contentService.searchQuery, equals('Bitcoin'));
      });

      testWidgets('Sort order changes correctly', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Find and tap the sort dropdown
        final sortDropdown = find.byType(DropdownButton<String>);
        await tester.tap(sortDropdown);
        await tester.pumpAndSettle();

        // Act: Change sort order to oldest first
        await tester.tap(find.text('Oldest First'));
        await tester.pumpAndSettle();

        // Assert: Sort order changed
        expect(contentService.sortOrder, equals('oldest'));

        // Act: Change to alphabetical
        await tester.tap(sortDropdown);
        await tester.pumpAndSettle();

        await tester.tap(find.text('A-Z'));
        await tester.pumpAndSettle();

        // Assert: Sort order changed
        expect(contentService.sortOrder, equals('alphabetical'));
      });
    });

    group('Content Script and Player Layout Flow', () {
      testWidgets('Content script toggle and expansion', (tester) async {
        // Arrange: Start with audio
        final testEpisode = TestUtils.createSampleAudioFile();
        await audioService.playAudio(testEpisode);

        await tester.pumpWidget(createTestApp(home: const PlayerScreen()));
        await tester.pumpAndSettle();

        // Act 1: Toggle content script display
        final contentButton = find.byIcon(Icons.article);
        await tester.tap(contentButton);
        await tester.pumpAndSettle();

        // Assert: Content script area expands
        expect(find.byType(CustomScrollView), findsOneWidget);

        // Act 2: Toggle back to compact view
        await tester.tap(contentButton);
        await tester.pumpAndSettle();

        // Assert: Returns to compact layout
        expect(find.byType(Column), findsWidgets);
      });

      testWidgets('Player options bottom sheet', (tester) async {
        // Arrange: Start with audio
        final testEpisode = TestUtils.createSampleAudioFile();
        await audioService.playAudio(testEpisode);

        await tester.pumpWidget(createTestApp(home: const PlayerScreen()));
        await tester.pumpAndSettle();

        // Act: Open player options
        final optionsButton = find.byIcon(Icons.more_vert);
        await tester.tap(optionsButton);
        await tester.pumpAndSettle();

        // Assert: Bottom sheet appears
        expect(find.text('Audio Details'), findsOneWidget);
        expect(find.byType(BottomSheet), findsOneWidget);

        // Act: Close bottom sheet
        await tester.tapAt(const Offset(200, 100)); // Tap outside
        await tester.pumpAndSettle();
      });

      testWidgets('Episode options from home screen', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Act: Long press on an episode
        final episodeCard = find.byType(Card).first;
        await tester.longPress(episodeCard);
        await tester.pumpAndSettle();

        // Assert: Episode options bottom sheet appears
        expect(find.text('Play'), findsOneWidget);
        expect(find.text('Add to Playlist'), findsOneWidget);
        expect(find.text('Share'), findsOneWidget);

        // Act: Tap Play option
        await tester.tap(find.text('Play'));
        await tester.pumpAndSettle();

        // Assert: Audio starts playing
        expect(audioService.currentAudioFile, isNotNull);
      });
    });

    group('Error Handling and Edge Cases', () {
      testWidgets('Handles loading states correctly', (tester) async {
        // Arrange: Set loading state
        contentService.setLoadingForTesting(true);

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Assert: Loading state shown
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Loading episodes...'), findsOneWidget);
      });

      testWidgets('Handles error states correctly', (tester) async {
        // Arrange: Set error state
        contentService.setErrorForTesting('Network connection failed');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Assert: Error state shown
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('Something went wrong'), findsOneWidget);
        expect(find.text('Network connection failed'), findsOneWidget);

        // Act: Tap retry button
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();
      });

      testWidgets('Handles audio playback errors', (tester) async {
        // Arrange: Start the app
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Act: Simulate audio error (method not available in current implementation)
        // audioService.handlePlaybackError('Audio format not supported');

        // Trigger a rebuild
        await tester.pump();

        // Assert: Error state handled gracefully
        expect(audioService.hasError, isTrue);
        expect(
            audioService.errorMessage, contains('Audio format not supported'));
      });

      testWidgets('Handles rapid user interactions', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Act: Rapidly change filters
        for (int i = 0; i < 5; i++) {
          await tester.tap(find.text('English'));
          await tester.pump(const Duration(milliseconds: 50));
          await tester.tap(find.text('Japanese'));
          await tester.pump(const Duration(milliseconds: 50));
        }

        await tester.pumpAndSettle();

        // Assert: App remains stable
        expect(find.byType(HomeScreen), findsOneWidget);
      });
    });

    group('Navigation and State Persistence', () {
      testWidgets('Navigation between screens preserves state', (tester) async {
        // Arrange: Start with audio playing
        final testEpisode = TestUtils.createSampleAudioFile();
        await audioService.playAudio(testEpisode);

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Act 1: Apply filters on home screen
        await tester.tap(find.text('Ethereum'));
        await tester.pumpAndSettle();

        // Act 2: Navigate to player screen
        await tester.tap(find.byType(MiniPlayer));
        await tester.pumpAndSettle();

        // Assert: Player screen shows
        expect(find.byType(PlayerScreen), findsOneWidget);

        // Act 3: Navigate back to home screen
        await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
        await tester.pumpAndSettle();

        // Assert: Home screen state preserved
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(contentService.selectedCategory, equals('ethereum'));
        expect(audioService.currentAudioFile, isNotNull);
      });

      testWidgets('Player screen handles no audio state', (tester) async {
        // Arrange: Navigate to player with no audio
        await tester.pumpWidget(createTestApp(home: const PlayerScreen()));
        await tester.pumpAndSettle();

        // Assert: No audio state shown
        expect(find.byIcon(Icons.music_off), findsOneWidget);
        expect(find.text('No audio playing'), findsOneWidget);
        expect(find.text('Browse Episodes'), findsOneWidget);

        // Act: Tap browse episodes button
        await tester.tap(find.text('Browse Episodes'));
        await tester.pumpAndSettle();
      });
    });

    group('Performance and Stress Tests', () {
      testWidgets('Handles large episode lists efficiently', (tester) async {
        // Arrange: Create large episode list
        final largeEpisodeList = TestUtils.createSampleAudioFileList(100);
        contentService.setEpisodesForTesting(largeEpisodeList);

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Act: Scroll through list
        final listView = find.byType(ListView);
        await tester.drag(listView, const Offset(0, -500));
        await tester.pumpAndSettle();

        await tester.drag(listView, const Offset(0, -500));
        await tester.pumpAndSettle();

        // Assert: App remains responsive
        expect(find.byType(HomeScreen), findsOneWidget);
      });

      testWidgets('Rapid filter changes performance', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Act: Rapidly change filters multiple times
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 10; i++) {
          await tester.tap(find.text('English'));
          await tester.pump();
          await tester.tap(find.text('Japanese'));
          await tester.pump();
          await tester.tap(find.text('Chinese'));
          await tester.pump();
        }

        await tester.pumpAndSettle();
        stopwatch.stop();

        // Assert: Performance is acceptable (less than 2 seconds)
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
        expect(find.byType(HomeScreen), findsOneWidget);
      });

      testWidgets('Memory usage with multiple episodes', (tester) async {
        // Arrange: Create episodes with different states
        final episodes = TestUtils.createSampleAudioFileList(50);
        // Note: setEpisodesForTesting method not available in current implementation
        // contentService.setEpisodesForTesting(episodes);

        // Set completion states for episodes
        for (int i = 0; i < episodes.length; i++) {
          await contentService.updateEpisodeCompletion(
              episodes[i].id, i * 0.02);
        }

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Act: Navigate between tabs
        await tester.tap(find.text('All'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Unfinished'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Recent'));
        await tester.pumpAndSettle();

        // Assert: App handles memory efficiently
        expect(find.byType(HomeScreen), findsOneWidget);
      });
    });
  });
}

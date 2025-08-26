import 'package:flutter_test/flutter_test.dart';

import 'package:from_fed_to_chain_app/services/content_service.dart';
import 'package:from_fed_to_chain_app/models/audio_file.dart';

import '../test_utils.dart';

// Note: StreamingApiService uses static methods so we can't mock it directly

void main() {
  // Initialize bindings for tests that use SharedPreferences
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ContentService Tests', () {
    late ContentService contentService;

    setUp(() {
      contentService = ContentService();
    });

    group('Episode Loading', () {
      test('can set episodes for testing', () async {
        final testEpisodes = TestUtils.createSampleAudioFileList(5);

        contentService.setEpisodesForTesting(testEpisodes);

        expect(contentService.allEpisodes, equals(testEpisodes));
        expect(contentService.filteredEpisodes, hasLength(greaterThan(0)));
        expect(contentService.isLoading, isFalse);
        expect(contentService.hasError, isFalse);
      });

      test('handles error state correctly', () {
        contentService.setErrorForTesting('Test error message');

        expect(contentService.hasError, isTrue);
        expect(contentService.errorMessage, equals('Test error message'));
        expect(contentService.isLoading, isFalse);
      });

      test('manages loading state correctly', () {
        // Test loading state
        contentService.setLoadingForTesting(true);
        expect(contentService.isLoading, isTrue);
        expect(contentService.hasError, isFalse);

        // Test loading complete
        contentService.setLoadingForTesting(false);
        expect(contentService.isLoading, isFalse);
      });
    });

    group('Filtering and Search', () {
      setUp(() {
        final testEpisodes = [
          TestUtils.createSampleAudioFile(
            id: 'ep1',
            title: 'Bitcoin News',
            language: 'zh-TW',
            category: 'daily-news',
          ),
          TestUtils.createSampleAudioFile(
            id: 'ep2',
            title: 'Ethereum Update',
            language: 'en-US',
            category: 'ethereum',
          ),
          TestUtils.createSampleAudioFile(
            id: 'ep3',
            title: 'Macro Economics',
            language: 'ja-JP',
            category: 'macro',
          ),
          TestUtils.createSampleAudioFile(
            id: 'ep4',
            title: 'Bitcoin Analysis',
            language: 'zh-TW',
            category: 'daily-news',
          ),
        ];

        // Set episodes directly for testing and reset filters to "all"
        contentService.setEpisodesForTesting(testEpisodes);
        // Reset to default language to show all episodes
        contentService.setSelectedLanguage(
            'zh-TW'); // This should show 2 episodes initially
      });

      test('filters episodes by language', () async {
        await contentService.setLanguage('en-US');

        final filtered = contentService.filteredEpisodes;
        expect(filtered.length, equals(1));
        expect(filtered.first.title, equals('Ethereum Update'));
      });

      test('filters episodes by category', () async {
        await contentService.setCategory('daily-news');

        final filtered = contentService.filteredEpisodes;
        expect(filtered.length, equals(2));
        expect(filtered.every((e) => e.category == 'daily-news'), isTrue);
      });

      test('combines language and category filters', () async {
        await contentService.setLanguage('zh-TW');
        await contentService.setCategory('daily-news');

        final filtered = contentService.filteredEpisodes;
        expect(filtered.length, equals(2));
        expect(
            filtered.every(
                (e) => e.language == 'zh-TW' && e.category == 'daily-news'),
            isTrue);
      });

      test('searches episodes by title', () {
        contentService.setSearchQuery('Bitcoin');

        final filtered = contentService.filteredEpisodes;
        expect(filtered.length, equals(2));
        expect(filtered.every((e) => e.title.contains('Bitcoin')), isTrue);
      });

      test('combines search with filters', () async {
        await contentService.setLanguage('zh-TW');
        contentService.setSearchQuery('Bitcoin');

        final filtered = contentService.filteredEpisodes;
        expect(filtered.length, equals(2));
        expect(
            filtered.every(
                (e) => e.language == 'zh-TW' && e.title.contains('Bitcoin')),
            isTrue);
      });

      test('handles case insensitive search', () {
        contentService.setSearchQuery('bitcoin');

        final filtered = contentService.filteredEpisodes;
        expect(filtered.length, equals(2));
      });

      test('clears search query', () {
        contentService.setSearchQuery('Bitcoin');
        expect(contentService.filteredEpisodes.length,
            equals(2)); // Only zh-TW episodes matching "Bitcoin"

        contentService.setSearchQuery('');
        expect(contentService.filteredEpisodes.length,
            equals(2)); // All zh-TW episodes (not all languages)
      });

      test('shows all episodes when category is "all"', () async {
        await contentService.setCategory('daily-news');
        expect(contentService.filteredEpisodes.length,
            equals(2)); // 2 zh-TW daily-news episodes

        await contentService.setCategory('all');
        expect(contentService.filteredEpisodes.length,
            equals(2)); // All zh-TW episodes (filtered by language)
      });
    });

    group('Sorting', () {
      setUp(() {
        final testEpisodes = [
          TestUtils.createSampleAudioFile(
            id: '2025-01-01-old-episode',
            title: 'Z Old Episode',
            language: 'zh-TW', // Ensure episodes are in default language filter
          ),
          TestUtils.createSampleAudioFile(
            id: '2025-03-01-new-episode',
            title: 'A New Episode',
            language: 'zh-TW',
          ),
          TestUtils.createSampleAudioFile(
            id: '2025-02-01-middle-episode',
            title: 'M Middle Episode',
            language: 'zh-TW',
          ),
        ];

        contentService.setEpisodesForTesting(testEpisodes);
      });

      test('sorts episodes by newest first', () {
        contentService.setSortOrder('newest');

        final sorted = contentService.filteredEpisodes;
        expect(sorted[0].id, equals('2025-03-01-new-episode'));
        expect(sorted[1].id, equals('2025-02-01-middle-episode'));
        expect(sorted[2].id, equals('2025-01-01-old-episode'));
      });

      test('sorts episodes by oldest first', () {
        contentService.setSortOrder('oldest');

        final sorted = contentService.filteredEpisodes;
        expect(sorted[0].id, equals('2025-01-01-old-episode'));
        expect(sorted[1].id, equals('2025-02-01-middle-episode'));
        expect(sorted[2].id, equals('2025-03-01-new-episode'));
      });

      test('sorts episodes alphabetically', () {
        contentService.setSortOrder('alphabetical');

        final sorted = contentService.filteredEpisodes;
        expect(sorted[0].title, equals('A New Episode'));
        expect(sorted[1].title, equals('M Middle Episode'));
        expect(sorted[2].title, equals('Z Old Episode'));
      });

      test('maintains sort order when filtering', () {
        contentService.setSortOrder('alphabetical');
        contentService.searchEpisodes('Episode');

        final sorted = contentService.filteredEpisodes;
        expect(sorted[0].title, equals('A New Episode'));
        expect(sorted[1].title, equals('M Middle Episode'));
        expect(sorted[2].title, equals('Z Old Episode'));
      });
    });

    group('Episode Completion Tracking', () {
      late AudioFile testEpisode;

      setUp(() {
        testEpisode = TestUtils.createSampleAudioFile(id: 'test-episode');
        contentService.setEpisodesForTesting([testEpisode]);
      });

      test('tracks episode completion percentage', () {
        contentService.setEpisodeCompletion(testEpisode.id, 0.5);

        expect(
            contentService.getEpisodeCompletion(testEpisode.id), equals(0.5));
      });

      test('identifies finished episodes', () {
        contentService.setEpisodeCompletion(testEpisode.id, 0.9);

        expect(contentService.isEpisodeFinished(testEpisode.id), isTrue);
      });

      test('identifies unfinished episodes', () {
        contentService.setEpisodeCompletion(testEpisode.id, 0.3);

        expect(contentService.isEpisodeFinished(testEpisode.id), isFalse);
      });

      test('returns unfinished episodes list', () {
        final episodes = [
          TestUtils.createSampleAudioFile(id: 'finished', language: 'zh-TW'),
          TestUtils.createSampleAudioFile(id: 'unfinished', language: 'zh-TW'),
          TestUtils.createSampleAudioFile(id: 'not-started', language: 'zh-TW'),
        ];
        contentService.setEpisodesForTesting(episodes);

        contentService.setEpisodeCompletion('finished', 0.95);
        contentService.setEpisodeCompletion('unfinished', 0.3);
        // 'not-started' has 0.0 completion (default)

        final unfinished = contentService.getUnfinishedEpisodes();
        expect(unfinished.length,
            equals(1)); // Only 'unfinished' has > 0 but < 0.9 completion
        expect(unfinished.any((e) => e.id == 'unfinished'), isTrue);
        expect(unfinished.any((e) => e.id == 'not-started'),
            isFalse); // Not started is 0.0, not unfinished
        expect(unfinished.any((e) => e.id == 'finished'), isFalse);
      });
    });

    group('Recent Episodes', () {
      setUp(() {
        final now = DateTime.now();
        final episodes = [
          TestUtils.createSampleAudioFile(id: 'old-episode'),
          TestUtils.createSampleAudioFile(id: 'recent-episode'),
          TestUtils.createSampleAudioFile(id: 'very-recent-episode'),
        ];
        contentService.setEpisodesForTesting(episodes);

        // Set listen history using addToListenHistory
        contentService.addToListenHistory(episodes[0],
            at: now.subtract(const Duration(days: 10)));
        contentService.addToListenHistory(episodes[1],
            at: now.subtract(const Duration(days: 2)));
        contentService.addToListenHistory(episodes[2],
            at: now.subtract(const Duration(hours: 1)));
      });

      test('returns recent episodes based on listen history', () {
        final recent = contentService.getListenHistoryEpisodes(limit: 10);

        expect(recent.length, equals(3)); // All episodes have history
        expect(recent.any((e) => e.id == 'recent-episode'), isTrue);
        expect(recent.any((e) => e.id == 'very-recent-episode'), isTrue);
        expect(recent.any((e) => e.id == 'old-episode'), isTrue);
      });

      test('limits recent episodes count', () {
        // Create and add more episodes with listen history
        final now = DateTime.now();
        final additionalEpisodes = <AudioFile>[];
        for (int i = 0; i < 20; i++) {
          final episode = TestUtils.createSampleAudioFile(id: 'recent-$i');
          additionalEpisodes.add(episode);
        }

        final allEpisodes = [
          ...contentService.allEpisodes,
          ...additionalEpisodes,
        ];
        contentService.setEpisodesForTesting(allEpisodes);

        for (int i = 0; i < 20; i++) {
          contentService.addToListenHistory(additionalEpisodes[i],
              at: now.subtract(Duration(hours: i)));
        }

        final recent = contentService.getListenHistoryEpisodes(limit: 10);
        expect(recent.length, lessThanOrEqualTo(10)); // Requested limit
      });

      test('sorts recent episodes by listen time', () {
        final recent = contentService.getListenHistoryEpisodes();

        // Should be sorted by most recent first (most recent episode is at index 2)
        if (recent.length >= 2) {
          expect(recent[0].id, equals('very-recent-episode'));
          expect(recent[1].id, equals('recent-episode'));
        }
      });
    });

    group('Playlist Management', () {
      late List<AudioFile> testEpisodes;

      setUp(() {
        // Create episodes with consistent language for filtering
        testEpisodes = List.generate(
            5,
            (index) => TestUtils.createSampleAudioFile(
                  id: 'test-audio-$index',
                  title: 'Test Audio Title $index',
                  language: 'zh-TW', // Use consistent language
                  category: index % 2 == 0 ? 'daily-news' : 'ethereum',
                ));
        contentService.setEpisodesForTesting(testEpisodes);
      });

      test('creates playlist from episodes', () {
        contentService.createPlaylist('Test Playlist', testEpisodes);

        expect(contentService.currentPlaylist, isNotNull);
        expect(contentService.currentPlaylist!.name, equals('Test Playlist'));
        expect(contentService.currentPlaylist!.episodes, equals(testEpisodes));
        expect(contentService.currentPlaylist!.currentEpisode,
            equals(testEpisodes.first));
      });

      test('creates category-based playlist', () async {
        // Set up episodes with daily-news category
        final newsEpisodes = testEpisodes
            .take(2)
            .map((episode) => TestUtils.createSampleAudioFile(
                  id: episode.id,
                  title: episode.title,
                  category: 'daily-news',
                  language: episode.language,
                ))
            .toList();

        final allEpisodes = [...newsEpisodes, ...testEpisodes.skip(2)];
        contentService.setEpisodesForTesting(allEpisodes);

        await contentService.setCategory('daily-news');
        contentService.createPlaylistFromFiltered('Daily News Playlist');

        expect(contentService.currentPlaylist, isNotNull);
        expect(
            contentService.currentPlaylist!.episodes
                .every((e) => e.category == 'daily-news'),
            isTrue);
      });

      test('creates language-based playlist', () async {
        // Set up episodes with en-US language
        final englishEpisodes = testEpisodes
            .take(2)
            .map((episode) => TestUtils.createSampleAudioFile(
                  id: episode.id,
                  title: episode.title,
                  category: episode.category,
                  language: 'en-US',
                ))
            .toList();

        final allEpisodes = [...englishEpisodes, ...testEpisodes.skip(2)];
        contentService.setEpisodesForTesting(allEpisodes);

        await contentService.setLanguage('en-US');
        contentService.createPlaylistFromFiltered('English Playlist');

        expect(contentService.currentPlaylist, isNotNull);
        expect(
            contentService.currentPlaylist!.episodes
                .every((e) => e.language == 'en-US'),
            isTrue);
      });

      test('manages current playlist', () {
        contentService.createPlaylist('Test Playlist', testEpisodes);

        expect(contentService.currentPlaylist, isNotNull);
        expect(contentService.currentPlaylist!.name, equals('Test Playlist'));
        expect(contentService.currentPlaylist!.episodes, equals(testEpisodes));

        // Clear playlist
        contentService.clearCurrentPlaylist();
        expect(contentService.currentPlaylist, isNull);
      });

      test('adds and removes episodes from current playlist', () {
        contentService.createPlaylist(
            'Test Playlist', testEpisodes.take(2).toList());

        final newEpisode = TestUtils.createSampleAudioFile(id: 'new-episode');
        contentService.addToCurrentPlaylist(newEpisode);

        expect(contentService.currentPlaylist!.episodes.length, equals(3));
        expect(contentService.currentPlaylist!.episodes.contains(newEpisode),
            isTrue);

        contentService.removeFromCurrentPlaylist(newEpisode);
        expect(contentService.currentPlaylist!.episodes.length, equals(2));
        expect(contentService.currentPlaylist!.episodes.contains(newEpisode),
            isFalse);
      });
    });

    group('Content Caching', () {
      test('caches episode content', () {
        final content = TestUtils.createSampleAudioContent(id: 'test-content');

        // Cache content directly for testing
        contentService.cacheContent(
            'test-content', 'en-US', 'daily-news', content);

        // Verify cached content can be retrieved
        final cachedContent = contentService.getCachedContent(
            'test-content', 'en-US', 'daily-news');
        expect(cachedContent, isNotNull);
        expect(cachedContent!.id, equals('test-content'));
      });

      test('handles missing cached content', () {
        final cachedContent = contentService.getCachedContent(
            'missing-content', 'en-US', 'daily-news');
        expect(cachedContent, isNull);
      });

      test('clears content cache', () {
        final content = TestUtils.createSampleAudioContent(id: 'test-content');

        // Cache content
        contentService.cacheContent(
            'test-content', 'en-US', 'daily-news', content);
        expect(
            contentService.getCachedContent(
                'test-content', 'en-US', 'daily-news'),
            isNotNull);

        // Clear cache
        contentService.clearContentCache();

        // Content should no longer be cached
        expect(
            contentService.getCachedContent(
                'test-content', 'en-US', 'daily-news'),
            isNull);
      });
    });

    group('Statistics and Analytics', () {
      setUp(() {
        final episodes = TestUtils.createSampleAudioFileList(10);
        contentService.setEpisodesForTesting(episodes);

        // Set up some completion data
        contentService.setEpisodeCompletion(episodes[0].id, 1.0);
        contentService.setEpisodeCompletion(episodes[1].id, 0.5);
        contentService.setEpisodeCompletion(episodes[2].id, 0.8);
        contentService.setEpisodeCompletion(episodes[3].id, 1.0);

        // Set up listen history
        final now = DateTime.now();
        contentService.addToListenHistory(episodes[0],
            at: now.subtract(const Duration(days: 1)));
        contentService.addToListenHistory(episodes[1],
            at: now.subtract(const Duration(hours: 5)));
        contentService.addToListenHistory(episodes[2],
            at: now.subtract(const Duration(days: 3)));
      });

      test('gets basic statistics', () {
        final stats = contentService.getStatistics();

        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey('totalEpisodes'), isTrue);
        expect(stats.containsKey('filteredEpisodes'), isTrue);
        expect(stats.containsKey('languages'), isTrue);
        expect(stats.containsKey('categories'), isTrue);
        expect(stats['totalEpisodes'], equals(10));
      });

      test('tracks episode completion', () {
        final episodes = contentService.allEpisodes;

        // Test completion tracking
        expect(
            contentService.getEpisodeCompletion(episodes[0].id), equals(1.0));
        expect(
            contentService.getEpisodeCompletion(episodes[1].id), equals(0.5));
        expect(contentService.isEpisodeFinished(episodes[0].id), isTrue);
        expect(contentService.isEpisodeFinished(episodes[1].id), isFalse);
      });

      test('manages listen history', () {
        final episodes = contentService.allEpisodes;
        final history = contentService.listenHistory;

        expect(history, isA<Map<String, DateTime>>());
        expect(history.containsKey(episodes[0].id), isTrue);
        expect(history.containsKey(episodes[1].id), isTrue);
        expect(history.containsKey(episodes[2].id), isTrue);
      });

      test('gets episodes by language and category', () {
        // Create episodes with specific languages and categories for testing
        final zhEpisodes = contentService.getEpisodesByLanguage('zh-TW');
        final dailyNewsEpisodes =
            contentService.getEpisodesByCategory('daily-news');
        final specificEpisodes = contentService
            .getEpisodesByLanguageAndCategory('zh-TW', 'daily-news');

        expect(zhEpisodes, isA<List<AudioFile>>());
        expect(dailyNewsEpisodes, isA<List<AudioFile>>());
        expect(specificEpisodes, isA<List<AudioFile>>());
      });
    });

    group('Error Handling', () {
      test('handles error state', () {
        contentService.setErrorForTesting('Network timeout error');

        expect(contentService.hasError, isTrue);
        expect(contentService.errorMessage, contains('timeout'));
        expect(contentService.isLoading, isFalse);
      });

      test('handles different error types', () {
        contentService.setErrorForTesting('Invalid JSON format');

        expect(contentService.hasError, isTrue);
        expect(contentService.errorMessage, contains('Invalid'));
      });

      test('recovers from error state', () {
        // Set error state
        contentService.setErrorForTesting('Network error');
        expect(contentService.hasError, isTrue);

        // Create a new ContentService instance to simulate recovery
        final newContentService = ContentService();
        final testEpisodes = TestUtils.createSampleAudioFileList(3);
        newContentService.setEpisodesForTesting(testEpisodes);

        expect(newContentService.hasError, isFalse);
        expect(newContentService.allEpisodes.length, equals(3));
      });

      test('handles empty data gracefully', () {
        contentService.setEpisodesForTesting([]);

        expect(contentService.hasError, isFalse);
        expect(contentService.allEpisodes.isEmpty, isTrue);
        expect(contentService.filteredEpisodes.isEmpty, isTrue);
      });
    });

    group('Persistence and Storage', () {
      test('tracks episode completion data', () async {
        const episodeId = 'test-episode';
        const completion = 0.75;

        await contentService.setEpisodeCompletion(episodeId, completion);

        expect(
            contentService.getEpisodeCompletion(episodeId), equals(completion));
        expect(contentService.isEpisodeFinished(episodeId), isFalse);
        expect(contentService.isEpisodeUnfinished(episodeId), isTrue);
      });

      test('manages listen history', () async {
        const episodeId = 'test-episode';
        final episode = TestUtils.createSampleAudioFile(id: episodeId);
        final timestamp = DateTime.now();

        await contentService.addToListenHistory(episode, at: timestamp);

        final history = contentService.listenHistory;
        expect(history.containsKey(episodeId), isTrue);
        expect(history[episodeId]?.millisecondsSinceEpoch,
            equals(timestamp.millisecondsSinceEpoch));
      });

      test('manages filter preferences', () async {
        await contentService.setLanguage('en-US');
        await contentService.setCategory('ethereum');
        await contentService.setSortOrder('alphabetical');

        expect(contentService.selectedLanguage, equals('en-US'));
        expect(contentService.selectedCategory, equals('ethereum'));
        expect(contentService.sortOrder, equals('alphabetical'));
      });

      test('handles default values correctly', () {
        final newContentService = ContentService();

        // Should load with default values
        expect(newContentService.selectedLanguage, equals('zh-TW'));
        expect(newContentService.selectedCategory, equals('all'));
        expect(newContentService.sortOrder, equals('newest'));
        expect(newContentService.isLoading, isFalse);
        expect(newContentService.hasError, isFalse);
      });
    });

    group('Reactive Updates', () {
      test('notifies listeners on episode loading', () {
        bool notified = false;
        contentService.addListener(() {
          notified = true;
        });

        final testEpisodes = TestUtils.createSampleAudioFileList(3);
        contentService.setEpisodesForTesting(testEpisodes);

        expect(notified, isTrue);
      });

      test('notifies listeners on filter changes', () async {
        bool notified = false;
        contentService.addListener(() {
          notified = true;
        });

        await contentService.setLanguage('en-US');

        expect(notified, isTrue);
      });

      test('notifies listeners on search changes', () {
        bool notified = false;
        contentService.addListener(() {
          notified = true;
        });

        contentService.setSearchQuery('test query');

        expect(notified, isTrue);
      });

      test('batches multiple filter changes', () async {
        int notificationCount = 0;
        contentService.addListener(() {
          notificationCount++;
        });

        // Multiple quick changes
        await contentService.setLanguage('en-US');
        await contentService.setCategory('ethereum');
        await contentService.setSortOrder('alphabetical');

        // Should notify for each change
        expect(notificationCount, greaterThan(0));
      });

      test('disposes properly', () {
        // Test that dispose doesn't crash
        expect(() => contentService.dispose(), returnsNormally);
      });
    });
  });
}

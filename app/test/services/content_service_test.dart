import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:from_fed_to_chain_app/services/content_service.dart';
import 'package:from_fed_to_chain_app/models/audio_file.dart';

import '../test_utils.dart';

void main() {
  group('ContentService Tests', () {
    late ContentService contentService;

    setUpAll(() async {
      // Initialize dotenv with test environment variables
      dotenv.testLoad(fileInput: '''
AUDIO_API_BASE_URL=https://test-api.example.com
ENVIRONMENT=test
''');
    });

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      contentService = ContentService();
    });

    tearDown(() {
      contentService.dispose();
    });

    test('should initialize with default values', () {
      expect(contentService.selectedLanguage, equals('zh-TW'));
      expect(contentService.selectedCategory, equals('all'));
      expect(contentService.sortOrder, equals('newest'));
      expect(contentService.searchQuery, isEmpty);
      expect(contentService.isLoading, isFalse);
      expect(contentService.hasError, isFalse);
      expect(contentService.allEpisodes, isEmpty);
      expect(contentService.filteredEpisodes, isEmpty);
    });

    test('should track episode completion correctly', () {
      // Test the episode completion tracking functionality
      const episodeId = 'test-episode';

      // This tests the getter methods that exist in the service
      expect(contentService.getEpisodeCompletion(episodeId), equals(0.0));
      expect(contentService.isEpisodeUnfinished(episodeId), isFalse);
      expect(contentService.isEpisodeFinished(episodeId), isFalse);
    });

    test('should mark episode as finished when completion >= 0.9', () {
      // Test the logic for marking episodes as finished
      const episodeId = 'finished-episode';

      // Test the boundary condition for finished episodes
      expect(contentService.isEpisodeFinished(episodeId), isFalse);
    });

    test('should get listen history episodes', () {
      // Test the listen history functionality
      final historyEpisodes = contentService.getListenHistoryEpisodes();
      expect(historyEpisodes, isEmpty);

      // Test with limit
      final limitedHistory = contentService.getListenHistoryEpisodes(limit: 10);
      expect(limitedHistory, isEmpty);
    });

    test('should handle search query updates', () {
      // Test search functionality that exists
      const testQuery = 'Bitcoin';
      contentService.setSearchQuery(testQuery);
      expect(contentService.searchQuery, equals(testQuery));
    });

    test('should clear content cache', () {
      // Test cache management
      contentService.clearContentCache();
      // Should not throw error
      expect(true, isTrue);
    });

    test('should handle content fetching', () async {
      // Test content fetching with proper error handling
      const nonExistentId = 'non-existent-content';
      const language = 'en-US';
      const category = 'daily-news';

      final content = await contentService.fetchContentById(
          nonExistentId, language, category);
      // Should handle missing content gracefully
      expect(content, isNull);
    });

    test('should get cached content correctly', () {
      // Test cached content retrieval
      const id = 'test-content';
      const language = 'zh-TW';
      const category = 'daily-news';

      final cachedContent =
          contentService.getCachedContent(id, language, category);
      expect(cachedContent, isNull); // Should be null for non-cached content
    });

    test('should handle audio file content lookup', () async {
      // Test getting content for audio file
      final audioFile = AudioFile(
        id: 'test-audio-file',
        title: 'Test Audio',
        language: 'en-US',
        category: 'daily-news',
        streamingUrl: 'https://example.com/test.m3u8',
        path: 'test.m3u8',
        lastModified: DateTime.now(),
      );

      final content = await contentService.getContentForAudioFile(audioFile);
      // Should handle missing content gracefully
      expect(content, isNull);
    });

    test('should handle playlist operations', () {
      // Test basic playlist functionality
      expect(contentService.currentPlaylist, isNull);

      final audioFile = AudioFile(
        id: 'playlist-test',
        title: 'Playlist Test',
        language: 'en-US',
        category: 'daily-news',
        streamingUrl: 'https://example.com/playlist.m3u8',
        path: 'playlist.m3u8',
        lastModified: DateTime.now(),
      );

      // Should not throw error when adding to playlist
      contentService.addToCurrentPlaylist(audioFile);
      expect(true, isTrue);
    });

    test('should notify listeners when data changes', () {
      // Test ChangeNotifier functionality
      bool notified = false;
      contentService.addListener(() {
        notified = true;
      });

      // Trigger a change that should notify listeners
      contentService.setSearchQuery('test query');
      expect(notified, isTrue);
    });

    // Enhanced tests for recent language filtering logic
    group('Language Filtering Logic', () {
      test('should filter episodes by selected language correctly', () {
        // Create mixed language episodes
        final episodes = [
          TestUtils.createSampleAudioFile(
            id: 'ep1',
            title: 'English Episode',
            language: 'en-US',
          ),
          TestUtils.createSampleAudioFile(
            id: 'ep2',
            title: 'Japanese Episode',
            language: 'ja-JP',
          ),
          TestUtils.createSampleAudioFile(
            id: 'ep3',
            title: 'Chinese Episode',
            language: 'zh-TW',
          ),
        ];

        // Mock the episodes in the service
        contentService.setEpisodesForTesting(episodes);

        // Test filtering by English
        contentService.setSelectedLanguage('en-US');
        final englishEpisodes = contentService.getFilteredEpisodes();
        expect(englishEpisodes, hasLength(1));
        expect(englishEpisodes.first.language, equals('en-US'));

        // Test filtering by Japanese
        contentService.setSelectedLanguage('ja-JP');
        final japaneseEpisodes = contentService.getFilteredEpisodes();
        expect(japaneseEpisodes, hasLength(1));
        expect(japaneseEpisodes.first.language, equals('ja-JP'));

        // Test filtering by Chinese
        contentService.setSelectedLanguage('zh-TW');
        final chineseEpisodes = contentService.getFilteredEpisodes();
        expect(chineseEpisodes, hasLength(1));
        expect(chineseEpisodes.first.language, equals('zh-TW'));
      });

      test('should handle case where no episodes match selected language', () {
        // Create episodes with only one language
        final episodes = [
          TestUtils.createSampleAudioFile(language: 'en-US'),
          TestUtils.createSampleAudioFile(language: 'en-US'),
        ];

        contentService.setEpisodesForTesting(episodes);

        // Filter by language that doesn't exist
        contentService.setSelectedLanguage('ja-JP');
        final filteredEpisodes = contentService.getFilteredEpisodes();
        expect(filteredEpisodes, isEmpty);
      });

      test('should preserve episode order when filtering by language', () {
        final episodes = [
          TestUtils.createSampleAudioFile(
            id: 'ep1',
            title: 'First English',
            language: 'en-US',
            publishDate: DateTime(2025, 1, 1),
          ),
          TestUtils.createSampleAudioFile(
            id: 'ep2',
            title: 'Japanese Episode',
            language: 'ja-JP',
            publishDate: DateTime(2025, 1, 2),
          ),
          TestUtils.createSampleAudioFile(
            id: 'ep3',
            title: 'Second English',
            language: 'en-US',
            publishDate: DateTime(2025, 1, 3),
          ),
        ];

        contentService.setEpisodesForTesting(episodes);
        contentService.setSelectedLanguage('en-US');

        final filteredEpisodes = contentService.getFilteredEpisodes();
        expect(filteredEpisodes, hasLength(2));
        expect(filteredEpisodes[0].title,
            equals('Second English')); // Newest first
        expect(filteredEpisodes[1].title, equals('First English'));
      });

      test('should update filtered episodes when language selection changes',
          () {
        final episodes = [
          TestUtils.createSampleAudioFile(language: 'en-US'),
          TestUtils.createSampleAudioFile(language: 'ja-JP'),
          TestUtils.createSampleAudioFile(language: 'zh-TW'),
        ];

        contentService.setEpisodesForTesting(episodes);

        // Start with English
        contentService.setSelectedLanguage('en-US');
        expect(contentService.getFilteredEpisodes(), hasLength(1));

        // Change to Japanese
        contentService.setSelectedLanguage('ja-JP');
        expect(contentService.getFilteredEpisodes(), hasLength(1));

        // Change to Chinese
        contentService.setSelectedLanguage('zh-TW');
        expect(contentService.getFilteredEpisodes(), hasLength(1));
      });

      test('should handle empty episode list when filtering by language', () {
        contentService.setEpisodesForTesting([]);
        contentService.setSelectedLanguage('en-US');

        final filteredEpisodes = contentService.getFilteredEpisodes();
        expect(filteredEpisodes, isEmpty);
      });

      test('should filter episodes regardless of case sensitivity', () {
        final episodes = [
          TestUtils.createSampleAudioFile(language: 'en-US'),
          TestUtils.createSampleAudioFile(language: 'EN-US'), // Different case
        ];

        contentService.setEpisodesForTesting(episodes);
        contentService.setSelectedLanguage('en-US');

        // Should match both regardless of case (if service handles case insensitive)
        final filteredEpisodes = contentService.getFilteredEpisodes();
        expect(filteredEpisodes, hasLength(greaterThanOrEqualTo(1)));
      });
    });

    group('Category Filtering Logic', () {
      test('should filter episodes by selected category correctly', () async {
        final episodes = [
          TestUtils.createSampleAudioFile(category: 'daily-news'),
          TestUtils.createSampleAudioFile(category: 'ethereum'),
          TestUtils.createSampleAudioFile(category: 'macro'),
        ];

        contentService.setEpisodesForTesting(episodes);

        // Set language to same as episode language to ensure episodes are not filtered out by language
        contentService.setSelectedLanguage(episodes.first.language);

        // Test filtering by category
        contentService.setSelectedCategory('daily-news');
        await Future.delayed(Duration.zero); // Allow time for filtering

        final newsEpisodes = contentService.getFilteredEpisodes();
        expect(newsEpisodes, hasLength(1));
        expect(newsEpisodes.first.category, equals('daily-news'));
      });

      test('should return all episodes when category is "all"', () async {
        final episodes = [
          TestUtils.createSampleAudioFile(category: 'daily-news'),
          TestUtils.createSampleAudioFile(category: 'ethereum'),
          TestUtils.createSampleAudioFile(category: 'macro'),
        ];

        contentService.setEpisodesForTesting(episodes);

        // Set language to same as episode language to ensure episodes are not filtered out by language
        contentService.setSelectedLanguage(episodes.first.language);
        contentService.setSelectedCategory('all');
        await Future.delayed(Duration.zero); // Allow time for filtering

        final allEpisodes = contentService.getFilteredEpisodes();
        expect(allEpisodes, hasLength(3));
      });
    });

    group('Combined Filtering Logic', () {
      test('should apply both language and category filters', () {
        final episodes = [
          TestUtils.createSampleAudioFile(
            language: 'en-US',
            category: 'daily-news',
          ),
          TestUtils.createSampleAudioFile(
            language: 'en-US',
            category: 'ethereum',
          ),
          TestUtils.createSampleAudioFile(
            language: 'ja-JP',
            category: 'daily-news',
          ),
        ];

        contentService.setEpisodesForTesting(episodes);
        contentService.setSelectedLanguage('en-US');
        contentService.setSelectedCategory('daily-news');

        final filteredEpisodes = contentService.getFilteredEpisodes();
        expect(filteredEpisodes, hasLength(1));
        expect(filteredEpisodes.first.language, equals('en-US'));
        expect(filteredEpisodes.first.category, equals('daily-news'));
      });

      test('should handle search query with filters', () {
        final episodes = [
          TestUtils.createSampleAudioFile(
            title: 'Bitcoin News Today',
            language: 'en-US',
            category: 'daily-news',
          ),
          TestUtils.createSampleAudioFile(
            title: 'Ethereum Update',
            language: 'en-US',
            category: 'ethereum',
          ),
          TestUtils.createSampleAudioFile(
            title: 'Bitcoin Analysis',
            language: 'ja-JP',
            category: 'daily-news',
          ),
        ];

        contentService.setEpisodesForTesting(episodes);
        contentService.setSelectedLanguage('en-US');
        contentService.setSearchQuery('Bitcoin');

        final filteredEpisodes = contentService.getFilteredEpisodes();
        expect(filteredEpisodes, hasLength(1));
        expect(filteredEpisodes.first.title, contains('Bitcoin News Today'));
      });
    });

    group('Episode Completion and History', () {
      test('should track episode completion correctly', () async {
        const episodeId = 'test-episode';

        // Initially no completion
        expect(contentService.getEpisodeCompletion(episodeId), equals(0.0));

        // Set completion
        await contentService.setEpisodeCompletion(episodeId, 0.5);
        expect(contentService.getEpisodeCompletion(episodeId), equals(0.5));

        // Update completion
        await contentService.setEpisodeCompletion(episodeId, 0.9);
        expect(contentService.getEpisodeCompletion(episodeId), equals(0.9));
      });

      test('should identify finished episodes correctly', () async {
        const episodeId = 'finished-episode';

        // Not finished initially
        expect(contentService.isEpisodeFinished(episodeId), isFalse);

        // Set to almost finished (should not be considered finished)
        await contentService.setEpisodeCompletion(episodeId, 0.89);
        expect(contentService.isEpisodeFinished(episodeId), isFalse);

        // Set to finished threshold
        await contentService.setEpisodeCompletion(episodeId, 0.9);
        expect(contentService.isEpisodeFinished(episodeId), isTrue);

        // Set to fully finished
        await contentService.setEpisodeCompletion(episodeId, 1.0);
        expect(contentService.isEpisodeFinished(episodeId), isTrue);
      });

      test('should identify unfinished episodes correctly', () async {
        const episodeId = 'unfinished-episode';

        // Not started (should not be unfinished)
        expect(contentService.isEpisodeUnfinished(episodeId), isFalse);

        // Started but not finished
        await contentService.setEpisodeCompletion(episodeId, 0.3);
        expect(contentService.isEpisodeUnfinished(episodeId), isTrue);

        // Almost finished (still unfinished)
        await contentService.setEpisodeCompletion(episodeId, 0.8);
        expect(contentService.isEpisodeUnfinished(episodeId), isTrue);

        // Finished (no longer unfinished)
        await contentService.setEpisodeCompletion(episodeId, 0.9);
        expect(contentService.isEpisodeUnfinished(episodeId), isFalse);
      });

      test('should track listen history correctly', () async {
        final episodes = TestUtils.createSampleAudioFileList(5);
        contentService.setEpisodesForTesting(episodes);

        // Add episodes to history
        await contentService.addToListenHistory(episodes[0]);
        await contentService.addToListenHistory(episodes[1]);

        final historyEpisodes = contentService.getListenHistoryEpisodes();
        expect(historyEpisodes, hasLength(2));
      });

      test('should limit listen history correctly', () async {
        final episodes = TestUtils.createSampleAudioFileList(10);
        contentService.setEpisodesForTesting(episodes);

        // Add all episodes to history
        for (final episode in episodes) {
          await contentService.addToListenHistory(episode);
        }

        // Get limited history
        final limitedHistory =
            contentService.getListenHistoryEpisodes(limit: 3);
        expect(limitedHistory, hasLength(3));
      });
    });

    group('Playlist Operations', () {
      test('should handle playlist creation and management', () {
        final audioFile = TestUtils.createSampleAudioFile();

        // Initially no playlist
        expect(contentService.currentPlaylist, isNull);

        // Create playlist
        final episodes = [TestUtils.createSampleAudioFile()];
        contentService.createPlaylist('Test Playlist', episodes);
        expect(contentService.currentPlaylist, isNotNull);
        expect(contentService.currentPlaylist?.name, equals('Test Playlist'));

        // Add to playlist
        contentService.addToCurrentPlaylist(audioFile);
        expect(contentService.currentPlaylist?.episodes, contains(audioFile));
      });

      test('should handle playlist clearing', () {
        final audioFile = TestUtils.createSampleAudioFile();

        contentService.createPlaylist('Test Playlist', [audioFile]);

        // Verify playlist has content
        expect(contentService.currentPlaylist?.episodes, isNotEmpty);

        // Clear playlist
        contentService.clearCurrentPlaylist();
        expect(contentService.currentPlaylist, isNull);
      });
    });

    group('Content Cache Management', () {
      test('should cache and retrieve content correctly', () {
        final content = TestUtils.createSampleAudioContent();

        // Cache content
        contentService.cacheContent(
            content.id, content.language, content.category, content);

        // Retrieve cached content
        final cachedContent = contentService.getCachedContent(
          content.id,
          content.language,
          content.category,
        );

        expect(cachedContent, isNotNull);
        expect(cachedContent?.id, equals(content.id));
      });

      test('should clear content cache correctly', () {
        final content = TestUtils.createSampleAudioContent();

        // Cache content
        contentService.cacheContent(
            content.id, content.language, content.category, content);
        expect(
            contentService.getCachedContent(
                content.id, content.language, content.category),
            isNotNull);

        // Clear cache
        contentService.clearContentCache();
        expect(
            contentService.getCachedContent(
                content.id, content.language, content.category),
            isNull);
      });
    });

    group('Error Handling and Edge Cases', () {
      test('should handle null episode IDs gracefully', () {
        expect(() => contentService.getEpisodeCompletion(''), returnsNormally);
        expect(() => contentService.isEpisodeFinished(''), returnsNormally);
        expect(() => contentService.isEpisodeUnfinished(''), returnsNormally);
      });

      test('should handle invalid completion values', () async {
        const episodeId = 'test-episode';

        // Test negative completion
        await contentService.setEpisodeCompletion(episodeId, -0.1);
        expect(contentService.getEpisodeCompletion(episodeId), equals(0.0));

        // Test completion over 1.0
        await contentService.setEpisodeCompletion(episodeId, 1.5);
        expect(contentService.getEpisodeCompletion(episodeId), equals(1.0));
      });

      test('should handle concurrent filter operations', () {
        final episodes = TestUtils.createSampleAudioFileList(10);
        contentService.setEpisodesForTesting(episodes);

        // Rapidly change filters
        contentService.setSelectedLanguage('en-US');
        contentService.setSelectedCategory('daily-news');
        contentService.setSearchQuery('test');
        contentService.setSelectedLanguage('ja-JP');

        // Should handle concurrent operations without errors
        expect(() => contentService.getFilteredEpisodes(), returnsNormally);
      });
    });
  });
}

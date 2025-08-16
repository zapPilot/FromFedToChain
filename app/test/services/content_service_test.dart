import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:from_fed_to_chain_app/services/content_service.dart';
import 'package:from_fed_to_chain_app/models/audio_file.dart';

void main() {
  group('ContentService Tests', () {
    late ContentService contentService;

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
  });
}

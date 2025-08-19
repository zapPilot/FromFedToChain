import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/services/content_service.dart';
import 'package:from_fed_to_chain_app/models/audio_file.dart';

void main() {
  group('ContentService Basic Tests', () {
    late ContentService contentService;

    setUp(() {
      contentService = ContentService();
    });

    tearDown(() {
      contentService.dispose();
    });

    test('initializes with default values', () {
      expect(contentService.selectedLanguage, 'zh-TW');
      expect(contentService.selectedCategory, 'all');
      expect(contentService.searchQuery, '');
      expect(contentService.isLoading, false);
      expect(contentService.hasError, false);
      expect(contentService.allEpisodes, isEmpty);
      expect(contentService.filteredEpisodes, isEmpty);
    });

    test('updates search query', () {
      const testQuery = 'bitcoin';
      contentService.setSearchQuery(testQuery);

      expect(contentService.searchQuery, testQuery);
    });

    test('tracks episode completion', () async {
      const episodeId = 'test-episode-1';
      const completion = 0.75;

      await contentService.updateEpisodeCompletion(episodeId, completion);

      expect(contentService.getEpisodeCompletion(episodeId), completion);
      expect(contentService.isEpisodeUnfinished(episodeId), true);
      expect(contentService.isEpisodeFinished(episodeId), false);
    });

    test('marks episode as finished', () async {
      const episodeId = 'test-episode-1';

      await contentService.markEpisodeAsFinished(episodeId);

      expect(contentService.getEpisodeCompletion(episodeId), 1.0);
      expect(contentService.isEpisodeFinished(episodeId), true);
      expect(contentService.isEpisodeUnfinished(episodeId), false);
    });

    test('handles listen history', () async {
      final testAudioFile = AudioFile(
        id: 'test-episode',
        title: 'Test Episode',
        language: 'en-US',
        category: 'daily-news',
        streamingUrl: 'https://example.com/test.m3u8',
        path: 'test.m3u8',
        lastModified: DateTime.now(),
      );

      await contentService.addToListenHistory(testAudioFile);

      expect(contentService.listenHistory,
          containsPair('test-episode', isA<DateTime>()));
    });

    test('validates language support', () async {
      // Valid languages should work
      await contentService.setLanguage('en-US');
      expect(contentService.selectedLanguage, 'en-US');

      await contentService.setLanguage('ja-JP');
      expect(contentService.selectedLanguage, 'ja-JP');

      await contentService.setLanguage('zh-TW');
      expect(contentService.selectedLanguage, 'zh-TW');
    });

    test('validates category support', () async {
      // Valid categories should work
      await contentService.setCategory('daily-news');
      expect(contentService.selectedCategory, 'daily-news');

      await contentService.setCategory('ethereum');
      expect(contentService.selectedCategory, 'ethereum');

      await contentService.setCategory('all');
      expect(contentService.selectedCategory, 'all');
    });

    test('creates playlists from episodes', () {
      final testEpisodes = [
        AudioFile(
          id: 'episode-1',
          title: 'Episode 1',
          language: 'en-US',
          category: 'daily-news',
          streamingUrl: 'https://example.com/episode1.m3u8',
          path: 'episode1.m3u8',
          lastModified: DateTime.now(),
        ),
        AudioFile(
          id: 'episode-2',
          title: 'Episode 2',
          language: 'en-US',
          category: 'daily-news',
          streamingUrl: 'https://example.com/episode2.m3u8',
          path: 'episode2.m3u8',
          lastModified: DateTime.now(),
        ),
      ];

      contentService.createPlaylist('Test Playlist', testEpisodes);

      expect(contentService.currentPlaylist, isNotNull);
      expect(contentService.currentPlaylist!.name, 'Test Playlist');
      expect(contentService.currentPlaylist!.episodes.length, 2);
    });

    test('handles sort order changes', () async {
      await contentService.setSortOrder('oldest');
      expect(contentService.sortOrder, 'oldest');

      await contentService.setSortOrder('alphabetical');
      expect(contentService.sortOrder, 'alphabetical');

      await contentService.setSortOrder('newest');
      expect(contentService.sortOrder, 'newest');
    });

    test('provides statistics', () {
      final stats = contentService.getStatistics();

      expect(stats, containsPair('totalEpisodes', isA<int>()));
      expect(stats, containsPair('filteredEpisodes', isA<int>()));
      expect(stats, containsPair('languages', isA<Map>()));
      expect(stats, containsPair('categories', isA<Map>()));
    });
  });
}

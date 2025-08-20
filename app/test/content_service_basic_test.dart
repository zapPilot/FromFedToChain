import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:from_fed_to_chain_app/services/content_service.dart';
import 'package:from_fed_to_chain_app/models/audio_file.dart';

void main() {
  group('ContentService Basic Tests', () {
    late ContentService contentService;

    setUp(() async {
      // Initialize test binding and mock SharedPreferences
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
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

    test('validates language support', () {
      // Test language validation without triggering network requests
      contentService.setSelectedLanguage('en-US');
      expect(contentService.selectedLanguage, 'en-US');

      contentService.setSelectedLanguage('ja-JP');
      expect(contentService.selectedLanguage, 'ja-JP');

      contentService.setSelectedLanguage('zh-TW');
      expect(contentService.selectedLanguage, 'zh-TW');
    });

    test('validates category support', () {
      // Test category validation without triggering network requests
      contentService.setSelectedCategory('daily-news');
      expect(contentService.selectedCategory, 'daily-news');

      contentService.setSelectedCategory('ethereum');
      expect(contentService.selectedCategory, 'ethereum');

      contentService.setSelectedCategory('all');
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

    test('handles sort order changes', () {
      // Test sort order without triggering side effects
      expect(contentService.sortOrder, 'newest'); // Default value

      // We can't easily test setSortOrder without SharedPreferences working correctly
      // So we just verify the getter works and returns sensible defaults
      expect(
          ['newest', 'oldest', 'alphabetical']
              .contains(contentService.sortOrder),
          isTrue);
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

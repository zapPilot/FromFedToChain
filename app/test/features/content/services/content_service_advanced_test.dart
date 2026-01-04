import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:from_fed_to_chain_app/features/content/services/content_service.dart';
import 'package:from_fed_to_chain_app/features/content/data/episode_repository.dart';
import 'package:from_fed_to_chain_app/features/content/data/content_repository.dart';
import 'package:from_fed_to_chain_app/features/content/data/progress_repository.dart';
import 'package:from_fed_to_chain_app/features/content/data/preferences_repository.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';

@GenerateMocks([
  EpisodeRepository,
  ContentRepository,
  ProgressRepository,
  PreferencesRepository
])
import 'content_service_advanced_test.mocks.dart';

void main() {
  group('ContentService Advanced Tests', () {
    late ContentService contentService;
    late MockEpisodeRepository mockEpisodeRepository;
    late MockContentRepository mockContentRepository;
    late MockProgressRepository mockProgressRepository;
    late MockPreferencesRepository mockPreferencesRepository;

    final testAudioFile = AudioFile(
      id: '2025-01-01-btc',
      title: 'Bitcoin News',
      language: 'zh-TW',
      category: 'daily-news',
      streamingUrl: 'https://example.com/audio.m3u8',
      path: 'audio.m3u8',
      lastModified: DateTime(2025, 1, 1),
      duration: const Duration(minutes: 10),
    );

    final testAudioFile2 = AudioFile(
      id: '2025-01-02-eth',
      title: 'Ethereum News',
      language: 'en-US',
      category: 'ethereum',
      streamingUrl: 'https://example.com/audio2.m3u8',
      path: 'audio2.m3u8',
      lastModified: DateTime(2025, 1, 2),
      duration: const Duration(minutes: 20),
    );

    setUp(() {
      mockEpisodeRepository = MockEpisodeRepository();
      mockContentRepository = MockContentRepository();
      mockProgressRepository = MockProgressRepository();
      mockPreferencesRepository = MockPreferencesRepository();

      // Default mock behaviors
      when(mockPreferencesRepository.selectedLanguage).thenReturn('zh-TW');
      when(mockPreferencesRepository.selectedCategory).thenReturn('all');
      when(mockPreferencesRepository.searchQuery).thenReturn('');
      when(mockPreferencesRepository.sortOrder).thenReturn('newest');
      when(mockProgressRepository.getListeningStatistics(any))
          .thenReturn({'total': 0});
      when(mockContentRepository.getCacheStatistics()).thenReturn({'count': 0});

      contentService = ContentService(
        episodeRepository: mockEpisodeRepository,
        contentRepository: mockContentRepository,
        progressRepository: mockProgressRepository,
        preferencesRepository: mockPreferencesRepository,
      );
    });

    test('getAudioFileById finds by exact match', () async {
      contentService.setEpisodesForTesting([testAudioFile, testAudioFile2]);

      final result = await contentService.getAudioFileById('2025-01-01-btc');
      expect(result, testAudioFile);
    });

    test('getAudioFileById finds by date pattern match', () async {
      contentService.setEpisodesForTesting([testAudioFile]);

      // Request with language suffix but same date in ID
      final result =
          await contentService.getAudioFileById('2025-01-01-btc-en-US');
      expect(result, testAudioFile);
    });

    test('advancedSearch filters by multiple criteria', () {
      contentService.setEpisodesForTesting([testAudioFile, testAudioFile2]);

      final results = contentService.advancedSearch(
        [testAudioFile, testAudioFile2],
        languages: ['en-US'],
        minDuration: const Duration(minutes: 15),
      );

      expect(results.length, 1);
      expect(results.first.id, testAudioFile2.id);
    });

    test('advancedSearch filters by date range', () {
      contentService.setEpisodesForTesting([testAudioFile, testAudioFile2]);

      final results = contentService.advancedSearch(
        [testAudioFile, testAudioFile2],
        dateFrom: DateTime(2025, 1, 2),
      );

      expect(results.length, 1);
      expect(results.first.id, testAudioFile2.id);
    });

    test('loadAllEpisodes handles errors', () async {
      when(mockEpisodeRepository.loadAllEpisodes())
          .thenThrow(Exception('Network Error'));

      await contentService.loadAllEpisodes();

      expect(contentService.hasError, true);
      expect(contentService.errorMessage, contains('Network Error'));
      expect(contentService.isLoading, false);
    });

    test('setLanguage validates input', () async {
      await contentService.setLanguage('invalid-lang');
      expect(contentService.errorMessage, contains('Unsupported language'));

      verifyNever(mockPreferencesRepository.setLanguage(any));
    });

    test('setCategory validates input', () async {
      await contentService.setCategory('invalid-cat');
      expect(contentService.errorMessage, contains('Unsupported category'));

      verifyNever(mockPreferencesRepository.setCategory(any));
    });

    test('search caching mechanism', () async {
      // Setup cache mock
      // This is tricky because _searchEpisodes uses _contentRepository for nothing related to caching?
      // Wait, _searchCache is internal to ContentService.
      // _searchEpisodes calls StreamingApiService.searchEpisodes if not local.
      // We can't easily mock static StreamingApiService.
      // But we can test that it returns local results and caches them without calling API if query matches local.

      contentService.setEpisodesForTesting([testAudioFile]);

      final results = await contentService.searchEpisodes('Bitcoin');
      expect(results, isNotEmpty);
      expect(results.first.title, 'Bitcoin News');

      // Second call should come from cache (internal verification hard, but ensures no crash)
      final results2 = await contentService.searchEpisodes('Bitcoin');
      expect(results2, isNotEmpty);
    });
  });
}

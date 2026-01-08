import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:from_fed_to_chain_app/features/content/services/content_service.dart';
import 'package:from_fed_to_chain_app/features/content/data/episode_repository.dart';
import 'package:from_fed_to_chain_app/features/content/data/content_repository.dart';
import 'package:from_fed_to_chain_app/features/content/data/progress_repository.dart';
import 'package:from_fed_to_chain_app/features/content/data/preferences_repository.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_content.dart';

import 'package:from_fed_to_chain_app/features/content/domain/use_cases/use_cases.dart';

@GenerateMocks([
  EpisodeRepository,
  ContentRepository,
  ProgressRepository,
  PreferencesRepository,
  LoadEpisodesUseCase,
  FilterEpisodesUseCase,
  SearchEpisodesUseCase
])
import 'content_service_coverage_test.mocks.dart';

void main() {
  group('ContentService Coverage Tests', () {
    late ContentService contentService;
    late MockContentRepository mockContentRepository;
    late MockProgressRepository mockProgressRepository;
    late MockPreferencesRepository mockPreferencesRepository;
    late MockLoadEpisodesUseCase mockLoadEpisodesUseCase;
    late MockFilterEpisodesUseCase mockFilterEpisodesUseCase;
    late MockSearchEpisodesUseCase mockSearchEpisodesUseCase;

    final testAudioFile = AudioFile(
      id: 'test-episode',
      title: 'Test Episode',
      language: 'en-US',
      category: 'daily-news',
      streamingUrl: 'https://example.com/audio.m3u8',
      path: 'audio.m3u8',
      lastModified: DateTime.now(),
      duration: const Duration(minutes: 10),
    );

    final testContent = AudioContent(
      id: 'test-content',
      title: 'Test Content',
      description: 'Some content',
      language: 'en-US',
      category: 'daily-news',
      date: DateTime.now(),
      status: 'published',
      updatedAt: DateTime.now(),
    );

    setUp(() {
      mockContentRepository = MockContentRepository();
      mockProgressRepository = MockProgressRepository();
      mockPreferencesRepository = MockPreferencesRepository();
      mockLoadEpisodesUseCase = MockLoadEpisodesUseCase();
      mockFilterEpisodesUseCase = MockFilterEpisodesUseCase();
      mockSearchEpisodesUseCase = MockSearchEpisodesUseCase();

      // Default stubs to prevent crashes in constructor
      when(mockProgressRepository.initialize()).thenAnswer((_) async {});
      when(mockPreferencesRepository.initialize()).thenAnswer((_) async {});
      when(mockPreferencesRepository.selectedLanguage).thenReturn('en-US');
      when(mockPreferencesRepository.selectedCategory).thenReturn('all');
      when(mockPreferencesRepository.searchQuery).thenReturn('');
      when(mockPreferencesRepository.sortOrder).thenReturn('newest');
      when(mockContentRepository.getCacheStatistics()).thenReturn({});
      when(mockProgressRepository.getListeningStatistics(any)).thenReturn({});

      // Mock filter use cases returning passed list by default
      when(mockFilterEpisodesUseCase.filterByLanguage(any, any))
          .thenAnswer((invocation) => invocation.positionalArguments[0]);
      when(mockFilterEpisodesUseCase.filterByCategory(any, any))
          .thenAnswer((invocation) => invocation.positionalArguments[0]);

      contentService = ContentService(
        contentRepository: mockContentRepository,
        progressRepository: mockProgressRepository,
        preferencesRepository: mockPreferencesRepository,
        loadEpisodesUseCase: mockLoadEpisodesUseCase,
        filterEpisodesUseCase: mockFilterEpisodesUseCase,
        searchEpisodesUseCase: mockSearchEpisodesUseCase,
      );
    });

    test('prefetchContent delegates to repository', () async {
      await contentService.prefetchContent([testAudioFile]);
      verify(mockContentRepository.prefetchContent([testAudioFile])).called(1);
    });

    test('clearContentCache delegates to repository', () {
      contentService.clearContentCache();
      verify(mockContentRepository.clearContentCache()).called(1);
    });

    test('cacheContent delegates to repository', () {
      contentService.cacheContent('id', 'en-US', 'daily-news', testContent);
      verify(mockContentRepository.cacheContent(
              'id', 'en-US', 'daily-news', testContent))
          .called(1);
    });

    test('getCachedContent delegates to repository', () {
      when(mockContentRepository.getCachedContent(any, any, any))
          .thenReturn(testContent);
      final result =
          contentService.getCachedContent('id', 'en-US', 'daily-news');
      expect(result, testContent);
      verify(mockContentRepository.getCachedContent(
              'id', 'en-US', 'daily-news'))
          .called(1);
    });

    test('dispose cleans up resources', () {
      // Call dispose twice to ensure idempotency
      contentService.dispose();
      contentService.dispose();

      // Should only be called once total
      verify(mockContentRepository.dispose()).called(1);
      verify(mockProgressRepository.dispose()).called(1);
      verify(mockPreferencesRepository.dispose()).called(1);
    });

    test('getDebugInfo returns correct structure', () {
      contentService.setEpisodesForTesting([testAudioFile]);

      final info = contentService.getDebugInfo(testAudioFile);

      expect(info['id'], testAudioFile.id);
      expect(info['totalEpisodes'], 1);
      expect(info['content_service'], 'ContentService');
      expect(info['audio_file'], isNotNull);
    });

    test('getDebugInfo handles null audio file', () {
      final info = contentService.getDebugInfo(null);
      expect(info['error'], 'No audio file provided');
    });

    test('Listen History Wrappers', () async {
      await contentService.removeFromListenHistory('episode-id');
      verify(mockProgressRepository.removeFromListenHistory('episode-id'))
          .called(1);

      await contentService.clearListenHistory();
      verify(mockProgressRepository.clearListenHistory()).called(1);
    });

    test('Progress Wrappers', () async {
      await contentService.setEpisodeCompletion('episode-id', 0.5);
      verify(mockProgressRepository.updateEpisodeCompletion('episode-id', 0.5))
          .called(1);

      when(mockProgressRepository.getEpisodeCompletion('episode-id'))
          .thenReturn(0.8);
      expect(contentService.getEpisodeCompletion('episode-id'), 0.8);
    });

    test('getStatistics returns correct structure', () {
      contentService.setEpisodesForTesting([testAudioFile]);

      final stats = contentService.getStatistics();

      expect(stats['totalEpisodes'], 1);
      expect(stats['listeningStats'], isNotNull);
      expect(stats['cacheStats'], isNotNull);
      expect(stats['selectedLanguage'], 'en-US');
    });

    test('clear calls all clear methods', () {
      contentService.setEpisodesForTesting([testAudioFile]);
      expect(contentService.allEpisodes, isNotEmpty);

      contentService.clear();

      expect(contentService.allEpisodes, isEmpty);
      expect(contentService.filteredEpisodes, isEmpty);
      verify(mockContentRepository.clearContentCache()).called(1);
    });

    test('fetchContentById delegates to repository', () async {
      when(mockContentRepository.fetchContentById(any, any, any))
          .thenAnswer((_) async => testContent);

      final result = await contentService.fetchContentById('id', 'lang', 'cat');
      expect(result, testContent);
    });

    test('getContentForAudioFile delegates to repository', () async {
      when(mockContentRepository.getContentForAudioFile(any))
          .thenAnswer((_) async => testContent);

      final result = await contentService.getContentForAudioFile(testAudioFile);
      expect(result, testContent);
    });
  });
}

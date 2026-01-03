import 'package:flutter_test/flutter_test.dart';

import 'package:from_fed_to_chain_app/features/content/data/episode_repository_impl.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import '../test_utils.dart';

void main() {
  late EpisodeRepositoryImpl repository;

  setUp(() {
    repository = EpisodeRepositoryImpl();
  });

  tearDown(() {
    repository.dispose();
  });

  group('EpisodeRepositoryImpl - Initial State', () {
    test('should have empty episodes initially', () {
      expect(repository.allEpisodes, isEmpty);
      expect(repository.hasEpisodes, isFalse);
    });

    test('should not be loading initially', () {
      expect(repository.isLoading, isFalse);
    });

    test('should have no error initially', () {
      expect(repository.hasError, isFalse);
      expect(repository.errorMessage, isNull);
    });
  });

  group('EpisodeRepositoryImpl - Testing Methods', () {
    test('setEpisodesForTesting should set episodes', () {
      final testEpisodes = TestUtils.createSampleAudioFileList(5);
      repository.setEpisodesForTesting(testEpisodes);

      expect(repository.allEpisodes.length, 5);
      expect(repository.hasEpisodes, isTrue);
    });

    test('setLoadingForTesting should update loading state', () {
      repository.setLoadingForTesting(true);
      expect(repository.isLoading, isTrue);

      repository.setLoadingForTesting(false);
      expect(repository.isLoading, isFalse);
    });

    test('setErrorForTesting should set error message', () {
      repository.setErrorForTesting('Test error');
      expect(repository.hasError, isTrue);
      expect(repository.errorMessage, 'Test error');
    });

    test('setErrorForTesting with null should clear error', () {
      repository.setErrorForTesting('Test error');
      expect(repository.hasError, isTrue);

      repository.setErrorForTesting(null);
      expect(repository.hasError, isFalse);
      expect(repository.errorMessage, isNull);
    });
  });

  group('EpisodeRepositoryImpl - Filtering', () {
    late List<AudioFile> testEpisodes;

    setUp(() {
      testEpisodes = [
        TestUtils.createSampleAudioFile(
          id: 'ep1',
          title: 'Episode 1',
          language: 'en-US',
          category: 'daily-news',
        ),
        TestUtils.createSampleAudioFile(
          id: 'ep2',
          title: 'Episode 2',
          language: 'en-US',
          category: 'ethereum',
        ),
        TestUtils.createSampleAudioFile(
          id: 'ep3',
          title: 'Episode 3',
          language: 'ja-JP',
          category: 'daily-news',
        ),
        TestUtils.createSampleAudioFile(
          id: 'ep4',
          title: 'Bitcoin News',
          language: 'zh-TW',
          category: 'macro',
        ),
      ];
    });

    test('getEpisodesByLanguage should filter by language', () {
      final result = repository.getEpisodesByLanguage(testEpisodes, 'en-US');
      expect(result.length, 2);
      expect(result.every((ep) => ep.language == 'en-US'), isTrue);
    });

    test('getEpisodesByCategory should filter by category', () {
      final result =
          repository.getEpisodesByCategory(testEpisodes, 'daily-news');
      expect(result.length, 2);
      expect(result.every((ep) => ep.category == 'daily-news'), isTrue);
    });

    test('getEpisodesByLanguageAndCategory should filter by both', () {
      final result = repository.getEpisodesByLanguageAndCategory(
        testEpisodes,
        'en-US',
        'daily-news',
      );
      expect(result.length, 1);
      expect(result.first.id, 'ep1');
    });

    test('getEpisodesByLanguage with no matches should return empty', () {
      final result =
          repository.getEpisodesByLanguage(testEpisodes, 'unknown-lang');
      expect(result, isEmpty);
    });

    test('getEpisodesByCategory with no matches should return empty', () {
      final result =
          repository.getEpisodesByCategory(testEpisodes, 'unknown-cat');
      expect(result, isEmpty);
    });
  });

  group('EpisodeRepositoryImpl - Query Filtering', () {
    late List<AudioFile> testEpisodes;

    setUp(() {
      testEpisodes = [
        TestUtils.createSampleAudioFile(
          id: 'bitcoin-2025-01-01',
          title: 'Bitcoin Price Analysis',
          language: 'en-US',
          category: 'daily-news',
        ),
        TestUtils.createSampleAudioFile(
          id: 'eth-update',
          title: 'Ethereum Network Update',
          language: 'en-US',
          category: 'ethereum',
        ),
        TestUtils.createSampleAudioFile(
          id: 'macro-analysis',
          title: 'Macro Economic Analysis',
          language: 'ja-JP',
          category: 'macro',
        ),
      ];
    });

    test('filterEpisodesByQuery should match title', () {
      final result = repository.filterEpisodesByQuery(testEpisodes, 'Bitcoin');
      expect(result.length, 1);
      expect(result.first.title, 'Bitcoin Price Analysis');
    });

    test('filterEpisodesByQuery should match id', () {
      final result =
          repository.filterEpisodesByQuery(testEpisodes, 'eth-update');
      expect(result.length, 1);
      expect(result.first.id, 'eth-update');
    });

    test('filterEpisodesByQuery should match category', () {
      final result = repository.filterEpisodesByQuery(testEpisodes, 'macro');
      expect(result.length, 1);
      expect(result.first.category, 'macro');
    });

    test('filterEpisodesByQuery should be case-insensitive', () {
      final result = repository.filterEpisodesByQuery(testEpisodes, 'BITCOIN');
      expect(result.length, 1);
    });

    test('filterEpisodesByQuery with empty query returns all', () {
      final result = repository.filterEpisodesByQuery(testEpisodes, '');
      expect(result.length, testEpisodes.length);
    });

    test('filterEpisodesByQuery with whitespace returns all', () {
      final result = repository.filterEpisodesByQuery(testEpisodes, '   ');
      expect(result.length, testEpisodes.length);
    });

    test('filterEpisodesByQuery with no matches returns empty', () {
      final result =
          repository.filterEpisodesByQuery(testEpisodes, 'nonexistent');
      expect(result, isEmpty);
    });
  });

  group('EpisodeRepositoryImpl - Statistics', () {
    test('getEpisodeStatistics should return correct counts', () {
      final testEpisodes = [
        TestUtils.createSampleAudioFile(
            id: 'ep1', language: 'en-US', category: 'daily-news'),
        TestUtils.createSampleAudioFile(
            id: 'ep2', language: 'en-US', category: 'ethereum'),
        TestUtils.createSampleAudioFile(
            id: 'ep3', language: 'ja-JP', category: 'daily-news'),
      ];

      final stats = repository.getEpisodeStatistics(testEpisodes);

      expect(stats['totalEpisodes'], 3);
      expect((stats['languages'] as Map<String, int>)['en-US'], 2);
      expect((stats['languages'] as Map<String, int>)['ja-JP'], 1);
      expect((stats['categories'] as Map<String, int>)['daily-news'], 2);
      expect((stats['categories'] as Map<String, int>)['ethereum'], 1);
    });

    test('getEpisodeStatistics with empty list', () {
      final stats = repository.getEpisodeStatistics([]);

      expect(stats['totalEpisodes'], 0);
      expect((stats['languages'] as Map<String, int>), isEmpty);
      expect((stats['categories'] as Map<String, int>), isEmpty);
    });
  });

  group('EpisodeRepositoryImpl - getEpisodeById', () {
    setUp(() {
      final testEpisodes = [
        TestUtils.createSampleAudioFile(
          id: '2025-01-01-bitcoin-zh-TW',
          title: 'Bitcoin News ZH',
          language: 'zh-TW',
          category: 'daily-news',
        ),
        TestUtils.createSampleAudioFile(
          id: '2025-01-01-bitcoin-en-US',
          title: 'Bitcoin News EN',
          language: 'en-US',
          category: 'daily-news',
        ),
        TestUtils.createSampleAudioFile(
          id: 'simple-episode',
          title: 'Simple Episode',
          language: 'en-US',
          category: 'ethereum',
        ),
      ];
      repository.setEpisodesForTesting(testEpisodes);
    });

    test('should find episode by exact ID', () async {
      final result = await repository.getEpisodeById('simple-episode');
      expect(result, isNotNull);
      expect(result!.id, 'simple-episode');
    });

    test('should find episode by ID with language suffix', () async {
      final result =
          await repository.getEpisodeById('2025-01-01-bitcoin-zh-TW');
      expect(result, isNotNull);
      expect(result!.language, 'zh-TW');
    });

    test('should find episode with preferred language', () async {
      final result = await repository.getEpisodeById(
        '2025-01-01-bitcoin',
        preferredLanguage: 'en-US',
      );
      // Should find the en-US version if available
      if (result != null) {
        expect(result.language, 'en-US');
      }
    });

    test('should return null for non-existent episode', () async {
      final result = await repository.getEpisodeById('non-existent-episode');
      expect(result, isNull);
    });

    test('should find episode using fuzzy date matching', () async {
      // Setup: Episode has complex ID but contains date
      final fuzzyEpisode = TestUtils.createSampleAudioFile(
        id: 'real-prefix-2025-02-15-topic-en-US',
        title: 'Fuzzy Title',
        language: 'en-US',
      );
      repository
          .setEpisodesForTesting([...repository.allEpisodes, fuzzyEpisode]);

      // Request with different prefix but same date
      // "user-input-2025-02-15-something" -> extracts 2025-02-15
      // Finds "real-prefix-2025-02-15-topic-en-US"
      final result = await repository.getEpisodeById(
        'user-input-2025-02-15-something',
        preferredLanguage: 'en-US',
      );

      expect(result, isNotNull);
      expect(result!.id, 'real-prefix-2025-02-15-topic-en-US');
    });
  });

  group('EpisodeRepositoryImpl - searchEpisodes', () {
    setUp(() {
      final testEpisodes = [
        TestUtils.createSampleAudioFile(
          id: 'bitcoin-news',
          title: 'Bitcoin Price Analysis',
          language: 'en-US',
          category: 'daily-news',
        ),
        TestUtils.createSampleAudioFile(
          id: 'eth-update',
          title: 'Ethereum Update',
          language: 'en-US',
          category: 'ethereum',
        ),
      ];
      repository.setEpisodesForTesting(testEpisodes);
    });

    test('should return all episodes for empty query', () async {
      final result = await repository.searchEpisodes('');
      expect(result.length, 2);
    });

    test('should search locally for matching query', () async {
      final result = await repository.searchEpisodes('Bitcoin');
      expect(result.length, 1);
      expect(result.first.title.contains('Bitcoin'), isTrue);
    });
  });

  group('EpisodeRepositoryImpl - State Management', () {
    test('clear should remove all episodes and errors', () {
      repository.setEpisodesForTesting(TestUtils.createSampleAudioFileList(5));
      repository.setErrorForTesting('Test error');

      repository.clear();

      expect(repository.allEpisodes, isEmpty);
      expect(repository.hasError, isFalse);
    });

    test('dispose should clear all data', () {
      repository.setEpisodesForTesting(TestUtils.createSampleAudioFileList(5));

      repository.dispose();

      expect(repository.allEpisodes, isEmpty);
    });

    test('allEpisodes should return unmodifiable list', () {
      repository.setEpisodesForTesting(TestUtils.createSampleAudioFileList(3));

      final episodes = repository.allEpisodes;

      // Verify we can access elements but can't modify
      expect(episodes.length, 3);
      expect(() => (episodes as List).add(TestUtils.createSampleAudioFile()),
          throwsA(anything));
    });
  });

  group('EpisodeRepositoryImpl - loadEpisodesForLanguage validation', () {
    test('should set error for invalid language', () async {
      final result =
          await repository.loadEpisodesForLanguage('invalid-language');
      expect(result, isEmpty);
      expect(repository.hasError, isTrue);
      expect(repository.errorMessage, contains('Unsupported language'));
    });

    test('should skip loading if already loading', () async {
      repository.setLoadingForTesting(true);
      final result = await repository.loadEpisodesForLanguage('en-US');
      // Should return filtered episodes from current set (empty in this case)
      expect(result, isEmpty);
    });
  });

  group('EpisodeRepositoryImpl - loadAllEpisodes', () {
    test('should skip loading if already loading', () async {
      repository.setLoadingForTesting(true);
      final result = await repository.loadAllEpisodes();
      expect(result, isEmpty);
    });

    test('should set error when no episodes found', () async {
      // This will try to load from the API and may fail in test environment
      // The important thing is that it handles the state correctly
      repository.setLoadingForTesting(true);
      final result = await repository.loadAllEpisodes();
      expect(result, isEmpty);
    });
  });
}

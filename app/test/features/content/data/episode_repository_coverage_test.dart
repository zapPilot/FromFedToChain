import 'package:flutter_test/flutter_test.dart';
import 'package:from_fed_to_chain_app/features/content/data/episode_repository_impl.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';

void main() {
  group('EpisodeRepositoryImpl Coverage Tests', () {
    late EpisodeRepositoryImpl repository;
    late AudioFile baseEpisodeEn;
    late AudioFile baseEpisodeZh;
    late AudioFile dateEpisode;

    setUp(() {
      repository = EpisodeRepositoryImpl();

      baseEpisodeEn = AudioFile(
        id: '2024-01-01-episode-1-en-US',
        title: 'Episode 1 English',
        language: 'en-US',
        category: 'daily-news',
        streamingUrl: 'url',
        path: 'path',
        duration: const Duration(minutes: 5),
        lastModified: DateTime.now(),
      );

      baseEpisodeZh = AudioFile(
        id: '2024-01-01-episode-1-zh-TW',
        title: 'Episode 1 Chinese',
        language: 'zh-TW',
        category: 'daily-news',
        streamingUrl: 'url',
        path: 'path',
        duration: const Duration(minutes: 5),
        lastModified: DateTime.now(),
      );

      dateEpisode = AudioFile(
        id: '2025-01-01-news-en-US',
        title: 'News Jan 1',
        language: 'en-US',
        category: 'daily-news',
        streamingUrl: 'url',
        path: 'path',
        duration: const Duration(minutes: 5),
        lastModified: DateTime.now(),
      );

      repository
          .setEpisodesForTesting([baseEpisodeEn, baseEpisodeZh, dateEpisode]);
    });

    test('getEpisodeById Strategy 1: Exact Match', () async {
      final result =
          await repository.getEpisodeById('2024-01-01-episode-1-en-US');
      expect(result, equals(baseEpisodeEn));
    });

    test('getEpisodeById Strategy 2.1: Base ID + Preferred Language', () async {
      // asking for "episode-1" with pref "zh-TW" -> should find "episode-1-zh-TW"
      final result = await repository.getEpisodeById('2024-01-01-episode-1',
          preferredLanguage: 'zh-TW');
      expect(result, equals(baseEpisodeZh));
    });

    test(
        'getEpisodeById Strategy 2.2: ID with wrong suffix + Preferred Language overrides check',
        () async {
      // Current implementation prioritizes Exact Match (Strategy 1).
      // If we provide a full ID '...-en-US', it returns EN episode, ignoring preferredLanguage 'zh-TW'.
      final result = await repository.getEpisodeById(
          '2024-01-01-episode-1-en-US',
          preferredLanguage: 'zh-TW');
      expect(result, equals(baseEpisodeEn));
    });

    test('getEpisodeById Strategy 3: Fuzzy Date Match', () async {
      // asking for "2025-01-01-something-else" -> should find "2025-01-01-news-en-US"
      final result = await repository.getEpisodeById('2025-01-01-other');
      expect(result, equals(dateEpisode));
    });

    test('getEpisodeById Strategy 3 + Language', () async {
      // Setup another date episode in ZH
      final dateEpisodeZh = AudioFile(
          id: '2025-01-01-news-zh-TW',
          title: 'News Jan 1 ZH',
          language: 'zh-TW',
          category: 'daily-news',
          streamingUrl: 'url',
          path: 'p',
          duration: Duration.zero,
          lastModified: DateTime.now());
      repository.setEpisodesForTesting([dateEpisode, dateEpisodeZh]);

      // asking for arbitrary ID with date, pref ZH
      final result = await repository.getEpisodeById('2025-01-01-something',
          preferredLanguage: 'zh-TW');
      expect(result, equals(dateEpisodeZh));
    });

    test('getEpisodeById returns null when empty', () async {
      repository.setEpisodesForTesting([]);
      // Should try to load (which will probably fail or return empty if we mock StreamingApiService, but here strict test)
      // Actually `loadAllEpisodes` calls static `StreamingApiService`.
      // This test might fail if it calls network.
      // Line 208: if empty, await loadAllEpisodes().
      // If loadAllEpisodes fails, it returns empty list (line 47).
      // So it should return null.

      final result = await repository.getEpisodeById('missing');
      expect(result, isNull);
    });

    test('searchEpisodes use local filter', () async {
      final result = await repository.searchEpisodes('Chinese');
      expect(result, contains(baseEpisodeZh));
      expect(result, isNot(contains(baseEpisodeEn)));
    });

    test('searchEpisodes empty query returns all', () async {
      final result = await repository.searchEpisodes('');
      expect(result.length, 3);
    });

    test('re-entry protection (via public getters)', () async {
      repository.setLoadingForTesting(true);
      expect(repository.isLoading, isTrue);

      // calling loadAllEpisodes should return immediately
      final futures = await repository.loadAllEpisodes();
      expect(futures.length, 3); // stored list
    });

    test('Language check', () async {
      final result = await repository.loadEpisodesForLanguage('invalid-lang');
      expect(result, isEmpty);
      expect(repository.hasError, isTrue);
      expect(repository.errorMessage, contains('Unsupported language'));
    });

    test('getEpisodesByLanguage filtering', () {
      final res =
          repository.getEpisodesByLanguage(repository.allEpisodes, 'zh-TW');
      expect(res.length, 1);
      expect(res.first, equals(baseEpisodeZh));
    });

    test('getEpisodesByCategory filtering', () {
      final res = repository.getEpisodesByCategory(
          repository.allEpisodes, 'daily-news');
      expect(res.length, 3);
    });

    test('getEpisodesByLanguageAndCategory filtering', () {
      final res = repository.getEpisodesByLanguageAndCategory(
          repository.allEpisodes, 'zh-TW', 'daily-news');
      expect(res.length, 1);
      expect(res.first, equals(baseEpisodeZh));
    });

    test('getEpisodeStatistics', () {
      final stats = repository.getEpisodeStatistics(repository.allEpisodes);
      expect(stats['totalEpisodes'], 3);
      expect((stats['languages'] as Map)['en-US'], 2);
      expect((stats['categories'] as Map)['daily-news'], 3);
    });
  });
}

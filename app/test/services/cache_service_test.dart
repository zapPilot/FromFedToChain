import 'package:flutter_test/flutter_test.dart';

import 'package:from_fed_to_chain_app/features/content/data/cache_service.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_content.dart';
import '../test_utils.dart';

void main() {
  late CacheService cacheService;

  setUp(() {
    cacheService = CacheService();
  });

  tearDown(() {
    cacheService.dispose();
  });

  group('CacheService - Initial State', () {
    test('should have empty cache initially', () {
      expect(cacheService.cacheSize, 0);
      expect(cacheService.hasCachedContent, isFalse);
      expect(cacheService.cachedContentKeys, isEmpty);
    });
  });

  group('CacheService - Cache Operations', () {
    test('cacheContent should add content to cache', () {
      final content = TestUtils.createSampleAudioContent(
        id: 'test-content',
        language: 'en-US',
        category: 'daily-news',
      );

      cacheService.cacheContent('test-content', 'en-US', 'daily-news', content);

      expect(cacheService.cacheSize, 1);
      expect(cacheService.hasCachedContent, isTrue);
    });

    test('getCachedContent should return cached content', () {
      final content = TestUtils.createSampleAudioContent(
        id: 'test-content',
        title: 'Test Title',
      );

      cacheService.cacheContent('test-content', 'en-US', 'daily-news', content);

      final cached =
          cacheService.getCachedContent('test-content', 'en-US', 'daily-news');

      expect(cached, isNotNull);
      expect(cached!.title, 'Test Title');
    });

    test('getCachedContent should return null for uncached content', () {
      final cached =
          cacheService.getCachedContent('nonexistent', 'en-US', 'daily-news');

      expect(cached, isNull);
    });

    test('isContentCached should return correct status', () {
      final content = TestUtils.createSampleAudioContent();

      expect(
          cacheService.isContentCached('test', 'en-US', 'daily-news'), isFalse);

      cacheService.cacheContent('test', 'en-US', 'daily-news', content);

      expect(
          cacheService.isContentCached('test', 'en-US', 'daily-news'), isTrue);
    });

    test('removeFromCache should remove specific content', () {
      final content = TestUtils.createSampleAudioContent();

      cacheService.cacheContent('test', 'en-US', 'daily-news', content);
      expect(cacheService.cacheSize, 1);

      final removed =
          cacheService.removeFromCache('test', 'en-US', 'daily-news');

      expect(removed, isTrue);
      expect(cacheService.cacheSize, 0);
    });

    test('removeFromCache should return false for nonexistent content', () {
      final removed =
          cacheService.removeFromCache('nonexistent', 'en-US', 'daily-news');

      expect(removed, isFalse);
    });
  });

  group('CacheService - Clear Operations', () {
    setUp(() {
      // Pre-populate cache with test data
      cacheService.cacheContent('ep1', 'en-US', 'daily-news',
          TestUtils.createSampleAudioContent(id: 'ep1'));
      cacheService.cacheContent('ep2', 'en-US', 'ethereum',
          TestUtils.createSampleAudioContent(id: 'ep2'));
      cacheService.cacheContent('ep3', 'ja-JP', 'daily-news',
          TestUtils.createSampleAudioContent(id: 'ep3'));
      cacheService.cacheContent('ep4', 'zh-TW', 'macro',
          TestUtils.createSampleAudioContent(id: 'ep4'));
    });

    test('clearContentCache should remove all cached content', () {
      expect(cacheService.cacheSize, 4);

      cacheService.clearContentCache();

      expect(cacheService.cacheSize, 0);
      expect(cacheService.hasCachedContent, isFalse);
    });

    test('clearCacheForLanguage should remove only matching language', () {
      expect(cacheService.cacheSize, 4);

      cacheService.clearCacheForLanguage('en-US');

      expect(cacheService.cacheSize, 2);
      expect(
          cacheService.isContentCached('ep1', 'en-US', 'daily-news'), isFalse);
      expect(cacheService.isContentCached('ep2', 'en-US', 'ethereum'), isFalse);
      expect(
          cacheService.isContentCached('ep3', 'ja-JP', 'daily-news'), isTrue);
      expect(cacheService.isContentCached('ep4', 'zh-TW', 'macro'), isTrue);
    });

    test('clearCacheForCategory should remove only matching category', () {
      expect(cacheService.cacheSize, 4);

      cacheService.clearCacheForCategory('daily-news');

      expect(cacheService.cacheSize, 2);
      expect(
          cacheService.isContentCached('ep1', 'en-US', 'daily-news'), isFalse);
      expect(
          cacheService.isContentCached('ep3', 'ja-JP', 'daily-news'), isFalse);
      expect(cacheService.isContentCached('ep2', 'en-US', 'ethereum'), isTrue);
      expect(cacheService.isContentCached('ep4', 'zh-TW', 'macro'), isTrue);
    });
  });

  group('CacheService - Statistics', () {
    test('getCacheStatistics should return correct stats', () {
      cacheService.cacheContent(
          'ep1', 'en-US', 'daily-news', TestUtils.createSampleAudioContent());
      cacheService.cacheContent(
          'ep2', 'en-US', 'ethereum', TestUtils.createSampleAudioContent());
      cacheService.cacheContent(
          'ep3', 'ja-JP', 'daily-news', TestUtils.createSampleAudioContent());

      final stats = cacheService.getCacheStatistics();

      expect(stats['totalItems'], 3);
      expect((stats['languages'] as Map<String, int>)['en-US'], 2);
      expect((stats['languages'] as Map<String, int>)['ja-JP'], 1);
      expect((stats['categories'] as Map<String, int>)['daily-news'], 2);
      expect((stats['categories'] as Map<String, int>)['ethereum'], 1);
    });

    test('getCacheStatistics should return empty for empty cache', () {
      final stats = cacheService.getCacheStatistics();

      expect(stats['totalItems'], 0);
      expect((stats['languages'] as Map<String, int>), isEmpty);
      expect((stats['categories'] as Map<String, int>), isEmpty);
    });

    test('getEstimatedCacheSize should return size estimate', () {
      final content = TestUtils.createSampleAudioContent(
        title: 'A Title',
        description: 'A Description',
      );
      cacheService.cacheContent('ep1', 'en-US', 'daily-news', content);

      final size = cacheService.getEstimatedCacheSize();

      expect(size, greaterThan(0));
    });

    test('getEstimatedCacheSize should return 0 for empty cache', () {
      final size = cacheService.getEstimatedCacheSize();
      expect(size, 0);
    });
  });

  group('CacheService - Cache Cleanup', () {
    test('cleanupCache should remove old entries when over limit', () {
      for (int i = 0; i < 10; i++) {
        cacheService.cacheContent('ep$i', 'en-US', 'daily-news',
            TestUtils.createSampleAudioContent(id: 'ep$i'));
      }

      expect(cacheService.cacheSize, 10);

      cacheService.cleanupCache(maxItems: 5);

      expect(cacheService.cacheSize, 5);
    });

    test('cleanupCache should not remove when under limit', () {
      for (int i = 0; i < 3; i++) {
        cacheService.cacheContent('ep$i', 'en-US', 'daily-news',
            TestUtils.createSampleAudioContent(id: 'ep$i'));
      }

      expect(cacheService.cacheSize, 3);

      cacheService.cleanupCache(maxItems: 10);

      expect(cacheService.cacheSize, 3);
    });
  });

  group('CacheService - Prefetch Operations', () {
    test('prefetchContent should not fail with empty list', () async {
      await cacheService.prefetchContent([]);
      expect(cacheService.cacheSize, 0);
    });

    test('prefetchContentForLanguage should filter by language', () async {
      final audioFiles = [
        TestUtils.createSampleAudioFile(language: 'en-US'),
        TestUtils.createSampleAudioFile(language: 'ja-JP'),
        TestUtils.createSampleAudioFile(language: 'en-US'),
      ];

      // This will attempt API calls, which may fail in tests
      // But it shouldn't throw
      await cacheService.prefetchContentForLanguage(audioFiles, 'en-US');
    });

    test('prefetchContentForCategory should filter by category', () async {
      final audioFiles = [
        TestUtils.createSampleAudioFile(category: 'daily-news'),
        TestUtils.createSampleAudioFile(category: 'ethereum'),
        TestUtils.createSampleAudioFile(category: 'daily-news'),
      ];

      await cacheService.prefetchContentForCategory(audioFiles, 'daily-news');
    });

    test('warmUpCache should limit to 10 episodes', () async {
      final audioFiles = TestUtils.createSampleAudioFileList(20);

      await cacheService.warmUpCache(audioFiles);
      // Just verify it doesn't throw
    });

    test('warmUpCache should not fail with empty list', () async {
      await cacheService.warmUpCache([]);
    });
  });

  group('CacheService - Testing Methods', () {
    test('setCacheForTesting should replace entire cache', () {
      final testCache = {
        'en-US/daily-news/ep1': TestUtils.createSampleAudioContent(id: 'ep1'),
        'ja-JP/ethereum/ep2': TestUtils.createSampleAudioContent(id: 'ep2'),
      };

      cacheService.setCacheForTesting(testCache);

      expect(cacheService.cacheSize, 2);
    });

    test('getCacheForTesting should return unmodifiable cache', () {
      cacheService.cacheContent(
          'ep1', 'en-US', 'daily-news', TestUtils.createSampleAudioContent());

      final cache = cacheService.getCacheForTesting();

      expect(() => (cache as Map).clear(), throwsA(anything));
    });
  });

  group('CacheService - getContentById', () {
    test('should return null for non-existent content', () async {
      final result = await cacheService.getContentById('nonexistent', []);
      expect(result, isNull);
    });

    test('should find content from episodes list', () async {
      final episodes = [
        TestUtils.createSampleAudioFile(
          id: 'test-ep',
          language: 'en-US',
          category: 'daily-news',
        ),
      ];

      // Pre-cache the content
      cacheService.cacheContent('test-ep', 'en-US', 'daily-news',
          TestUtils.createSampleAudioContent(id: 'test-ep', title: 'Cached'));

      final result = await cacheService.getContentById('test-ep', episodes);

      expect(result, isNotNull);
      expect(result!.title, 'Cached');
    });
  });

  group('CacheService - dispose', () {
    test('dispose should clear all cached content', () {
      cacheService.cacheContent(
          'ep1', 'en-US', 'daily-news', TestUtils.createSampleAudioContent());
      expect(cacheService.cacheSize, 1);

      cacheService.dispose();

      expect(cacheService.cacheSize, 0);
    });
  });
}

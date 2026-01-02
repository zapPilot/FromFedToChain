import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'package:from_fed_to_chain_app/features/content/data/api_repository.dart';
import 'package:from_fed_to_chain_app/core/config/api_config.dart';

void main() {
  late Dio dio;
  late DioAdapter dioAdapter;

  setUp(() {
    // Reset the singleton before each test
    ApiRepository.reset();

    // Create Dio with mock adapter
    dio = Dio();
    dioAdapter = DioAdapter(dio: dio);

    // Inject into repository
    ApiRepository.instance.setDioForTesting(dio);
  });

  tearDown(() {
    ApiRepository.reset();
  });

  group('ApiRepository Singleton', () {
    test('should return the same instance', () {
      final instance1 = ApiRepository.instance;
      final instance2 = ApiRepository.instance;
      expect(identical(instance1, instance2), isTrue);
    });

    test('reset should create new instance', () {
      final instance1 = ApiRepository.instance;
      ApiRepository.reset();
      final instance2 = ApiRepository.instance;
      expect(identical(instance1, instance2), isFalse);
    });
  });

  group('getEpisodesForLanguageAndCategory', () {
    test('should return list of AudioFiles on success', () async {
      final url = ApiConfig.getListUrl('zh-TW', 'daily-news');

      dioAdapter.onGet(
        url,
        (server) => server.reply(200, [
          {
            'id': 'test-episode',
            'path': 'audio/zh-TW/daily-news/test-episode/audio.m3u8',
            'title': 'Test Episode',
            'last_modified': '2025-01-01T00:00:00Z',
          },
        ]),
      );

      final result = await ApiRepository.instance
          .getEpisodesForLanguageAndCategory('zh-TW', 'daily-news');

      expect(result, isA<List>());
      expect(result.length, 1);
      expect(result.first.title, 'Test Episode');
      expect(result.first.language, 'zh-TW');
      expect(result.first.category, 'daily-news');
    });

    test('should return empty list when response is empty', () async {
      final url = ApiConfig.getListUrl('en-US', 'ethereum');

      dioAdapter.onGet(
        url,
        (server) => server.reply(200, []),
      );

      final result = await ApiRepository.instance
          .getEpisodesForLanguageAndCategory('en-US', 'ethereum');

      expect(result, isEmpty);
    });

    test('should skip items without path', () async {
      final url = ApiConfig.getListUrl('en-US', 'macro');

      dioAdapter.onGet(
        url,
        (server) => server.reply(200, [
          {'title': 'No Path Episode'},
          {
            'id': 'valid-episode',
            'path': 'audio/en-US/macro/valid-episode/audio.m3u8',
            'title': 'Valid Episode',
          },
        ]),
      );

      final result = await ApiRepository.instance
          .getEpisodesForLanguageAndCategory('en-US', 'macro');

      expect(result.length, 1);
      expect(result.first.title, 'Valid Episode');
    });

    test('should throw on network error', () async {
      final url = ApiConfig.getListUrl('zh-TW', 'daily-news');

      dioAdapter.onGet(
        url,
        (server) => server.throws(
          0,
          DioException(
            requestOptions: RequestOptions(path: url),
            type: DioExceptionType.connectionError,
          ),
        ),
      );

      expect(
        () => ApiRepository.instance
            .getEpisodesForLanguageAndCategory('zh-TW', 'daily-news'),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('getEpisodesForLanguage', () {
    test('should aggregate episodes from all categories', () async {
      for (final category in ApiConfig.supportedCategories) {
        final url = ApiConfig.getListUrl('en-US', category);
        dioAdapter.onGet(
          url,
          (server) => server.reply(200, [
            {
              'id': 'ep-$category',
              'path': 'audio/en-US/$category/ep-$category/audio.m3u8',
              'title': 'Episode from $category',
              'last_modified': '2025-01-01T00:00:00Z',
            },
          ]),
        );
      }

      final result =
          await ApiRepository.instance.getEpisodesForLanguage('en-US');

      expect(result.length, ApiConfig.supportedCategories.length);
    });

    test('should sort episodes by date (newest first)', () async {
      int dateCounter = 10;
      for (final category in ApiConfig.supportedCategories) {
        final url = ApiConfig.getListUrl('zh-TW', category);
        dateCounter++;
        dioAdapter.onGet(
          url,
          (server) => server.reply(200, [
            {
              'id': 'ep-$category',
              'path': 'audio/zh-TW/$category/ep/audio.m3u8',
              'title': 'Episode from $category',
              'last_modified':
                  '2025-01-${dateCounter.toString().padLeft(2, '0')}T00:00:00Z',
            },
          ]),
        );
      }

      final result =
          await ApiRepository.instance.getEpisodesForLanguage('zh-TW');

      // Verify sorted by date descending
      for (int i = 0; i < result.length - 1; i++) {
        expect(
          result[i].lastModified.isAfter(result[i + 1].lastModified) ||
              result[i]
                  .lastModified
                  .isAtSameMomentAs(result[i + 1].lastModified),
          isTrue,
        );
      }
    });
  });

  group('getAllEpisodes', () {
    test('should aggregate episodes from all languages and categories',
        () async {
      for (final language in ApiConfig.supportedLanguages) {
        for (final category in ApiConfig.supportedCategories) {
          final url = ApiConfig.getListUrl(language, category);
          dioAdapter.onGet(
            url,
            (server) => server.reply(200, [
              {
                'id': 'ep-$language-$category',
                'path': 'audio/$language/$category/ep/audio.m3u8',
                'title': 'Test Episode $language $category',
                'last_modified': '2025-01-01T00:00:00Z',
              },
            ]),
          );
        }
      }

      final result = await ApiRepository.instance.getAllEpisodes();

      // Should have episode for each language/category combination
      final expectedCount = ApiConfig.supportedLanguages.length *
          ApiConfig.supportedCategories.length;
      expect(result.length, expectedCount);
    });
  });

  group('searchEpisodes', () {
    test('should filter episodes by query', () async {
      for (final language in ApiConfig.supportedLanguages) {
        for (final category in ApiConfig.supportedCategories) {
          final url = ApiConfig.getListUrl(language, category);
          dioAdapter.onGet(
            url,
            (server) => server.reply(200, [
              {
                'id': 'bitcoin-news',
                'path': 'audio/$language/$category/bitcoin-news/audio.m3u8',
                'title': 'Bitcoin News',
                'last_modified': '2025-01-01T00:00:00Z',
              },
              {
                'id': 'ethereum-update',
                'path': 'audio/$language/$category/ethereum-update/audio.m3u8',
                'title': 'Ethereum Update',
                'last_modified': '2025-01-02T00:00:00Z',
              },
            ]),
          );
        }
      }

      final result = await ApiRepository.instance.searchEpisodes('bitcoin');

      // Only Bitcoin-related episodes should be returned
      expect(
          result.every((ep) =>
              ep.title.toLowerCase().contains('bitcoin') ||
              ep.id.toLowerCase().contains('bitcoin')),
          isTrue);
    });

    test('should return all episodes for empty query', () async {
      for (final language in ApiConfig.supportedLanguages) {
        for (final category in ApiConfig.supportedCategories) {
          final url = ApiConfig.getListUrl(language, category);
          dioAdapter.onGet(
            url,
            (server) => server.reply(200, [
              {
                'id': 'ep-$language-$category',
                'path': 'audio/$language/$category/ep/audio.m3u8',
                'title': 'Episode',
                'last_modified': '2025-01-01T00:00:00Z',
              },
            ]),
          );
        }
      }

      final result = await ApiRepository.instance.searchEpisodes('');

      expect(result.isNotEmpty, isTrue);
    });
  });

  group('fetchContent', () {
    test('should return AudioContent on success', () async {
      final url =
          ApiConfig.getContentUrl('en-US', 'daily-news', 'test-content');

      dioAdapter.onGet(
        url,
        (server) => server.reply(200, {
          'id': 'test-content',
          'title': 'Test Content Title',
          'content': 'This is the content body',
          'date': '2025-01-01',
          'status': 'published',
          'category': 'daily-news',
          'language': 'en-US',
          'references': ['Reference 1', 'Reference 2'],
          'updated_at': '2025-01-01T00:00:00Z',
        }),
      );

      final result = await ApiRepository.instance
          .fetchContent('test-content', 'en-US', 'daily-news');

      expect(result, isNotNull);
      expect(result!.id, 'test-content');
      expect(result.title, 'Test Content Title');
    });

    test('should return null on 404', () async {
      final url = ApiConfig.getContentUrl('en-US', 'daily-news', 'nonexistent');

      dioAdapter.onGet(
        url,
        (server) => server.reply(404, null),
      );

      final result = await ApiRepository.instance
          .fetchContent('nonexistent', 'en-US', 'daily-news');

      expect(result, isNull);
    });

    test('should return null on network error', () async {
      final url =
          ApiConfig.getContentUrl('en-US', 'daily-news', 'test-content');

      dioAdapter.onGet(
        url,
        (server) => server.throws(
          0,
          DioException(
            requestOptions: RequestOptions(path: url),
            type: DioExceptionType.connectionError,
          ),
        ),
      );

      final result = await ApiRepository.instance
          .fetchContent('test-content', 'en-US', 'daily-news');

      expect(result, isNull);
    });
  });

  group('cancelCall', () {
    test('should handle cancelling non-existent call', () {
      expect(
        () => ApiRepository.instance.cancelCall('nonexistent-call'),
        returnsNormally,
      );
    });
  });

  group('cancelAllCalls', () {
    test('should cancel all active calls without error', () {
      expect(
        () => ApiRepository.instance.cancelAllCalls(),
        returnsNormally,
      );
    });
  });

  group('getApiStatistics', () {
    test('should return statistics map', () {
      final stats = ApiRepository.instance.getApiStatistics();

      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.containsKey('activeCalls'), isTrue);
      expect(stats.containsKey('activeCallIds'), isTrue);
      expect(stats.containsKey('dioConfig'), isTrue);
    });

    test('should reflect zero active calls when idle', () {
      final stats = ApiRepository.instance.getApiStatistics();
      expect(stats['activeCalls'], 0);
    });
  });

  group('dispose', () {
    test('should dispose resources without error', () {
      expect(
        () => ApiRepository.instance.dispose(),
        returnsNormally,
      );
    });
  });

  group('RetryInterceptor', () {
    test('should be properly instantiated', () {
      final interceptor = RetryInterceptor();
      expect(interceptor, isNotNull);
    });

    test('maxRetries should be 3', () {
      expect(RetryInterceptor.maxRetries, 3);
    });

    test('retryDelay should be 1 second', () {
      expect(RetryInterceptor.retryDelay, const Duration(seconds: 1));
    });
  });

  group('ErrorHandlingInterceptor', () {
    test('should be properly instantiated', () {
      final interceptor = ErrorHandlingInterceptor();
      expect(interceptor, isNotNull);
    });
  });

  group('HTTP Error Handling', () {
    test('should handle 400 bad request gracefully', () async {
      final url = ApiConfig.getListUrl('en-US', 'daily-news');

      dioAdapter.onGet(url, (server) => server.reply(400, null));

      expect(
        () => ApiRepository.instance
            .getEpisodesForLanguageAndCategory('en-US', 'daily-news'),
        throwsA(isA<DioException>()),
      );
    });

    test('should handle 401 unauthorized gracefully', () async {
      final url = ApiConfig.getListUrl('en-US', 'daily-news');

      dioAdapter.onGet(url, (server) => server.reply(401, null));

      expect(
        () => ApiRepository.instance
            .getEpisodesForLanguageAndCategory('en-US', 'daily-news'),
        throwsA(isA<DioException>()),
      );
    });

    test('should handle 500 server error gracefully', () async {
      final url = ApiConfig.getListUrl('en-US', 'daily-news');

      dioAdapter.onGet(url, (server) => server.reply(500, null));

      expect(
        () => ApiRepository.instance
            .getEpisodesForLanguageAndCategory('en-US', 'daily-news'),
        throwsA(isA<DioException>()),
      );
    });
  });
}

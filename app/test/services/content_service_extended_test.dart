import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:from_fed_to_chain_app/services/content_facade_service.dart';
import 'package:from_fed_to_chain_app/services/streaming_api_service.dart';
import 'package:from_fed_to_chain_app/models/audio_file.dart';
import 'package:from_fed_to_chain_app/models/audio_content.dart';

// Generate mocks for dependencies
@GenerateMocks([http.Client, StreamingApiService])
import 'content_service_extended_test.mocks.dart';

void main() {
  group('ContentFacadeService Extended Coverage Tests', () {
    late ContentFacadeService contentService;
    late MockClient mockHttpClient;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      dotenv.testLoad(fileInput: '''
ENVIRONMENT=test
STREAMING_BASE_URL=https://example.com
API_TIMEOUT_SECONDS=30
STREAM_TIMEOUT_SECONDS=30
''');
      mockHttpClient = MockClient();
      // Note: ContentFacadeService uses repositories, mock setup may need adjustment

      when(
        mockHttpClient.get(
          argThat(predicate<Uri>(
              (uri) => uri.queryParameters.containsKey('prefix'))),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => http.Response(
            json.encode([
              {
                'id': 'first-episode',
                'path': 'audio/zh-TW/daily-news/first-episode.m3u8',
                'title': 'First Episode',
                'last_modified': '2025-01-15T00:00:00Z',
                'size': 1024,
                'duration': 300,
              },
              {
                'id': 'last-episode',
                'path': 'audio/zh-TW/daily-news/last-episode.m3u8',
                'title': 'Last Episode',
                'last_modified': '2025-01-16T00:00:00Z',
                'size': 2048,
                'duration': 320,
              },
              {
                'id': 'static-test-content',
                'path': 'audio/en-US/daily-news/static-test-content.m3u8',
                'title': 'Static Test',
                'last_modified': '2025-01-15T00:00:00Z',
                'size': 512,
                'duration': 300,
              },
            ]),
            200,
            headers: {'content-type': 'application/json'},
          ));

      contentService = ContentFacadeService();
    });

    tearDown(() {
      contentService.dispose();
      // Note: ContentFacadeService uses repositories instead of HTTP client
    });

    group('Content Fetching and Caching', () {
      test('should fetch content from API when not cached', () async {
        final mockResponse = {
          'id': 'test-content',
          'title': 'Test Content',
          'language': 'en-US',
          'category': 'daily-news',
          'date': '2025-01-15T00:00:00.000Z',
          'status': 'published',
          'description': 'Test description',
          'references': ['Source 1'],
          'social_hook': 'Test hook',
          'updated_at': '2025-01-15T00:00:00.000Z',
        };

        when(
          mockHttpClient.get(
            argThat(predicate<Uri>((uri) =>
                uri.path.contains('/api/content/') &&
                uri.toString().contains('test-content'))),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => http.Response(
              json.encode(mockResponse),
              200,
              headers: {'content-type': 'application/json'},
            ));

        final content = await contentService.fetchContentById(
            'test-content', 'en-US', 'daily-news');

        expect(content, isNotNull);
        expect(content!.id, 'test-content');
        expect(content.title, 'Test Content');
        verify(
          mockHttpClient.get(
            argThat(predicate<Uri>((uri) =>
                uri.path.contains('/api/content/') &&
                uri.toString().contains('test-content'))),
            headers: anyNamed('headers'),
          ),
        ).called(1);
      });

      test('should return cached content on subsequent requests', () async {
        final mockContent = AudioContent(
          id: 'cached-content',
          title: 'Cached Content',
          language: 'en-US',
          category: 'daily-news',
          date: DateTime(2025, 1, 15),
          status: 'published',
          description: 'Cached description',
          references: ['Source 1'],
          socialHook: 'Cached hook',
          updatedAt: DateTime(2025, 1, 15),
        );

        // Cache content manually
        contentService.cacheContent(
            'cached-content', 'en-US', 'daily-news', mockContent);

        final content = await contentService.fetchContentById(
            'cached-content', 'en-US', 'daily-news');

        expect(content, isNotNull);
        expect(content!.id, 'cached-content');
        verifyNever(mockHttpClient.get(any, headers: anyNamed('headers')));
      });

      test('should handle HTTP error responses gracefully', () async {
        when(
          mockHttpClient.get(
            argThat(predicate<Uri>((uri) =>
                uri.path.contains('/api/content/') &&
                uri.toString().contains('not-found'))),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => http.Response('Not Found', 404));

        final content = await contentService.fetchContentById(
            'not-found', 'en-US', 'daily-news');

        expect(content, isNull);
        verify(
          mockHttpClient.get(
            argThat(predicate<Uri>((uri) =>
                uri.path.contains('/api/content/') &&
                uri.toString().contains('not-found'))),
            headers: anyNamed('headers'),
          ),
        ).called(1);
      });

      test('should handle network exceptions gracefully', () async {
        when(
          mockHttpClient.get(
            argThat(predicate<Uri>((uri) =>
                uri.path.contains('/api/content/') &&
                uri.toString().contains('error-content'))),
            headers: anyNamed('headers'),
          ),
        ).thenThrow(Exception('Network error'));

        final content = await contentService.fetchContentById(
            'error-content', 'en-US', 'daily-news');

        expect(content, isNull);
        verify(
          mockHttpClient.get(
            argThat(predicate<Uri>((uri) =>
                uri.path.contains('/api/content/') &&
                uri.toString().contains('error-content'))),
            headers: anyNamed('headers'),
          ),
        ).called(1);
      });

      test('should handle malformed JSON responses', () async {
        when(
          mockHttpClient.get(
            argThat(predicate<Uri>((uri) =>
                uri.path.contains('/api/content/') &&
                uri.toString().contains('malformed-content'))),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => http.Response('invalid json', 200));

        final content = await contentService.fetchContentById(
            'malformed-content', 'en-US', 'daily-news');

        expect(content, isNull);
        verify(
          mockHttpClient.get(
            argThat(predicate<Uri>((uri) =>
                uri.path.contains('/api/content/') &&
                uri.toString().contains('malformed-content'))),
            headers: anyNamed('headers'),
          ),
        ).called(1);
      });

      test('should clear content cache', () {
        final mockContent = AudioContent(
          id: 'test-content',
          title: 'Test Content',
          language: 'en-US',
          category: 'daily-news',
          date: DateTime(2025, 1, 15),
          status: 'published',
          description: 'Test description',
          references: ['Source 1'],
          socialHook: 'Test hook',
          updatedAt: DateTime(2025, 1, 15),
        );

        contentService.cacheContent(
            'test-content', 'en-US', 'daily-news', mockContent);

        final cachedBefore = contentService.getCachedContent(
            'test-content', 'en-US', 'daily-news');
        expect(cachedBefore, isNotNull);

        contentService.clearContentCache();

        final cachedAfter = contentService.getCachedContent(
            'test-content', 'en-US', 'daily-news');
        expect(cachedAfter, isNull);
      });
    });

    group('Audio File Deep Linking', () {
      final sampleEpisodes = <AudioFile>[
        AudioFile(
          id: '2025-01-15-bitcoin-news-zh-TW',
          title: 'Bitcoin News ZH',
          streamingUrl: 'https://example.com/bitcoin-zh.m3u8',
          path: '/audio/zh-TW/daily-news/2025-01-15-bitcoin-news-zh-TW.m3u8',
          language: 'zh-TW',
          category: 'daily-news',
          lastModified: DateTime(2025, 1, 15),
        ),
        AudioFile(
          id: '2025-01-15-bitcoin-news-en-US',
          title: 'Bitcoin News EN',
          streamingUrl: 'https://example.com/bitcoin-en.m3u8',
          path: '/audio/en-US/daily-news/2025-01-15-bitcoin-news-en-US.m3u8',
          language: 'en-US',
          category: 'daily-news',
          lastModified: DateTime(2025, 1, 15),
        ),
        AudioFile(
          id: '2025-01-15-ethereum-analysis',
          title: 'Ethereum Analysis',
          streamingUrl: 'https://example.com/ethereum.m3u8',
          path: '/audio/zh-TW/ethereum/2025-01-15-ethereum-analysis.m3u8',
          language: 'zh-TW',
          category: 'ethereum',
          lastModified: DateTime(2025, 1, 15),
        ),
      ];

      test('should find audio file by exact ID match', () async {
        contentService.setEpisodesForTesting(sampleEpisodes);

        final result = await contentService
            .getAudioFileById('2025-01-15-bitcoin-news-zh-TW');

        expect(result, isNotNull);
        expect(result!.id, '2025-01-15-bitcoin-news-zh-TW');
        expect(result.language, 'zh-TW');
      });

      test('should find audio file by base ID with language suffix', () async {
        contentService.setEpisodesForTesting(sampleEpisodes);

        final result = await contentService
            .getAudioFileById('2025-01-15-bitcoin-news-en-US');

        expect(result, isNotNull);
        expect(result!.id, '2025-01-15-bitcoin-news-en-US');
        expect(result.language, 'en-US');
      });

      test('should find audio file by date pattern when exact match fails',
          () async {
        contentService.setEpisodesForTesting(sampleEpisodes);

        final result = await contentService
            .getAudioFileById('2025-01-15-some-unknown-content');

        expect(result, isNotNull);
        expect(result!.id.contains('2025-01-15'), isTrue);
      });

      test('should return null when no matching audio file found', () async {
        contentService.setEpisodesForTesting(sampleEpisodes);

        final result =
            await contentService.getAudioFileById('2025-12-31-nonexistent');

        expect(result, isNull);
      });

      test('should return null when episodes list is empty', () async {
        contentService.setEpisodesForTesting([]);

        final result = await contentService.getAudioFileById('any-content-id');

        expect(result, isNull);
      });
    });

    group('Static Content Access', () {
      test('should get content by ID via static method', () async {
        final mockEpisodes = <AudioFile>[
          AudioFile(
            id: 'static-test-content',
            title: 'Static Test',
            streamingUrl: 'https://example.com/static.m3u8',
            path: '/audio/en-US/daily-news/static-test-content.m3u8',
            language: 'en-US',
            category: 'daily-news',
            lastModified: DateTime(2025, 1, 15),
          ),
        ];

        // Use setEpisodesForTesting directly on ContentService
        contentService.setEpisodesForTesting(mockEpisodes);
        // Note: ContentFacadeService doesn't use static setAllEpisodesForTesting

        final mockContent = AudioContent(
          id: 'static-test-content',
          title: 'Static Test Content',
          language: 'en-US',
          category: 'daily-news',
          date: DateTime(2025, 1, 15),
          status: 'published',
          description: 'Static test description',
          references: ['Source 1'],
          socialHook: 'Static hook',
          updatedAt: DateTime(2025, 1, 15),
        );

        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response(
                  json.encode(mockContent.toJson()),
                  200,
                  headers: {'content-type': 'application/json'},
                ));

        final content = await contentService.fetchContentById(
            'static-test-content', 'en-US', 'daily-news');

        expect(content, isNotNull);
        expect(content!.id, 'static-test-content');
      });

      test('should return null when static content not found', () async {
        contentService.setEpisodesForTesting([]);
        // Note: ContentFacadeService doesn't use static setAllEpisodesForTesting

        final content = await contentService.fetchContentById(
            'nonexistent-static-content', 'en-US', 'daily-news');

        expect(content, isNull);
      });
    });

    group('Episode Navigation Edge Cases', () {
      test(
          'should handle next/previous episode when current episode not in filtered list',
          () async {
        final episodes = <AudioFile>[
          AudioFile(
            id: 'episode-1',
            title: 'Episode 1',
            streamingUrl: 'https://example.com/1.m3u8',
            path: '/audio/zh-TW/daily-news/episode-1.m3u8',
            language: 'zh-TW',
            category: 'daily-news',
            lastModified: DateTime(2025, 1, 15),
          ),
          AudioFile(
            id: 'episode-2',
            title: 'Episode 2',
            streamingUrl: 'https://example.com/2.m3u8',
            path: '/audio/en-US/daily-news/episode-2.m3u8',
            language: 'en-US',
            category: 'daily-news',
            lastModified: DateTime(2025, 1, 16),
          ),
        ];

        contentService.setEpisodesForTesting(episodes);
        contentService
            .setSelectedLanguage('zh-TW'); // This will filter out episode-2

        final outsideEpisode = AudioFile(
          id: 'episode-2',
          title: 'Episode 2',
          streamingUrl: 'https://example.com/2.m3u8',
          path: '/audio/en-US/daily-news/episode-2.m3u8',
          language: 'en-US',
          category: 'daily-news',
          lastModified: DateTime(2025, 1, 16),
        );

        final nextEpisode = contentService.getNextEpisode(outsideEpisode);
        final previousEpisode =
            contentService.getPreviousEpisode(outsideEpisode);

        expect(nextEpisode, isNull);
        expect(previousEpisode, isNull);
      });

      test('should handle navigation at list boundaries', () async {
        final episodes = <AudioFile>[
          AudioFile(
            id: 'first-episode',
            title: 'First Episode',
            streamingUrl: 'https://example.com/first.m3u8',
            path: '/audio/zh-TW/daily-news/first-episode.m3u8',
            language: 'zh-TW',
            category: 'daily-news',
            lastModified: DateTime(2025, 1, 15),
          ),
          AudioFile(
            id: 'last-episode',
            title: 'Last Episode',
            streamingUrl: 'https://example.com/last.m3u8',
            path: '/audio/zh-TW/daily-news/last-episode.m3u8',
            language: 'zh-TW',
            category: 'daily-news',
            lastModified: DateTime(2025, 1, 16),
          ),
        ];

        contentService.setEpisodesForTesting(episodes);

        // Test at beginning of list
        final beforeFirst = contentService.getPreviousEpisode(episodes[0]);
        expect(beforeFirst, isNull);

        // Test at end of list
        final afterLast = contentService.getNextEpisode(episodes[1]);
        expect(afterLast, isNull);
      });
    });

    group('Validation and Error Handling', () {
      test('should validate language in setLanguage method', () async {
        contentService.setErrorForTesting(null);

        await contentService.setLanguage('invalid-language');

        expect(contentService.hasError, isTrue);
        expect(contentService.errorMessage, contains('Unsupported language'));
      });

      test('should validate category in setCategory method', () async {
        contentService.setErrorForTesting(null);

        await contentService.setCategory('invalid-category');

        expect(contentService.hasError, isTrue);
        expect(contentService.errorMessage, contains('Unsupported category'));
      });

      test('should allow "all" as valid category', () async {
        contentService.setErrorForTesting(null);

        await contentService.setCategory('all');

        expect(contentService.hasError, isFalse);
        expect(contentService.selectedCategory, 'all');
      });
    });

    group('Debug Information', () {
      test('should provide debug info for audio file', () {
        final audioFile = AudioFile(
          id: 'debug-test',
          title: 'Debug Test',
          streamingUrl: 'https://example.com/debug.m3u8',
          path: '/audio/en-US/daily-news/debug-test.m3u8',
          language: 'en-US',
          category: 'daily-news',
          lastModified: DateTime(2025, 1, 15),
        );

        final debugInfo = contentService.getDebugInfo(audioFile);

        expect(debugInfo['id'], 'debug-test');
        expect(debugInfo['title'], 'Debug Test');
        expect(debugInfo['language'], 'en-US');
        expect(debugInfo['category'], 'daily-news');
        expect(debugInfo['streamingUrl'], 'https://example.com/debug.m3u8');
        expect(debugInfo.containsKey('totalEpisodes'), isTrue);
        expect(debugInfo.containsKey('filteredEpisodes'), isTrue);
        expect(debugInfo.containsKey('selectedLanguage'), isTrue);
        expect(debugInfo.containsKey('selectedCategory'), isTrue);
        expect(debugInfo.containsKey('isLoading'), isTrue);
        expect(debugInfo.containsKey('hasError'), isTrue);
      });

      test('should handle debug info for null audio file', () {
        final debugInfo = contentService.getDebugInfo(null);

        expect(debugInfo['error'], 'No audio file provided');
      });
    });

    group('Statistics and Aggregation', () {
      test('should calculate statistics correctly', () {
        final episodes = <AudioFile>[
          AudioFile(
            id: 'ep1',
            title: 'Episode 1',
            streamingUrl: 'https://example.com/1.m3u8',
            path: '/audio/zh-TW/daily-news/ep1.m3u8',
            language: 'zh-TW',
            category: 'daily-news',
            lastModified: DateTime(2025, 1, 15),
          ),
          AudioFile(
            id: 'ep2',
            title: 'Episode 2',
            streamingUrl: 'https://example.com/2.m3u8',
            path: '/audio/en-US/daily-news/ep2.m3u8',
            language: 'en-US',
            category: 'daily-news',
            lastModified: DateTime(2025, 1, 16),
          ),
          AudioFile(
            id: 'ep3',
            title: 'Episode 3',
            streamingUrl: 'https://example.com/3.m3u8',
            path: '/audio/zh-TW/ethereum/ep3.m3u8',
            language: 'zh-TW',
            category: 'ethereum',
            lastModified: DateTime(2025, 1, 17),
          ),
        ];

        contentService.setEpisodesForTesting(episodes);

        final stats = contentService.getStatistics();

        expect(stats['totalEpisodes'], 3);
        expect(stats['languages']['zh-TW'], 2);
        expect(stats['languages']['en-US'], 1);
        expect(stats['categories']['daily-news'], 2);
        expect(stats['categories']['ethereum'], 1);
      });

      test('should get episodes by language', () {
        final episodes = <AudioFile>[
          AudioFile(
            id: 'zh-ep1',
            title: 'ZH Episode 1',
            streamingUrl: 'https://example.com/zh1.m3u8',
            path: '/audio/zh-TW/daily-news/zh-ep1.m3u8',
            language: 'zh-TW',
            category: 'daily-news',
            lastModified: DateTime(2025, 1, 15),
          ),
          AudioFile(
            id: 'en-ep1',
            title: 'EN Episode 1',
            streamingUrl: 'https://example.com/en1.m3u8',
            path: '/audio/en-US/daily-news/en-ep1.m3u8',
            language: 'en-US',
            category: 'daily-news',
            lastModified: DateTime(2025, 1, 16),
          ),
        ];

        contentService.setEpisodesForTesting(episodes);

        final zhEpisodes = contentService.getEpisodesByLanguage('zh-TW');
        final enEpisodes = contentService.getEpisodesByLanguage('en-US');

        expect(zhEpisodes.length, 1);
        expect(zhEpisodes[0].language, 'zh-TW');
        expect(enEpisodes.length, 1);
        expect(enEpisodes[0].language, 'en-US');
      });

      test('should get episodes by category', () {
        final episodes = <AudioFile>[
          AudioFile(
            id: 'news-ep1',
            title: 'News Episode 1',
            streamingUrl: 'https://example.com/news1.m3u8',
            path: '/audio/zh-TW/daily-news/news-ep1.m3u8',
            language: 'zh-TW',
            category: 'daily-news',
            lastModified: DateTime(2025, 1, 15),
          ),
          AudioFile(
            id: 'eth-ep1',
            title: 'Ethereum Episode 1',
            streamingUrl: 'https://example.com/eth1.m3u8',
            path: '/audio/zh-TW/ethereum/eth-ep1.m3u8',
            language: 'zh-TW',
            category: 'ethereum',
            lastModified: DateTime(2025, 1, 16),
          ),
        ];

        contentService.setEpisodesForTesting(episodes);

        final newsEpisodes = contentService.getEpisodesByCategory('daily-news');
        final ethEpisodes = contentService.getEpisodesByCategory('ethereum');

        expect(newsEpisodes.length, 1);
        expect(newsEpisodes[0].category, 'daily-news');
        expect(ethEpisodes.length, 1);
        expect(ethEpisodes[0].category, 'ethereum');
      });

      test('should get episodes by language and category', () {
        final episodes = <AudioFile>[
          AudioFile(
            id: 'zh-news-ep1',
            title: 'ZH News Episode 1',
            streamingUrl: 'https://example.com/zh-news1.m3u8',
            path: '/audio/zh-TW/daily-news/zh-news-ep1.m3u8',
            language: 'zh-TW',
            category: 'daily-news',
            lastModified: DateTime(2025, 1, 15),
          ),
          AudioFile(
            id: 'en-news-ep1',
            title: 'EN News Episode 1',
            streamingUrl: 'https://example.com/en-news1.m3u8',
            path: '/audio/en-US/daily-news/en-news-ep1.m3u8',
            language: 'en-US',
            category: 'daily-news',
            lastModified: DateTime(2025, 1, 16),
          ),
          AudioFile(
            id: 'zh-eth-ep1',
            title: 'ZH Ethereum Episode 1',
            streamingUrl: 'https://example.com/zh-eth1.m3u8',
            path: '/audio/zh-TW/ethereum/zh-eth-ep1.m3u8',
            language: 'zh-TW',
            category: 'ethereum',
            lastModified: DateTime(2025, 1, 17),
          ),
        ];

        contentService.setEpisodesForTesting(episodes);

        final zhNewsEpisodes = contentService.getEpisodesByLanguageAndCategory(
            'zh-TW', 'daily-news');
        final enNewsEpisodes = contentService.getEpisodesByLanguageAndCategory(
            'en-US', 'daily-news');
        final zhEthEpisodes = contentService.getEpisodesByLanguageAndCategory(
            'zh-TW', 'ethereum');

        expect(zhNewsEpisodes.length, 1);
        expect(zhNewsEpisodes[0].language, 'zh-TW');
        expect(zhNewsEpisodes[0].category, 'daily-news');

        expect(enNewsEpisodes.length, 1);
        expect(enNewsEpisodes[0].language, 'en-US');
        expect(enNewsEpisodes[0].category, 'daily-news');

        expect(zhEthEpisodes.length, 1);
        expect(zhEthEpisodes[0].language, 'zh-TW');
        expect(zhEthEpisodes[0].category, 'ethereum');
      });
    });

    group('Content Pre-fetching', () {
      test('should prefetch content for multiple episodes', () async {
        final episodes = <AudioFile>[
          AudioFile(
            id: 'prefetch-1',
            title: 'Prefetch Episode 1',
            streamingUrl: 'https://example.com/prefetch1.m3u8',
            path: '/audio/en-US/daily-news/prefetch-1.m3u8',
            language: 'en-US',
            category: 'daily-news',
            lastModified: DateTime(2025, 1, 15),
          ),
          AudioFile(
            id: 'prefetch-2',
            title: 'Prefetch Episode 2',
            streamingUrl: 'https://example.com/prefetch2.m3u8',
            path: '/audio/en-US/daily-news/prefetch-2.m3u8',
            language: 'en-US',
            category: 'daily-news',
            lastModified: DateTime(2025, 1, 16),
          ),
        ];

        final mockContent1 = {
          'id': 'prefetch-1',
          'title': 'Prefetch Episode 1',
          'language': 'en-US',
          'category': 'daily-news',
          'date': '2025-01-15T00:00:00.000Z',
          'status': 'published',
          'description': 'Prefetch description 1',
          'references': ['Source 1'],
          'social_hook': 'Prefetch hook 1',
          'updated_at': '2025-01-15T00:00:00.000Z',
        };

        final mockContent2 = {
          'id': 'prefetch-2',
          'title': 'Prefetch Episode 2',
          'language': 'en-US',
          'category': 'daily-news',
          'date': '2025-01-16T00:00:00.000Z',
          'status': 'published',
          'description': 'Prefetch description 2',
          'references': ['Source 2'],
          'social_hook': 'Prefetch hook 2',
          'updated_at': '2025-01-16T00:00:00.000Z',
        };

        when(
          mockHttpClient.get(
            argThat(predicate<Uri>((uri) =>
                uri.path.contains('/api/content/') &&
                uri.toString().contains('prefetch-1'))),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => http.Response(
              json.encode(mockContent1),
              200,
              headers: {'content-type': 'application/json'},
            ));

        when(
          mockHttpClient.get(
            argThat(predicate<Uri>((uri) =>
                uri.path.contains('/api/content/') &&
                uri.toString().contains('prefetch-2'))),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => http.Response(
              json.encode(mockContent2),
              200,
              headers: {'content-type': 'application/json'},
            ));

        await contentService.prefetchContent(episodes);

        // Verify both contents are now cached
        final cachedContent1 = contentService.getCachedContent(
            'prefetch-1', 'en-US', 'daily-news');
        final cachedContent2 = contentService.getCachedContent(
            'prefetch-2', 'en-US', 'daily-news');

        expect(cachedContent1, isNotNull);
        expect(cachedContent1!.id, 'prefetch-1');
        expect(cachedContent2, isNotNull);
        expect(cachedContent2!.id, 'prefetch-2');

        verify(
          mockHttpClient.get(
            argThat(predicate<Uri>((uri) =>
                uri.path.contains('/api/content/') &&
                (uri.toString().contains('prefetch-1') ||
                    uri.toString().contains('prefetch-2')))),
            headers: anyNamed('headers'),
          ),
        ).called(2);
      });

      test('should handle prefetch with empty episode list', () async {
        await contentService.prefetchContent([]);
        verifyNever(mockHttpClient.get(any, headers: anyNamed('headers')));
      });

      test('should handle prefetch failures gracefully', () async {
        final episodes = <AudioFile>[
          AudioFile(
            id: 'fail-prefetch',
            title: 'Fail Prefetch Episode',
            streamingUrl: 'https://example.com/fail.m3u8',
            path: '/audio/en-US/daily-news/fail-prefetch.m3u8',
            language: 'en-US',
            category: 'daily-news',
            lastModified: DateTime(2025, 1, 15),
          ),
        ];

        when(
          mockHttpClient.get(
            argThat(predicate<Uri>((uri) =>
                uri.path.contains('/api/content/') &&
                uri.toString().contains('fail-prefetch'))),
            headers: anyNamed('headers'),
          ),
        ).thenThrow(Exception('Network error'));

        // Should complete without throwing
        await contentService.prefetchContent(episodes);

        verify(
          mockHttpClient.get(
            argThat(predicate<Uri>((uri) =>
                uri.path.contains('/api/content/') &&
                uri.toString().contains('fail-prefetch'))),
            headers: anyNamed('headers'),
          ),
        ).called(1);
      });
    });
  });
}

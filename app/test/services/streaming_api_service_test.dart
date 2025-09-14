import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async' as async;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:from_fed_to_chain_app/services/streaming_api_service.dart';

// Generate mocks
@GenerateMocks([http.Client])
import 'streaming_api_service_test.mocks.dart';

void main() {
  group('StreamingApiService Tests', () {
    late MockClient mockHttpClient;

    setUpAll(() async {
      // Initialize dotenv with test environment variables
      dotenv.testLoad(fileInput: '''
AUDIO_API_BASE_URL=https://test-api.example.com
ENVIRONMENT=test
''');
    });

    setUp(() {
      mockHttpClient = MockClient();
      StreamingApiService.setHttpClient(mockHttpClient);
    });

    tearDown(() {
      StreamingApiService.dispose();
    });

    group('HTTP Client Management', () {
      test('should set and get HTTP client correctly', () {
        final testClient = MockClient();
        StreamingApiService.setHttpClient(testClient);

        expect(StreamingApiService.httpClient, equals(testClient));
      });

      test('should dispose HTTP client properly', () {
        StreamingApiService.dispose();
        // Client should be reset to a new instance
        expect(StreamingApiService.httpClient, isNotNull);
      });
    });

    group('getEpisodeList', () {
      test('should fetch episodes successfully with valid response', () async {
        const language = 'zh-TW';
        const category = 'startup';

        final mockResponse = [
          {
            'id': '2025-01-01-test',
            'path': 'zh-TW/startup/2025-01-01-test.m3u8',
            'title': 'Test Episode',
            'category': 'startup',
            'language': 'zh-TW',
            'streaming_url':
                'https://test-api.example.com/zh-TW/startup/2025-01-01-test.m3u8',
            'size': 1024,
            'last_modified': '2025-01-01T10:00:00Z',
            'duration': 300,
          }
        ];

        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
              json.encode(mockResponse),
              200,
              headers: {'content-type': 'application/json'},
            ));

        final episodes =
            await StreamingApiService.getEpisodeList(language, category);

        expect(episodes, hasLength(1));
        expect(episodes.first.title, equals('Test Episode'));
        expect(episodes.first.category, equals('startup'));
        expect(episodes.first.language, equals('zh-TW'));
        verify(mockHttpClient.get(any, headers: anyNamed('headers'))).called(1);
      });

      test('should handle single episode object response', () async {
        const language = 'en-US';
        const category = 'daily-news';

        final mockResponse = {
          'id': '2025-01-01-news',
          'path': 'en-US/daily-news/2025-01-01-news.m3u8',
          'title': 'Daily News',
          'category': 'daily-news',
          'language': 'en-US',
          'streaming_url':
              'https://test-api.example.com/en-US/daily-news/2025-01-01-news.m3u8',
          'size': 2048,
          'last_modified': '2025-01-01T12:00:00Z',
          'duration': 600,
        };

        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response(
                  json.encode(mockResponse),
                  200,
                ));

        final episodes =
            await StreamingApiService.getEpisodeList(language, category);

        expect(episodes, hasLength(1));
        expect(episodes.first.title, equals('Daily News'));
        expect(episodes.first.category, equals('daily-news'));
      });

      test('should handle response with episodes array in object', () async {
        const language = 'ja-JP';
        const category = 'ethereum';

        final mockResponse = {
          'episodes': [
            {
              'id': '2025-01-01-eth',
              'path': 'ja-JP/ethereum/2025-01-01-eth.m3u8',
              'title': 'Ethereum Update',
              'category': 'ethereum',
              'language': 'ja-JP',
              'streaming_url':
                  'https://test-api.example.com/ja-JP/ethereum/2025-01-01-eth.m3u8',
              'size': 1536,
              'last_modified': '2025-01-01T14:00:00Z',
              'duration': 420,
            }
          ]
        };

        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response(
                  json.encode(mockResponse),
                  200,
                ));

        final episodes =
            await StreamingApiService.getEpisodeList(language, category);

        expect(episodes, hasLength(1));
        expect(episodes.first.title, equals('Ethereum Update'));
      });

      test('should handle response with data array in object', () async {
        const language = 'zh-TW';
        const category = 'macro';

        final mockResponse = {
          'data': [
            {
              'id': '2025-01-01-macro',
              'path': 'zh-TW/macro/2025-01-01-macro.m3u8',
              'title': 'Macro Analysis',
              'category': 'macro',
              'language': 'zh-TW',
              'size': 2048,
              'last_modified': '2025-01-01T16:00:00Z',
              'duration': 900,
            }
          ]
        };

        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response(
                  json.encode(mockResponse),
                  200,
                ));

        final episodes =
            await StreamingApiService.getEpisodeList(language, category);

        expect(episodes, hasLength(1));
        expect(episodes.first.title, equals('Macro Analysis'));
      });

      test('should throw ArgumentError for invalid language', () async {
        expect(
          () => StreamingApiService.getEpisodeList('invalid', 'startup'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw ArgumentError for invalid category', () async {
        expect(
          () => StreamingApiService.getEpisodeList('zh-TW', 'invalid'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw ApiException for non-200 status code', () async {
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response(
                  'Not Found',
                  404,
                  reasonPhrase: 'Not Found',
                ));

        expect(
          () => StreamingApiService.getEpisodeList('zh-TW', 'startup'),
          throwsA(isA<ApiException>()),
        );
      });

      test('should throw NetworkException for ClientException', () async {
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenThrow(http.ClientException('Network error'));

        expect(
          () => StreamingApiService.getEpisodeList('zh-TW', 'startup'),
          throwsA(isA<NetworkException>()),
        );
      });

      test('should throw TimeoutException for timeout', () async {
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenThrow(async.TimeoutException('Request timed out', Duration(seconds: 30)));

        expect(
          () => StreamingApiService.getEpisodeList('zh-TW', 'startup'),
          throwsA(predicate((e) => e is TimeoutException && e.message.contains('timed out'))),
        );
      });

      test('should throw UnknownException for unexpected errors', () async {
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenThrow(Exception('Unexpected error'));

        expect(
          () => StreamingApiService.getEpisodeList('zh-TW', 'startup'),
          throwsA(isA<UnknownException>()),
        );
      });

      test('should skip episodes with missing path', () async {
        const language = 'zh-TW';
        const category = 'startup';

        final mockResponse = [
          {
            'id': '2025-01-01-valid',
            'path': 'zh-TW/startup/2025-01-01-valid.m3u8',
            'title': 'Valid Episode',
            'category': 'startup',
            'size': 1024,
            'last_modified': '2025-01-01T10:00:00Z',
            'duration': 300,
          },
          {
            'title': 'Invalid Episode - No Path',
            'category': 'startup',
            'size': 1024,
            'last_modified': '2025-01-01T11:00:00Z',
            'duration': 300,
          },
          {
            'path': '',
            'title': 'Invalid Episode - Empty Path',
            'category': 'startup',
            'size': 1024,
            'last_modified': '2025-01-01T12:00:00Z',
            'duration': 300,
          }
        ];

        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response(
                  json.encode(mockResponse),
                  200,
                ));

        final episodes =
            await StreamingApiService.getEpisodeList(language, category);

        expect(episodes, hasLength(1));
        expect(episodes.first.title, equals('Valid Episode'));
      });

      test('should handle malformed episode data gracefully', () async {
        const language = 'zh-TW';
        const category = 'startup';

        final mockResponse = [
          {
            'id': '2025-01-01-valid',
            'path': 'zh-TW/startup/2025-01-01-valid.m3u8',
            'title': 'Valid Episode',
            'category': 'startup',
            'size': 1024,
            'last_modified': '2025-01-01T10:00:00Z',
            'duration': 300,
          },
          {
            'id': '2025-01-01-malformed',
            'path': 'zh-TW/startup/2025-01-01-malformed.m3u8',
            'title': 'Malformed Episode',
            'category': 'startup',
            'size': 'invalid_size', // Invalid size
            'last_modified': 'invalid_date', // Invalid date
            'duration': 'invalid_duration', // Invalid duration
          }
        ];

        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response(
                  json.encode(mockResponse),
                  200,
                ));

        final episodes =
            await StreamingApiService.getEpisodeList(language, category);

        expect(episodes, hasLength(1));
        expect(episodes.first.title, equals('Valid Episode'));
      });

      test('should throw FormatException for unexpected response format',
          () async {
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response(
                  'invalid json string',
                  200,
                ));

        expect(
          () => StreamingApiService.getEpisodeList('zh-TW', 'startup'),
          throwsA(isA<FormatException>()),
        );
      });

      test('should throw FormatException for non-array/object response',
          () async {
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response(
                  json.encode('string response'),
                  200,
                ));

        expect(
          () => StreamingApiService.getEpisodeList('zh-TW', 'startup'),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('getAllEpisodesForLanguage', () {
      test('should fetch episodes from all categories for language', () async {
        const language = 'zh-TW';

        // Mock responses for different categories
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((invocation) async {
          final uri = invocation.positionalArguments[0] as Uri;
          // Extract category from query parameter: prefix=audio/{language}/{category}/
          final prefix = uri.queryParameters['prefix'] ?? '';
          final parts = prefix.split('/');
          final category = parts.length >= 3 ? parts[2] : 'startup';

          final mockResponse = [
            {
              'id': '2025-01-01-test',
              'path': 'zh-TW/$category/2025-01-01-test.m3u8',
              'title': 'Episode from $category',
              'category': category,
              'language': 'zh-TW',
              'size': 1024,
              'last_modified': '2025-01-01T10:00:00Z',
              'duration': 300,
            }
          ];

          return http.Response(json.encode(mockResponse), 200);
        });

        final episodes =
            await StreamingApiService.getAllEpisodesForLanguage(language);

        expect(episodes, isNotEmpty);
        expect(episodes.every((e) => e.language == language), isTrue);
      });

      test('should handle errors for some categories gracefully', () async {
        const language = 'zh-TW';

        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((invocation) async {
          final uri = invocation.positionalArguments[0] as Uri;
          // Extract category from query parameter: prefix=audio/{language}/{category}/
          final prefix = uri.queryParameters['prefix'] ?? '';
          final parts = prefix.split('/');
          final category = parts.length >= 3 ? parts[2] : 'startup';

          if (category == 'startup') {
            // Simulate error for startup category
            return http.Response('Not Found', 404);
          }

          final mockResponse = [
            {
              'id': '2025-01-01-test',
              'path': 'zh-TW/$category/2025-01-01-test.m3u8',
              'title': 'Episode from $category',
              'category': category,
              'language': 'zh-TW',
              'size': 1024,
              'last_modified': '2025-01-01T10:00:00Z',
              'duration': 300,
            }
          ];

          return http.Response(json.encode(mockResponse), 200);
        });

        final episodes =
            await StreamingApiService.getAllEpisodesForLanguage(language);

        expect(episodes, isNotEmpty);
        expect(episodes.any((e) => e.category == 'startup'), isFalse);
      });

      test('should throw ArgumentError for invalid language', () async {
        expect(
          () => StreamingApiService.getAllEpisodesForLanguage('invalid'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should sort episodes by date newest first', () async {
        const language = 'zh-TW';

        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((invocation) async {
          final mockResponse = [
            {
              'id': '2025-01-01-old',
              'path': 'zh-TW/startup/2025-01-01-old.m3u8',
              'title': 'Old Episode',
              'category': 'startup',
              'language': 'zh-TW',
              'size': 1024,
              'last_modified': '2025-01-01T10:00:00Z',
              'duration': 300,
            },
            {
              'id': '2025-01-02-new',
              'path': 'zh-TW/startup/2025-01-02-new.m3u8',
              'title': 'New Episode',
              'category': 'startup',
              'language': 'zh-TW',
              'size': 1024,
              'last_modified': '2025-01-02T10:00:00Z',
              'duration': 300,
            }
          ];

          return http.Response(json.encode(mockResponse), 200);
        });

        final episodes =
            await StreamingApiService.getAllEpisodesForLanguage(language);

        expect(episodes, isNotEmpty);
        expect(episodes.first.title, equals('New Episode'));
        expect(episodes.last.title, equals('Old Episode'));
      });
    });

    group('getAllEpisodes', () {
      test('should fetch all episodes across languages and categories',
          () async {
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((invocation) async {
          final uri = invocation.positionalArguments[0] as Uri;
          // Extract language and category from query parameter: prefix=audio/{language}/{category}/
          final prefix = uri.queryParameters['prefix'] ?? '';
          final parts = prefix.split('/');
          final language = parts.length >= 2 ? parts[1] : 'zh-TW';
          final category = parts.length >= 3 ? parts[2] : 'startup';

          final mockResponse = [
            {
              'id': '2025-01-01-test',
              'path': '$language/$category/2025-01-01-test.m3u8',
              'title': 'Episode $language-$category',
              'category': category,
              'language': language,
              'size': 1024,
              'last_modified': '2025-01-01T10:00:00Z',
              'duration': 300,
            }
          ];

          return http.Response(json.encode(mockResponse), 200);
        });

        final episodes = await StreamingApiService.getAllEpisodes();

        expect(episodes, isNotEmpty);
        // Should have episodes from multiple languages and categories
        final languages = episodes.map((e) => e.language).toSet();
        final categories = episodes.map((e) => e.category).toSet();
        expect(languages.length, greaterThan(1));
        expect(categories.length, greaterThan(1));
      });

      test('should handle errors for some requests gracefully', () async {
        int callCount = 0;
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((invocation) async {
          callCount++;

          if (callCount == 1) {
            // First call fails
            return http.Response('Server Error', 500);
          }

          final uri = invocation.positionalArguments[0] as Uri;
          // Extract language and category from query parameter: prefix=audio/{language}/{category}/
          final prefix = uri.queryParameters['prefix'] ?? '';
          final parts = prefix.split('/');
          final language = parts.length >= 2 ? parts[1] : 'zh-TW';
          final category = parts.length >= 3 ? parts[2] : 'startup';

          final mockResponse = [
            {
              'id': '2025-01-01-test',
              'path': '$language/$category/2025-01-01-test.m3u8',
              'title': 'Episode $language-$category',
              'category': category,
              'language': language,
              'size': 1024,
              'last_modified': '2025-01-01T10:00:00Z',
              'duration': 300,
            }
          ];

          return http.Response(json.encode(mockResponse), 200);
        });

        final episodes = await StreamingApiService.getAllEpisodes();

        expect(episodes, isNotEmpty);
      });

      test('should sort all episodes by date newest first', () async {
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((invocation) async {
          final uri = invocation.positionalArguments[0] as Uri;
          // Extract language and category from query parameter: prefix=audio/{language}/{category}/
          final prefix = uri.queryParameters['prefix'] ?? '';
          final parts = prefix.split('/');
          final language = parts.length >= 2 ? parts[1] : 'zh-TW';
          final category = parts.length >= 3 ? parts[2] : 'startup';

          final mockResponse = [
            {
              'id': '2025-01-01-test',
              'path': '$language/$category/2025-01-01-test.m3u8',
              'title': 'Episode $language-$category',
              'category': category,
              'language': language,
              'size': 1024,
              'last_modified': '2025-01-01T10:00:00Z',
              'duration': 300,
            }
          ];

          return http.Response(json.encode(mockResponse), 200);
        });

        final episodes = await StreamingApiService.getAllEpisodes();

        expect(episodes, isNotEmpty);
        // Verify sorting (newest first)
        for (int i = 0; i < episodes.length - 1; i++) {
          expect(
            episodes[i].lastModified.isAfter(episodes[i + 1].lastModified) ||
                episodes[i]
                    .lastModified
                    .isAtSameMomentAs(episodes[i + 1].lastModified),
            isTrue,
          );
        }
      });
    });

    group('searchEpisodes', () {
      test('should search within specific language and category', () async {
        const language = 'zh-TW';
        const category = 'startup';
        const query = 'bitcoin';

        final mockResponse = [
          {
            'id': '2025-01-01-bitcoin',
            'path': 'zh-TW/startup/2025-01-01-bitcoin.m3u8',
            'title': 'Bitcoin Analysis',
            'category': 'startup',
            'language': 'zh-TW',
            'size': 1024,
            'last_modified': '2025-01-01T10:00:00Z',
            'duration': 300,
          },
          {
            'id': '2025-01-01-ethereum',
            'path': 'zh-TW/startup/2025-01-01-ethereum.m3u8',
            'title': 'Ethereum Update',
            'category': 'startup',
            'language': 'zh-TW',
            'size': 1024,
            'last_modified': '2025-01-01T11:00:00Z',
            'duration': 300,
          }
        ];

        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response(
                  json.encode(mockResponse),
                  200,
                ));

        final episodes = await StreamingApiService.searchEpisodes(
          query,
          language: language,
          category: category,
        );

        expect(episodes, hasLength(1));
        expect(episodes.first.title, equals('Bitcoin Analysis'));
      });

      test('should search within specific language across categories',
          () async {
        const language = 'zh-TW';
        const query = 'crypto';

        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((invocation) async {
          final mockResponse = [
            {
              'id': '2025-01-01-crypto',
              'path': 'zh-TW/startup/2025-01-01-crypto.m3u8',
              'title': 'Crypto Trends',
              'category': 'startup',
              'language': 'zh-TW',
              'size': 1024,
              'last_modified': '2025-01-01T10:00:00Z',
              'duration': 300,
            }
          ];

          return http.Response(json.encode(mockResponse), 200);
        });

        final episodes = await StreamingApiService.searchEpisodes(
          query,
          language: language,
        );

        expect(episodes, hasLength(greaterThan(0)));
        expect(episodes.every((e) => e.language == language), isTrue);
      });

      test('should search across all episodes when no filters provided',
          () async {
        const query = 'bitcoin';

        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((invocation) async {
          final uri = invocation.positionalArguments[0] as Uri;
          // Extract language and category from query parameter: prefix=audio/{language}/{category}/
          final prefix = uri.queryParameters['prefix'] ?? '';
          final parts = prefix.split('/');
          final language = parts.length >= 2 ? parts[1] : 'zh-TW';
          final category = parts.length >= 3 ? parts[2] : 'startup';

          final mockResponse = [
            {
              'id': '2025-01-01-bitcoin',
              'path': '$language/$category/2025-01-01-bitcoin.m3u8',
              'title': 'Bitcoin News',
              'category': category,
              'language': language,
              'size': 1024,
              'last_modified': '2025-01-01T10:00:00Z',
              'duration': 300,
            }
          ];

          return http.Response(json.encode(mockResponse), 200);
        });

        final episodes = await StreamingApiService.searchEpisodes(query);

        expect(episodes, isNotEmpty);
      });

      test('should return empty list for empty query', () async {
        const language = 'zh-TW';
        const category = 'startup';

        final mockResponse = [
          {
            'id': '2025-01-01-test',
            'path': 'zh-TW/startup/2025-01-01-test.m3u8',
            'title': 'Test Episode',
            'category': 'startup',
            'language': 'zh-TW',
            'streaming_url':
                'https://test-api.example.com/zh-TW/startup/2025-01-01-test.m3u8',
            'size': 1024,
            'last_modified': '2025-01-01T10:00:00Z',
            'duration': 300,
          }
        ];

        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response(
                  json.encode(mockResponse),
                  200,
                ));

        final episodes = await StreamingApiService.searchEpisodes(
          '',
          language: language,
          category: category,
        );

        expect(episodes, hasLength(1)); // Empty query returns all
      });

      test('should search case-insensitively', () async {
        const language = 'zh-TW';
        const category = 'startup';
        const query = 'BITCOIN';

        final mockResponse = [
          {
            'id': '2025-01-01-bitcoin',
            'path': 'zh-TW/startup/2025-01-01-bitcoin.m3u8',
            'title': 'bitcoin analysis',
            'category': 'startup',
            'language': 'zh-TW',
            'size': 1024,
            'last_modified': '2025-01-01T10:00:00Z',
            'duration': 300,
          }
        ];

        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response(
                  json.encode(mockResponse),
                  200,
                ));

        final episodes = await StreamingApiService.searchEpisodes(
          query,
          language: language,
          category: category,
        );

        expect(episodes, hasLength(1));
      });

      test('should search in title, id, and category fields', () async {
        const language = 'zh-TW';
        const category = 'startup';

        final mockResponse = [
          {
            'id': '2025-01-01-bitcoin',
            'path': 'zh-TW/startup/2025-01-01-bitcoin.m3u8',
            'title': 'Daily News',
            'category': 'startup',
            'language': 'zh-TW',
            'size': 1024,
            'last_modified': '2025-01-01T10:00:00Z',
            'duration': 300,
          }
        ];

        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response(
                  json.encode(mockResponse),
                  200,
                ));

        // Search by ID
        final episodesById = await StreamingApiService.searchEpisodes(
          'bitcoin',
          language: language,
          category: category,
        );
        expect(episodesById, hasLength(1));

        // Search by category
        final episodesByCategory = await StreamingApiService.searchEpisodes(
          'startup',
          language: language,
          category: category,
        );
        expect(episodesByCategory, hasLength(1));
      });
    });

    group('Utility Methods', () {
      test('testConnectivity should return true for successful connection',
          () async {
        final mockResponse = [
          {
            'id': '2025-01-01-test',
            'path': 'zh-TW/startup/2025-01-01-test.m3u8',
            'title': 'Test Episode',
            'category': 'startup',
            'language': 'zh-TW',
            'streaming_url':
                'https://test-api.example.com/zh-TW/startup/2025-01-01-test.m3u8',
            'size': 1024,
            'last_modified': '2025-01-01T10:00:00Z',
            'duration': 300,
          }
        ];

        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response(
                  json.encode(mockResponse),
                  200,
                ));

        final isConnected = await StreamingApiService.testConnectivity();
        expect(isConnected, isTrue);
      });

      test('testConnectivity should return false for failed connection',
          () async {
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenThrow(http.ClientException('Network error'));

        final isConnected = await StreamingApiService.testConnectivity();
        expect(isConnected, isFalse);
      });

      test('getApiStatus should return correct API information', () {
        final status = StreamingApiService.getApiStatus();

        expect(status, isA<Map<String, dynamic>>());
        expect(status.containsKey('baseUrl'), isTrue);
        expect(status.containsKey('environment'), isTrue);
        expect(status.containsKey('supportedLanguages'), isTrue);
        expect(status.containsKey('supportedCategories'), isTrue);
        expect(status.containsKey('apiTimeout'), isTrue);
      });

      test('validateStreamingUrl should return true for valid URL', () async {
        const testUrl = 'https://example.com/test.m3u8';

        when(mockHttpClient.head(any))
            .thenAnswer((_) async => http.Response('', 200));

        final isValid = await StreamingApiService.validateStreamingUrl(testUrl);
        expect(isValid, isTrue);
      });

      test('validateStreamingUrl should return false for invalid URL',
          () async {
        const testUrl = 'https://example.com/invalid.m3u8';

        when(mockHttpClient.head(any))
            .thenAnswer((_) async => http.Response('Not Found', 404));

        final isValid = await StreamingApiService.validateStreamingUrl(testUrl);
        expect(isValid, isFalse);
      });

      test('validateStreamingUrl should return false for network error',
          () async {
        const testUrl = 'https://example.com/error.m3u8';

        when(mockHttpClient.head(any))
            .thenThrow(http.ClientException('Network error'));

        final isValid = await StreamingApiService.validateStreamingUrl(testUrl);
        expect(isValid, isFalse);
      });
    });

    group('Exception Classes', () {
      test('NetworkException should format correctly', () {
        const exception = NetworkException('Network connection failed');
        expect(exception.toString(),
            equals('NetworkException: Network connection failed'));
        expect(exception.message, equals('Network connection failed'));
      });

      test('ApiException should format correctly without status code', () {
        const exception = ApiException('API request failed');
        expect(
            exception.toString(), equals('ApiException: API request failed'));
        expect(exception.message, equals('API request failed'));
        expect(exception.statusCode, isNull);
      });

      test('ApiException should format correctly with status code', () {
        const exception = ApiException('API request failed', 404);
        expect(exception.toString(),
            equals('ApiException: API request failed (Status: 404)'));
        expect(exception.statusCode, equals(404));
      });

      test('TimeoutException should format correctly', () {
        const exception = TimeoutException('Request timed out');
        expect(exception.toString(),
            equals('TimeoutException: Request timed out'));
        expect(exception.message, equals('Request timed out'));
      });

      test('UnknownException should format correctly', () {
        const exception = UnknownException('Unknown error occurred');
        expect(exception.toString(),
            equals('UnknownException: Unknown error occurred'));
        expect(exception.message, equals('Unknown error occurred'));
      });
    });
  });
}

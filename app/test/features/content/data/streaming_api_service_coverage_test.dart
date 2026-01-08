import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:from_fed_to_chain_app/features/content/data/streaming_api_service.dart';
import 'package:from_fed_to_chain_app/core/config/api_config.dart';
import 'package:from_fed_to_chain_app/core/exceptions/app_exceptions.dart';

@GenerateMocks([http.Client])
import 'streaming_api_service_coverage_test.mocks.dart';

void main() {
  group('StreamingApiService Coverage Tests', () {
    late MockClient mockClient;
    late StreamingApiService service;

    setUp(() {
      mockClient = MockClient();
      // Create instance with injected mock client
      service = StreamingApiService(client: mockClient);
    });

    tearDown(() {
      service.close();
      // Also reset the singleton for backward compatibility tests
      StreamingApiService.resetInstance();
    });

    test('fetchEpisodeList returns parsed episodes on success', () async {
      const lang = 'zh-TW';
      const cat = 'daily-news';
      final url = Uri.parse(ApiConfig.getListUrl(lang, cat));

      when(mockClient.get(url, headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response(
              jsonEncode([
                {
                  'id': '1',
                  'path': 'path/to/ep1',
                  'title': 'Ep 1',
                  'duration': 60,
                  'size': 1024,
                  'last_modified': '2025-01-01T00:00:00Z'
                }
              ]),
              200));

      final result = await service.fetchEpisodeList(lang, cat);
      expect(result.length, 1);
      expect(result.first.id, '1');
      expect(result.first.language, lang);
    });

    test('fetchEpisodeList handles error status codes', () async {
      final url = Uri.parse(ApiConfig.getListUrl('zh-TW', 'daily-news'));
      when(mockClient.get(url, headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response('Not Found', 404));

      expect(
        () => service.fetchEpisodeList('zh-TW', 'daily-news'),
        throwsA(isA<ApiException>()),
      );
    });

    test('fetchEpisodeList handles network exceptions', () async {
      final url = Uri.parse(ApiConfig.getListUrl('zh-TW', 'daily-news'));
      when(mockClient.get(url, headers: anyNamed('headers')))
          .thenThrow(http.ClientException('Connection failed'));

      expect(
        () => service.fetchEpisodeList('zh-TW', 'daily-news'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('checkStreamingUrl success', () async {
      const url = 'https://example.com/audio.m3u8';
      when(mockClient.head(Uri.parse(url)))
          .thenAnswer((_) async => http.Response('', 200));

      final result = await service.checkStreamingUrl(url);
      expect(result, isTrue);
    });

    test('checkStreamingUrl failure', () async {
      const url = 'https://example.com/audio.m3u8';
      when(mockClient.head(Uri.parse(url)))
          .thenAnswer((_) async => http.Response('', 404));

      final result = await service.checkStreamingUrl(url);
      expect(result, isFalse);
    });

    test('fetchAllEpisodesForLanguage aggregates correctly', () async {
      // Mock for each category
      for (final cat in ApiConfig.supportedCategories) {
        final url = Uri.parse(ApiConfig.getListUrl('en-US', cat));
        when(mockClient.get(url, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response(
                jsonEncode([
                  {'id': 'ep-$cat', 'path': 'path/$cat', 'title': 'Ep $cat'}
                ]),
                200));
      }

      final result = await service.fetchAllEpisodesForLanguage('en-US');
      expect(result.length, ApiConfig.supportedCategories.length);
    });

    test('fetchSearchEpisodes filters correctly', () async {
      // Setup mock to return something
      final url = Uri.parse(ApiConfig.getListUrl('en-US', 'daily-news'));
      when(mockClient.get(url, headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response(
              jsonEncode([
                {'id': 'bitcoin', 'path': 'p', 'title': 'Bitcoin News'}
              ]),
              200));

      final result = await service.fetchSearchEpisodes('bitcoin',
          language: 'en-US', category: 'daily-news');
      expect(result.length, 1);

      final emptyResult = await service.fetchSearchEpisodes('ether',
          language: 'en-US', category: 'daily-news');
      expect(emptyResult, isEmpty);
    });

    test('invalid inputs throw ArgumentError', () async {
      expect(() => service.fetchEpisodeList('bad-lang', 'daily-news'),
          throwsArgumentError);
      expect(() => service.fetchEpisodeList('en-US', 'bad-cat'),
          throwsArgumentError);
      expect(() => service.fetchAllEpisodesForLanguage('bad-lang'),
          throwsArgumentError);
    });

    group('Instance-based DI', () {
      test('creates service with custom client', () {
        final customClient = MockClient();
        final customService = StreamingApiService(client: customClient);
        expect(customService, isNotNull);
        customService.close();
      });

      test('creates service with default client when none provided', () {
        final defaultService = StreamingApiService();
        expect(defaultService, isNotNull);
        defaultService.close();
      });

      test('singleton instance is accessible', () {
        StreamingApiService.resetInstance();
        // Access the singleton
        final instance1 = StreamingApiService.instance;
        final instance2 = StreamingApiService.instance;
        expect(identical(instance1, instance2), isTrue);
      });

      test('resetInstance clears the singleton', () {
        final instance1 = StreamingApiService.instance;
        StreamingApiService.resetInstance();
        final instance2 = StreamingApiService.instance;
        expect(identical(instance1, instance2), isFalse);
      });
    });

    group('Static methods (backward compatibility)', () {
      test('setHttpClient updates singleton', () {
        final customClient = MockClient();
        StreamingApiService.setHttpClient(customClient);

        // Verify the singleton was updated
        expect(StreamingApiService.instance, isNotNull);

        // Clean up
        StreamingApiService.resetInstance();
      });

      test('static getEpisodeList delegates to instance', () async {
        final testClient = MockClient();
        StreamingApiService.setHttpClient(testClient);

        final url = Uri.parse(ApiConfig.getListUrl('zh-TW', 'startup'));
        when(testClient.get(url, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response(
                jsonEncode([
                  {'id': '1', 'path': 'p1', 'title': 'Test'}
                ]),
                200));

        final result =
            await StreamingApiService.getEpisodeList('zh-TW', 'startup');
        expect(result.length, 1);

        StreamingApiService.resetInstance();
      });
    });

    test('fetchApiStatus returns correct configuration', () {
      final status = service.fetchApiStatus();

      expect(status['baseUrl'], isNotNull);
      expect(status['supportedLanguages'], ApiConfig.supportedLanguages);
      expect(status['supportedCategories'], ApiConfig.supportedCategories);
      expect(status['apiTimeout'], ApiConfig.apiTimeout.inSeconds);
    });
  });
}

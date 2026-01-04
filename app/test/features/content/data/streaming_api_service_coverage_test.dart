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

    setUp(() {
      mockClient = MockClient();
      StreamingApiService.setHttpClient(mockClient);
    });

    tearDown(() {
      StreamingApiService.dispose();
    });

    test('getEpisodeList returns parsed episodes on success', () async {
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

      final result = await StreamingApiService.getEpisodeList(lang, cat);
      expect(result.length, 1);
      expect(result.first.id, '1');
      expect(result.first.language, lang);
    });

    test('getEpisodeList handles error status codes', () async {
      final url = Uri.parse(ApiConfig.getListUrl('zh-TW', 'daily-news'));
      when(mockClient.get(url, headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response('Not Found', 404));

      expect(
        () => StreamingApiService.getEpisodeList('zh-TW', 'daily-news'),
        throwsA(isA<ApiException>()),
      );
    });

    test('getEpisodeList handles network exceptions', () async {
      final url = Uri.parse(ApiConfig.getListUrl('zh-TW', 'daily-news'));
      when(mockClient.get(url, headers: anyNamed('headers')))
          .thenThrow(http.ClientException('Connection failed'));

      expect(
        () => StreamingApiService.getEpisodeList('zh-TW', 'daily-news'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('validateStreamingUrl success', () async {
      const url = 'https://example.com/audio.m3u8';
      when(mockClient.head(Uri.parse(url)))
          .thenAnswer((_) async => http.Response('', 200));

      final result = await StreamingApiService.validateStreamingUrl(url);
      expect(result, isTrue);
    });

    test('validateStreamingUrl failure', () async {
      const url = 'https://example.com/audio.m3u8';
      when(mockClient.head(Uri.parse(url)))
          .thenAnswer((_) async => http.Response('', 404));

      final result = await StreamingApiService.validateStreamingUrl(url);
      expect(result, isFalse);
    });

    test('getAllEpisodesForLanguage aggregates correctly', () async {
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

      final result =
          await StreamingApiService.getAllEpisodesForLanguage('en-US');
      expect(result.length, ApiConfig.supportedCategories.length);
    });

    test('searchEpisodes filters correctly', () async {
      // Setup mock to return something
      final url = Uri.parse(ApiConfig.getListUrl('en-US', 'daily-news'));
      when(mockClient.get(url, headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response(
              jsonEncode([
                {'id': 'bitcoin', 'path': 'p', 'title': 'Bitcoin News'}
              ]),
              200));

      final result = await StreamingApiService.searchEpisodes('bitcoin',
          language: 'en-US', category: 'daily-news');
      expect(result.length, 1);

      final emptyResult = await StreamingApiService.searchEpisodes('ether',
          language: 'en-US', category: 'daily-news');
      expect(emptyResult, isEmpty);
    });

    test('invalid inputs throw ArgumentError', () async {
      expect(() => StreamingApiService.getEpisodeList('bad-lang', 'daily-news'),
          throwsArgumentError);
      expect(() => StreamingApiService.getEpisodeList('en-US', 'bad-cat'),
          throwsArgumentError);
      expect(() => StreamingApiService.getAllEpisodesForLanguage('bad-lang'),
          throwsArgumentError);
    });
  });
}

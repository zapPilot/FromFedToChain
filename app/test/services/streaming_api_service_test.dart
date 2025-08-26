import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:from_fed_to_chain_app/services/streaming_api_service.dart';
import 'package:from_fed_to_chain_app/config/api_config.dart';

import '../test_utils.dart';

void main() {
  group('StreamingApiService Tests', () {
    setUpAll(() async {
      // Initialize dotenv for tests - create in-memory environment for testing
      try {
        await dotenv.load();
      } catch (e) {
        // If no .env file exists, set up minimal test environment
        dotenv.testLoad(fileInput: '''
ENVIRONMENT=test
STREAMING_BASE_URL=http://mock-api.test
API_TIMEOUT_SECONDS=30
STREAM_TIMEOUT_SECONDS=30
''');
      }
    });

    group('Static Method Interface', () {
      test('getEpisodeList method signature exists', () {
        expect(StreamingApiService.getEpisodeList, isA<Function>());
      });

      test('getEpisodeList validates language parameter', () async {
        // Test invalid language - should throw ArgumentError synchronously
        expect(
          () => StreamingApiService.getEpisodeList('invalid-lang', 'startup'),
          throwsArgumentError,
        );
      });

      test('getEpisodeList validates category parameter', () async {
        // Test invalid category - should throw ArgumentError synchronously
        expect(
          () => StreamingApiService.getEpisodeList('zh-TW', 'invalid-category'),
          throwsArgumentError,
        );
      });

      test('getAllEpisodes method exists', () {
        expect(StreamingApiService.getAllEpisodes, isA<Function>());
      });

      test('getAllEpisodesForLanguage validates language parameter', () async {
        expect(
          () => StreamingApiService.getAllEpisodesForLanguage('invalid-lang'),
          throwsArgumentError,
        );
      });

      test('searchEpisodes method exists and accepts query', () {
        expect(StreamingApiService.searchEpisodes, isA<Function>());
      });

      test('testConnectivity method exists', () {
        expect(StreamingApiService.testConnectivity, isA<Function>());
      });

      test('validateStreamingUrl method exists', () {
        expect(StreamingApiService.validateStreamingUrl, isA<Function>());
      });

      test('dispose method exists', () {
        expect(StreamingApiService.dispose, isA<Function>());
      });
    });

    group('Exception Types', () {
      test('StreamingApiException hierarchy exists', () {
        const networkException = NetworkException('Network error');
        const apiException = ApiException('API error');
        const timeoutException = TimeoutException('Timeout error');
        const unknownException = UnknownException('Unknown error');

        expect(networkException, isA<StreamingApiException>());
        expect(apiException, isA<StreamingApiException>());
        expect(timeoutException, isA<StreamingApiException>());
        expect(unknownException, isA<StreamingApiException>());

        expect(networkException.message, equals('Network error'));
        expect(apiException.message, equals('API error'));
        expect(timeoutException.message, equals('Timeout error'));
        expect(unknownException.message, equals('Unknown error'));
      });

      test('ApiException includes status code', () {
        const apiException = ApiException('Error with status', 404);
        expect(apiException.statusCode, equals(404));
        expect(apiException.toString(), contains('Status: 404'));
      });

      test('Exception toString methods work correctly', () {
        const networkException = NetworkException('Network error');
        const apiException = ApiException('API error', 500);
        const timeoutException = TimeoutException('Timeout error');
        const unknownException = UnknownException('Unknown error');

        expect(networkException.toString(), contains('NetworkException'));
        expect(apiException.toString(), contains('ApiException'));
        expect(timeoutException.toString(), contains('TimeoutException'));
        expect(unknownException.toString(), contains('UnknownException'));
      });
    });

    group('Configuration Integration', () {
      test('API config provides necessary constants', () {
        expect(ApiConfig.supportedLanguages, isA<List<String>>());
        expect(ApiConfig.supportedCategories, isA<List<String>>());
        expect(ApiConfig.supportedLanguages.contains('zh-TW'), isTrue);
        expect(ApiConfig.supportedLanguages.contains('en-US'), isTrue);
        expect(ApiConfig.supportedCategories.contains('startup'), isTrue);
      });

      test('API config validation methods work', () {
        expect(ApiConfig.isValidLanguage('zh-TW'), isTrue);
        expect(ApiConfig.isValidLanguage('invalid-lang'), isFalse);
        expect(ApiConfig.isValidCategory('startup'), isTrue);
        expect(ApiConfig.isValidCategory('invalid-category'), isFalse);
      });

      test('getApiStatus returns configuration map with expected keys', () {
        final status = StreamingApiService.getApiStatus();

        expect(status, isA<Map<String, dynamic>>());
        expect(status.containsKey('baseUrl'), isTrue);
        expect(status.containsKey('environment'), isTrue);
        expect(status.containsKey('isProduction'), isTrue);
        expect(status.containsKey('supportedLanguages'), isTrue);
        expect(status.containsKey('supportedCategories'), isTrue);
        expect(status.containsKey('apiTimeout'), isTrue);
        expect(status.containsKey('streamTimeout'), isTrue);
      });
    });

    group('AudioFile Model Integration', () {
      test('creates valid AudioFile from test data', () {
        final testAudioFile = TestUtils.createSampleAudioFile(
          id: 'test-episode',
          title: 'Test Episode',
          language: 'en-US',
          category: 'daily-news',
          streamingUrl: 'https://example.com/test.m3u8',
        );

        expect(testAudioFile.id, equals('test-episode'));
        expect(testAudioFile.title, equals('Test Episode'));
        expect(testAudioFile.language, equals('en-US'));
        expect(testAudioFile.category, equals('daily-news'));
        expect(testAudioFile.streamingUrl,
            equals('https://example.com/test.m3u8'));
      });

      test('validates AudioFile required fields', () {
        final testAudioFile = TestUtils.createSampleAudioFile();

        expect(testAudioFile.id, isNotEmpty);
        expect(testAudioFile.title, isNotEmpty);
        expect(testAudioFile.language, isNotEmpty);
        expect(testAudioFile.category, isNotEmpty);
        expect(testAudioFile.streamingUrl, isNotEmpty);
        expect(testAudioFile.path, isNotEmpty);
      });

      test('handles optional AudioFile fields', () {
        final testAudioFile = TestUtils.createSampleAudioFile(
          duration: const Duration(minutes: 10),
          fileSizeBytes: 2048000,
        );

        expect(testAudioFile.duration, equals(const Duration(minutes: 10)));
        expect(testAudioFile.fileSizeBytes, equals(2048000));
        expect(testAudioFile.lastModified, isA<DateTime>());
      });
    });

    group('Test Utilities Integration', () {
      test('TestUtils creates valid sample AudioFile list', () {
        final sampleList = TestUtils.createSampleAudioFileList(3);

        expect(sampleList.length, equals(3));
        expect(sampleList.every((file) => file.id.isNotEmpty), isTrue);
        expect(sampleList.every((file) => file.title.isNotEmpty), isTrue);
        expect(
            sampleList.every((file) => file.streamingUrl.isNotEmpty), isTrue);
      });

      test('TestUtils validation helper works with AudioFile', () {
        final testFile = TestUtils.createSampleAudioFile();

        // This should not throw
        expect(() => TestUtils.validateAudioFile(testFile), returnsNormally);
      });

      test('TestUtils creates files with varied attributes', () {
        final sampleList = TestUtils.createSampleAudioFileList(6);

        // Should have different categories based on modulo operation
        final categories = sampleList.map((f) => f.category).toSet();
        expect(categories.length, greaterThan(1));

        // Should have different languages based on modulo operation
        final languages = sampleList.map((f) => f.language).toSet();
        expect(languages.length, greaterThan(1));
      });
    });
  });
}

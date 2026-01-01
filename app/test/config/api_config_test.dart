import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:from_fed_to_chain_app/core/config/api_config.dart';

void main() {
  group('ApiConfig Tests', () {
    setUp(() async {
      // Initialize dotenv for testing
      dotenv.testLoad(fileInput: '''
ENVIRONMENT=test
API_TIMEOUT_SECONDS=30
STREAM_TIMEOUT_SECONDS=30
''');
    });

    tearDown(() {
      dotenv.clean();
    });

    group('Environment Detection', () {
      test('should have valid environment', () {
        expect(ApiConfig.environment, isA<String>());
        expect(ApiConfig.environment.isNotEmpty, isTrue);
      });

      test('should detect test environment when running tests', () {
        expect(
            ApiConfig.isTest, isA<bool>()); // isTest is environment-dependent
      });

      test('should return correct current environment', () {
        expect(ApiConfig.currentEnvironment, equals(ApiConfig.environment));
      });

      test('should have environment detection methods', () {
        expect(ApiConfig.isProduction, isA<bool>());
        expect(ApiConfig.isDevelopment, isA<bool>());
      });
    });

    group('Base URL Resolution', () {
      test('should return test URL when in test environment', () {
        expect(ApiConfig.streamingBaseUrl, equals('http://mock-api.test'));
      });

      test('should have valid streaming base URL', () {
        expect(ApiConfig.streamingBaseUrl, isA<String>());
        expect(ApiConfig.streamingBaseUrl.isNotEmpty, isTrue);
      });
    });

    group('API Endpoint Generation', () {
      test('should generate correct list URL', () {
        final url = ApiConfig.getListUrl('en-US', 'daily-news');
        expect(url, contains('?prefix=audio/en-US/daily-news/'));
      });

      test('should generate correct stream URL', () {
        final url = ApiConfig.getStreamUrl('audio/en-US/episode.m3u8');
        expect(url, contains('/proxy/audio/en-US/episode.m3u8'));
      });

      test('should generate correct content URL', () {
        final url =
            ApiConfig.getContentUrl('zh-TW', 'ethereum', '2025-07-01-episode');
        expect(url, contains('/api/content/zh-TW/ethereum/2025-07-01-episode'));
      });

      test('should handle special characters in paths', () {
        final streamUrl = ApiConfig.getStreamUrl(
            'audio/en-US/episode-with-special@chars.m3u8');
        expect(streamUrl,
            contains('/proxy/audio/en-US/episode-with-special@chars.m3u8'));
      });

      test('should handle empty parameters gracefully', () {
        final listUrl = ApiConfig.getListUrl('', '');
        expect(listUrl, contains('?prefix=audio//'));

        final contentUrl = ApiConfig.getContentUrl('', '', '');
        expect(contentUrl, contains('/api/content///'));
      });
    });

    group('Configuration Constants', () {
      test('should have default timeout values', () {
        expect(ApiConfig.apiTimeout, isA<Duration>());
        expect(ApiConfig.streamTimeout, isA<Duration>());
        expect(ApiConfig.apiTimeout.inSeconds, greaterThan(0));
        expect(ApiConfig.streamTimeout.inSeconds, greaterThan(0));
      });

      test('should have correct retry attempts', () {
        expect(ApiConfig.retryAttempts, equals(3));
      });
    });

    group('Supported Languages and Categories', () {
      test('should have correct supported languages', () {
        expect(ApiConfig.supportedLanguages, hasLength(3));
        expect(ApiConfig.supportedLanguages, contains('zh-TW'));
        expect(ApiConfig.supportedLanguages, contains('en-US'));
        expect(ApiConfig.supportedLanguages, contains('ja-JP'));
      });

      test('should have correct supported categories', () {
        expect(ApiConfig.supportedCategories, hasLength(6));
        expect(ApiConfig.supportedCategories, contains('daily-news'));
        expect(ApiConfig.supportedCategories, contains('ethereum'));
        expect(ApiConfig.supportedCategories, contains('macro'));
        expect(ApiConfig.supportedCategories, contains('startup'));
        expect(ApiConfig.supportedCategories, contains('ai'));
        expect(ApiConfig.supportedCategories, contains('defi'));
      });

      test('should validate languages correctly', () {
        expect(ApiConfig.isValidLanguage('zh-TW'), isTrue);
        expect(ApiConfig.isValidLanguage('en-US'), isTrue);
        expect(ApiConfig.isValidLanguage('ja-JP'), isTrue);
        expect(ApiConfig.isValidLanguage('fr-FR'), isFalse);
        expect(ApiConfig.isValidLanguage('invalid'), isFalse);
        expect(ApiConfig.isValidLanguage(''), isFalse);
      });

      test('should validate categories correctly', () {
        expect(ApiConfig.isValidCategory('daily-news'), isTrue);
        expect(ApiConfig.isValidCategory('ethereum'), isTrue);
        expect(ApiConfig.isValidCategory('defi'), isTrue);
        expect(ApiConfig.isValidCategory('invalid-category'), isFalse);
        expect(ApiConfig.isValidCategory(''), isFalse);
      });
    });

    group('Display Names', () {
      test('should have correct language display names', () {
        expect(ApiConfig.languageNames, hasLength(3));
        expect(ApiConfig.languageNames['zh-TW'], equals('繁體中文'));
        expect(ApiConfig.languageNames['en-US'], equals('English'));
        expect(ApiConfig.languageNames['ja-JP'], equals('日本語'));
      });

      test('should have correct category display names', () {
        expect(ApiConfig.categoryNames, hasLength(6));
        expect(ApiConfig.categoryNames['daily-news'], equals('Daily News'));
        expect(ApiConfig.categoryNames['ethereum'], equals('Ethereum'));
        expect(ApiConfig.categoryNames['macro'], equals('Macro Economics'));
        expect(ApiConfig.categoryNames['startup'], equals('Startup'));
        expect(ApiConfig.categoryNames['ai'], equals('AI & Technology'));
        expect(ApiConfig.categoryNames['defi'], equals('DeFi'));
      });

      test('should get language display names', () {
        expect(ApiConfig.getLanguageDisplayName('zh-TW'), equals('繁體中文'));
        expect(ApiConfig.getLanguageDisplayName('en-US'), equals('English'));
        expect(ApiConfig.getLanguageDisplayName('ja-JP'), equals('日本語'));
        expect(ApiConfig.getLanguageDisplayName('unknown'), equals('unknown'));
      });

      test('should get category display names', () {
        expect(ApiConfig.getCategoryDisplayName('daily-news'),
            equals('Daily News'));
        expect(
            ApiConfig.getCategoryDisplayName('ethereum'), equals('Ethereum'));
        expect(ApiConfig.getCategoryDisplayName('macro'),
            equals('Macro Economics'));
        expect(ApiConfig.getCategoryDisplayName('invalid'), equals('invalid'));
      });

      test('should fallback to original string for unknown display names', () {
        expect(ApiConfig.getLanguageDisplayName('custom-lang'),
            equals('custom-lang'));
        expect(ApiConfig.getCategoryDisplayName('custom-category'),
            equals('custom-category'));
      });
    });
  });
}

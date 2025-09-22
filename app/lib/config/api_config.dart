import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Production-ready API configuration for signed URL streaming service
///
/// Features:
/// ✅ Production URLs: https://signed-url.davidtnfsh.workers.dev
/// ✅ Multi-environment support (production, staging, development, test)
/// ✅ Optimized streaming with pre-signed URLs
/// ✅ Backwards compatibility with path-based URL construction
/// ✅ .env file support
class ApiConfig {
  // Environment detection with safe fallback
  static String get environment {
    try {
      return dotenv.get('ENVIRONMENT', fallback: 'production');
    } catch (e) {
      // If dotenv is not initialized, return test environment for tests
      return const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false)
          ? 'test'
          : 'production';
    }
  }
  static const bool isTest =
      bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);

  // Base URLs by environment
  static const Map<String, String> _streamingUrls = {
    'production': 'https://signed-url.davidtnfsh.workers.dev',
    'staging':
        'https://staging-signed-url.davidtnfsh.workers.dev', // If available
    'development': 'https://signed-url.davidtnfsh.workers.dev',
    'test': 'http://mock-api.test',
  };

  // Dynamic URL resolution with safe fallback
  static String get streamingBaseUrl {
    if (isTest) return _streamingUrls['test']!;

    // Check for direct URL override in .env (with safe fallback)
    try {
      final envUrl = dotenv.get('STREAMING_BASE_URL', fallback: '');
      if (envUrl.isNotEmpty) return envUrl;
    } catch (e) {
      // dotenv not initialized, use default
    }

    return _streamingUrls[environment] ?? _streamingUrls['production']!;
  }

  // API endpoints using production format
  static String getListUrl(String language, String category) =>
      '$streamingBaseUrl?prefix=audio/$language/$category/';

  static String getStreamUrl(String path) => '$streamingBaseUrl/proxy/$path';

  static String getContentUrl(String language, String category, String id) =>
      '$streamingBaseUrl/api/content/$language/$category/$id';

  // Configuration constants with safe fallback
  static Duration get apiTimeout {
    try {
      return Duration(
          seconds: int.parse(dotenv.get('API_TIMEOUT_SECONDS', fallback: '30')));
    } catch (e) {
      return const Duration(seconds: 30); // Default fallback
    }
  }

  static Duration get streamTimeout {
    try {
      return Duration(
          seconds: int.parse(dotenv.get('STREAM_TIMEOUT_SECONDS', fallback: '30')));
    } catch (e) {
      return const Duration(seconds: 30); // Default fallback
    }
  }
  static const int retryAttempts = 3;

  // Supported languages and categories (synced with ContentSchema.js)
  static const List<String> supportedLanguages = ['zh-TW', 'en-US', 'ja-JP'];
  static const List<String> supportedCategories = [
    'daily-news',
    'ethereum',
    'macro',
    'startup',
    'ai',
    'defi'
  ];

  // Language display names
  static const Map<String, String> languageNames = {
    'zh-TW': '繁體中文',
    'en-US': 'English',
    'ja-JP': '日本語',
  };

  // Category display names
  static const Map<String, String> categoryNames = {
    'daily-news': 'Daily News',
    'ethereum': 'Ethereum',
    'macro': 'Macro Economics',
    'startup': 'Startup',
    'ai': 'AI & Technology',
    'defi': 'DeFi',
  };

  // Helper methods for validation
  static bool isValidLanguage(String language) =>
      supportedLanguages.contains(language);
  static bool isValidCategory(String category) =>
      supportedCategories.contains(category);

  static String getLanguageDisplayName(String language) =>
      languageNames[language] ?? language;

  static String getCategoryDisplayName(String category) =>
      categoryNames[category] ?? category;

  // Debug information
  static String get currentEnvironment => environment;
  static bool get isProduction => environment == 'production';
  static bool get isDevelopment => environment == 'development';
}

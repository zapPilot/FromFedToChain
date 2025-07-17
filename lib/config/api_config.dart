/// Production-ready API configuration for signed URL streaming service
/// 
/// Features:
/// ✅ Production URLs: https://signed-url.davidtnfsh.workers.dev
/// ✅ Multi-environment support (production, staging, development, test)
/// ✅ Optimized streaming with pre-signed URLs
/// ✅ Backwards compatibility with path-based URL construction
class ApiConfig {
  // Environment detection
  static const String environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'production');
  static const bool isTest = bool.fromEnvironment('dart.library.io', defaultValue: false);
  
  // Base URLs by environment
  static const Map<String, String> _streamingUrls = {
    'production': 'https://signed-url.davidtnfsh.workers.dev',
    'staging': 'https://staging-signed-url.davidtnfsh.workers.dev', // If available
    'development': 'https://signed-url.davidtnfsh.workers.dev',
    'test': 'http://mock-api.test',
  };
  
  // Dynamic URL resolution
  static String get streamingBaseUrl {
    if (isTest) return _streamingUrls['test']!;
    return _streamingUrls[environment] ?? _streamingUrls['production']!;
  }
  
  // API endpoints using production format
  static String getListUrl(String language, String category) =>
      '$streamingBaseUrl/list?prefix=audio/$language/$category/';
  
  static String getStreamUrl(String path) =>
      '$streamingBaseUrl/?path=${Uri.encodeComponent(path)}';
  
  // Configuration constants
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration streamTimeout = Duration(seconds: 30);
  static const int retryAttempts = 3;
  
  // Supported languages and categories (synced with ContentSchema.js)
  static const List<String> supportedLanguages = ['zh-TW', 'en-US', 'ja-JP'];
  static const List<String> supportedCategories = ['daily-news', 'ethereum', 'macro', 'startup', 'ai', 'defi'];
  
  // Helper methods for validation
  static bool isValidLanguage(String language) => supportedLanguages.contains(language);
  static bool isValidCategory(String category) => supportedCategories.contains(category);
  
  // Debug information
  static String get currentEnvironment => environment;
  static bool get isProduction => environment == 'production';
  static bool get isDevelopment => environment == 'development';
}
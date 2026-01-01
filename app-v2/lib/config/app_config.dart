/// Application-wide configuration constants
/// Contains languages, categories, and UI constants for the From Fed to Chain app
class AppConfig {
  AppConfig._();

  // ===== Languages =====
  static const String defaultLanguage = 'en-US';
  static const String allCategoriesKey = 'all';

  static const List<String> supportedLanguages = [
    'zh-TW', // Traditional Chinese
    'en-US', // English
    'ja-JP', // Japanese
  ];

  static const Map<String, String> languageNames = {
    'zh-TW': '繁體中文',
    'en-US': 'English',
    'ja-JP': '日本語',
  };

  static const Map<String, String> languageFlags = {
    'zh-TW': '🇹🇼',
    'en-US': '🇺🇸',
    'ja-JP': '🇯🇵',
  };

  // ===== Categories =====
  static const List<String> supportedCategories = [
    'daily-news',
    'ethereum',
    'macro',
    'startup',
    'ai',
    'defi',
  ];

  static const Map<String, String> categoryNames = {
    'all': 'All',
    'daily-news': 'Daily News',
    'ethereum': 'Ethereum',
    'macro': 'Macro Economics',
    'startup': 'Startup',
    'ai': 'AI',
    'defi': 'DeFi',
  };

  static const Map<String, String> categoryEmojis = {
    'daily-news': '📰',
    'ethereum': '⚡',
    'macro': '📊',
    'startup': '🚀',
    'ai': '🤖',
    'defi': '💎',
  };

  // ===== UI Constants =====
  static const double minPlayerHeight = 80.0;
  static const double maxPlayerHeight = 600.0;
  static const double contentCardHeight = 120.0;
  static const double languageTabHeight = 48.0;
  static const double categoryChipHeight = 56.0;

  // ===== Animation Durations =====
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // ===== Search & Filtering =====
  static const Duration searchDebounceDelay = Duration(milliseconds: 300);
  static const int maxSearchResults = 100;

  // ===== App Info =====
  static const String appName = 'From Fed to Chain';
  static const String appVersion = '2.0.0';
  static const String appDescription =
      'Simplified audio streaming app for crypto/macro economics content';

  // ===== Helper Methods =====
  static String getLanguageName(String languageCode) {
    return languageNames[languageCode] ?? languageCode;
  }

  static String getLanguageFlag(String languageCode) {
    return languageFlags[languageCode] ?? '';
  }

  static String getCategoryName(String categoryKey) {
    return categoryNames[categoryKey] ?? categoryKey;
  }

  static String getCategoryEmoji(String categoryKey) {
    return categoryEmojis[categoryKey] ?? '';
  }

  static bool isValidLanguage(String languageCode) {
    return supportedLanguages.contains(languageCode);
  }

  static bool isValidCategory(String categoryKey) {
    return categoryKey == allCategoriesKey ||
        supportedCategories.contains(categoryKey);
  }
}

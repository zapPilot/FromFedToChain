import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:from_fed_to_chain_app/features/content/data/user_preferences_service.dart';
import 'package:from_fed_to_chain_app/core/config/api_config.dart';

void main() {
  late UserPreferencesService service;

  setUp(() async {
    // Set up mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    service = UserPreferencesService();
  });

  tearDown(() {
    service.dispose();
  });

  group('UserPreferencesService - Default Values', () {
    test('should have default language', () {
      expect(service.selectedLanguage, ApiConfig.defaultLanguage);
    });

    test('should have default category as all', () {
      expect(service.selectedCategory, 'all');
    });

    test('should have empty search query', () {
      expect(service.searchQuery, '');
    });

    test('should have default sort order as newest', () {
      expect(service.sortOrder, 'newest');
    });

    test('should have dark mode enabled by default', () {
      expect(service.isDarkMode, isTrue);
    });

    test('should have default playback speed of 1.0', () {
      expect(service.playbackSpeed, 1.0);
    });

    test('should have autoplay enabled by default', () {
      expect(service.autoplayEnabled, isTrue);
    });

    test('should have download over wifi only enabled', () {
      expect(service.downloadOverWifiOnly, isTrue);
    });

    test('should have default cache size of 100', () {
      expect(service.cacheSize, 100);
    });

    test('should have notifications enabled by default', () {
      expect(service.notificationsEnabled, isTrue);
      expect(service.newEpisodeNotifications, isTrue);
      expect(service.downloadCompleteNotifications, isTrue);
    });

    test('should have default accessibility settings', () {
      expect(service.textScaleFactor, 1.0);
      expect(service.highContrastMode, isFalse);
      expect(service.reducedMotion, isFalse);
    });
  });

  group('UserPreferencesService - Testing Methods', () {
    test('setLanguageForTesting should update language', () {
      service.setLanguageForTesting('ja-JP');
      expect(service.selectedLanguage, 'ja-JP');
    });

    test('setCategoryForTesting should update category', () {
      service.setCategoryForTesting('ethereum');
      expect(service.selectedCategory, 'ethereum');
    });

    test('setSortOrderForTesting should update sort order', () {
      service.setSortOrderForTesting('oldest');
      expect(service.sortOrder, 'oldest');
    });
  });

  group('UserPreferencesService - setLanguage', () {
    test('should update language for valid language', () async {
      await service.setLanguage('ja-JP');
      expect(service.selectedLanguage, 'ja-JP');
    });

    test('should not update language for invalid language', () async {
      final originalLanguage = service.selectedLanguage;
      await service.setLanguage('invalid-lang');
      expect(service.selectedLanguage, originalLanguage);
    });

    test('should not update when value is same', () async {
      final language = service.selectedLanguage;
      await service.setLanguage(language);
      expect(service.selectedLanguage, language);
    });
  });

  group('UserPreferencesService - setCategory', () {
    test('should update category for valid category', () async {
      await service.setCategory('ethereum');
      expect(service.selectedCategory, 'ethereum');
    });

    test('should update category to all', () async {
      await service.setCategory('all');
      expect(service.selectedCategory, 'all');
    });

    test('should not update category for invalid category', () async {
      await service.setCategory('invalid-category');
      expect(service.selectedCategory, isNot('invalid-category'));
    });
  });

  group('UserPreferencesService - setSearchQuery', () {
    test('should update search query', () {
      service.setSearchQuery('bitcoin');
      expect(service.searchQuery, 'bitcoin');
    });

    test('should update to empty query', () {
      service.setSearchQuery('bitcoin');
      service.setSearchQuery('');
      expect(service.searchQuery, '');
    });
  });

  group('UserPreferencesService - setSortOrder', () {
    test('should update to newest', () async {
      await service.setSortOrder('newest');
      expect(service.sortOrder, 'newest');
    });

    test('should update to oldest', () async {
      await service.setSortOrder('oldest');
      expect(service.sortOrder, 'oldest');
    });

    test('should update to alphabetical', () async {
      await service.setSortOrder('alphabetical');
      expect(service.sortOrder, 'alphabetical');
    });

    test('should not update for invalid sort order', () async {
      await service.setSortOrder('invalid');
      expect(service.sortOrder, isNot('invalid'));
    });
  });

  group('UserPreferencesService - Theme Settings', () {
    test('setDarkMode should update dark mode', () async {
      await service.setDarkMode(false);
      expect(service.isDarkMode, isFalse);

      await service.setDarkMode(true);
      expect(service.isDarkMode, isTrue);
    });
  });

  group('UserPreferencesService - Playback Settings', () {
    test('setPlaybackSpeed should update within valid range', () async {
      await service.setPlaybackSpeed(1.5);
      expect(service.playbackSpeed, 1.5);

      await service.setPlaybackSpeed(2.0);
      expect(service.playbackSpeed, 2.0);
    });

    test('setPlaybackSpeed should reject values below 0.5', () async {
      await service.setPlaybackSpeed(1.0);
      await service.setPlaybackSpeed(0.3);
      expect(service.playbackSpeed, 1.0); // Should not change
    });

    test('setPlaybackSpeed should reject values above 3.0', () async {
      await service.setPlaybackSpeed(1.0);
      await service.setPlaybackSpeed(3.5);
      expect(service.playbackSpeed, 1.0); // Should not change
    });

    test('setAutoplayEnabled should update autoplay', () async {
      await service.setAutoplayEnabled(false);
      expect(service.autoplayEnabled, isFalse);
    });
  });

  group('UserPreferencesService - Download Settings', () {
    test('setDownloadOverWifiOnly should update', () async {
      await service.setDownloadOverWifiOnly(false);
      expect(service.downloadOverWifiOnly, isFalse);
    });

    test('setCacheSize should update within valid range', () async {
      await service.setCacheSize(200);
      expect(service.cacheSize, 200);
    });

    test('setCacheSize should reject values below 10', () async {
      await service.setCacheSize(5);
      expect(service.cacheSize, isNot(5));
    });

    test('setCacheSize should reject values above 500', () async {
      await service.setCacheSize(600);
      expect(service.cacheSize, isNot(600));
    });
  });

  group('UserPreferencesService - Notification Settings', () {
    test('setNotificationsEnabled should update', () async {
      await service.setNotificationsEnabled(false);
      expect(service.notificationsEnabled, isFalse);
    });

    test('setNewEpisodeNotifications should update', () async {
      await service.setNewEpisodeNotifications(false);
      expect(service.newEpisodeNotifications, isFalse);
    });

    test('setDownloadCompleteNotifications should update', () async {
      await service.setDownloadCompleteNotifications(false);
      expect(service.downloadCompleteNotifications, isFalse);
    });
  });

  group('UserPreferencesService - Accessibility Settings', () {
    test('setTextScaleFactor should update within valid range', () async {
      await service.setTextScaleFactor(1.5);
      expect(service.textScaleFactor, 1.5);
    });

    test('setTextScaleFactor should reject values below 0.8', () async {
      await service.setTextScaleFactor(1.0);
      await service.setTextScaleFactor(0.5);
      expect(service.textScaleFactor, 1.0);
    });

    test('setTextScaleFactor should reject values above 2.0', () async {
      await service.setTextScaleFactor(1.0);
      await service.setTextScaleFactor(2.5);
      expect(service.textScaleFactor, 1.0);
    });

    test('setHighContrastMode should update', () async {
      await service.setHighContrastMode(true);
      expect(service.highContrastMode, isTrue);
    });

    test('setReducedMotion should update', () async {
      await service.setReducedMotion(true);
      expect(service.reducedMotion, isTrue);
    });
  });

  group('UserPreferencesService - Reset', () {
    test('resetToDefaults should reset all settings', () async {
      // Change various settings
      await service.setLanguage('ja-JP');
      await service.setCategory('ethereum');
      await service.setSortOrder('oldest');
      await service.setDarkMode(false);
      await service.setPlaybackSpeed(1.5);
      await service.setHighContrastMode(true);

      // Reset
      await service.resetToDefaults();

      // Verify defaults restored
      expect(service.selectedLanguage, ApiConfig.defaultLanguage);
      expect(service.selectedCategory, 'all');
      expect(service.sortOrder, 'newest');
      expect(service.isDarkMode, isTrue);
      expect(service.playbackSpeed, 1.0);
      expect(service.highContrastMode, isFalse);
    });
  });

  group('UserPreferencesService - Export/Import', () {
    test('exportPreferences should return all settings', () {
      service.setLanguageForTesting('ja-JP');
      service.setCategoryForTesting('ethereum');

      final exported = service.exportPreferences();

      expect(exported['selectedLanguage'], 'ja-JP');
      expect(exported['selectedCategory'], 'ethereum');
      expect(exported.containsKey('isDarkMode'), isTrue);
      expect(exported.containsKey('playbackSpeed'), isTrue);
      expect(exported.containsKey('notificationsEnabled'), isTrue);
    });

    test('importPreferences should update all settings', () async {
      final preferences = {
        'selectedLanguage': 'zh-TW',
        'selectedCategory': 'macro',
        'sortOrder': 'oldest',
        'isDarkMode': false,
        'playbackSpeed': 2.0,
        'autoplayEnabled': false,
        'cacheSize': 50,
        'textScaleFactor': 1.2,
        'highContrastMode': true,
      };

      await service.importPreferences(preferences);

      expect(service.selectedLanguage, 'zh-TW');
      expect(service.selectedCategory, 'macro');
      expect(service.sortOrder, 'oldest');
      expect(service.isDarkMode, isFalse);
      expect(service.playbackSpeed, 2.0);
      expect(service.autoplayEnabled, isFalse);
      expect(service.cacheSize, 50);
      expect(service.textScaleFactor, 1.2);
      expect(service.highContrastMode, isTrue);
    });

    test('importPreferences should handle missing values with defaults',
        () async {
      await service.importPreferences({});

      expect(service.selectedLanguage, ApiConfig.defaultLanguage);
      expect(service.selectedCategory, 'all');
    });
  });

  group('UserPreferencesService - Initialize', () {
    test('initialize should load preferences without error', () async {
      await service.initialize();
      // Should not throw
    });
  });

  group('UserPreferencesService - Dispose', () {
    test('dispose should prevent further updates', () async {
      service.dispose();

      // These should not throw but should be no-ops
      await service.setLanguage('ja-JP');
      await service.setCategory('ethereum');
    });

    test('multiple dispose calls should be safe', () {
      service.dispose();
      service.dispose();
      service.dispose();
      // Should not throw
    });
  });

  group('UserPreferencesService - ChangeNotifier', () {
    test('should notify listeners on language change', () async {
      int notifyCount = 0;
      service.addListener(() => notifyCount++);

      await service.setLanguage('ja-JP');

      expect(notifyCount, greaterThanOrEqualTo(1));
    });

    test('should notify listeners on category change', () async {
      int notifyCount = 0;
      service.addListener(() => notifyCount++);

      await service.setCategory('ethereum');

      expect(notifyCount, greaterThanOrEqualTo(1));
    });

    test('should notify listeners on search query change', () {
      int notifyCount = 0;
      service.addListener(() => notifyCount++);

      service.setSearchQuery('test');

      expect(notifyCount, greaterThanOrEqualTo(1));
    });
  });
}

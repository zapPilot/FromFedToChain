import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:from_fed_to_chain_app/core/config/api_config.dart';
import 'package:from_fed_to_chain_app/features/content/data/preferences_repository.dart';

/// Service for managing user preferences and settings
/// Handles language, category, sort order, and other user-specific settings
class UserPreferencesService extends ChangeNotifier
    implements PreferencesRepository {
  String _selectedLanguage = ApiConfig.defaultLanguage;
  String _selectedCategory = 'all';
  String _searchQuery = '';
  String _sortOrder = 'newest'; // 'newest', 'oldest', 'alphabetical'

  bool _disposed = false;

  // Theme and UI preferences
  bool _isDarkMode = true;
  double _playbackSpeed = 1.0;
  bool _autoplayEnabled = true;
  bool _downloadOverWifiOnly = true;
  int _cacheSize = 100; // Maximum cached episodes

  // Notification preferences
  bool _notificationsEnabled = true;
  bool _newEpisodeNotifications = true;
  bool _downloadCompleteNotifications = true;

  // Accessibility preferences
  double _textScaleFactor = 1.0;
  bool _highContrastMode = false;
  bool _reducedMotion = false;

  // Getters
  String get selectedLanguage => _selectedLanguage;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  String get sortOrder => _sortOrder;
  bool get isDarkMode => _isDarkMode;
  double get playbackSpeed => _playbackSpeed;
  bool get autoplayEnabled => _autoplayEnabled;
  bool get downloadOverWifiOnly => _downloadOverWifiOnly;
  int get cacheSize => _cacheSize;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get newEpisodeNotifications => _newEpisodeNotifications;
  bool get downloadCompleteNotifications => _downloadCompleteNotifications;
  double get textScaleFactor => _textScaleFactor;
  bool get highContrastMode => _highContrastMode;
  bool get reducedMotion => _reducedMotion;

  /// Initialize and load user preferences
  Future<void> initialize() async {
    if (_disposed) return;
    await _loadPreferences();
  }

  /// Load user preferences from SharedPreferences
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Core content preferences
      _selectedLanguage =
          prefs.getString('selected_language') ?? ApiConfig.defaultLanguage;
      _selectedCategory = prefs.getString('selected_category') ?? 'all';
      _sortOrder = prefs.getString('sort_order') ?? 'newest';

      // Theme and UI preferences
      _isDarkMode = prefs.getBool('is_dark_mode') ?? true;
      _playbackSpeed = prefs.getDouble('playback_speed') ?? 1.0;
      _autoplayEnabled = prefs.getBool('autoplay_enabled') ?? true;
      _downloadOverWifiOnly = prefs.getBool('download_over_wifi_only') ?? true;
      _cacheSize = prefs.getInt('cache_size') ?? 100;

      // Notification preferences
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _newEpisodeNotifications =
          prefs.getBool('new_episode_notifications') ?? true;
      _downloadCompleteNotifications =
          prefs.getBool('download_complete_notifications') ?? true;

      // Accessibility preferences
      _textScaleFactor = prefs.getDouble('text_scale_factor') ?? 1.0;
      _highContrastMode = prefs.getBool('high_contrast_mode') ?? false;
      _reducedMotion = prefs.getBool('reduced_motion') ?? false;

      // Validate loaded language (reset 'all' to default language)
      if (!ApiConfig.isValidLanguage(_selectedLanguage) ||
          _selectedLanguage == 'all') {
        _selectedLanguage = ApiConfig.defaultLanguage;
      }

      // Validate category
      if (_selectedCategory != 'all' &&
          !ApiConfig.isValidCategory(_selectedCategory)) {
        _selectedCategory = 'all';
      }

      // Validate sort order
      if (!['newest', 'oldest', 'alphabetical'].contains(_sortOrder)) {
        _sortOrder = 'newest';
      }

      // Validate playback speed
      if (_playbackSpeed < 0.5 || _playbackSpeed > 3.0) {
        _playbackSpeed = 1.0;
      }

      // Validate text scale factor
      if (_textScaleFactor < 0.8 || _textScaleFactor > 2.0) {
        _textScaleFactor = 1.0;
      }

      // Validate cache size
      if (_cacheSize < 10 || _cacheSize > 500) {
        _cacheSize = 100;
      }

      notifyListeners();

      if (kDebugMode) {
        print('UserPreferencesService: Loaded preferences successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('UserPreferencesService: Failed to load preferences: $e');
      }
    }
  }

  /// Save user preferences to SharedPreferences
  Future<void> _savePreferences() async {
    if (_disposed) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Core content preferences
      await prefs.setString('selected_language', _selectedLanguage);
      await prefs.setString('selected_category', _selectedCategory);
      await prefs.setString('sort_order', _sortOrder);

      // Theme and UI preferences
      await prefs.setBool('is_dark_mode', _isDarkMode);
      await prefs.setDouble('playback_speed', _playbackSpeed);
      await prefs.setBool('autoplay_enabled', _autoplayEnabled);
      await prefs.setBool('download_over_wifi_only', _downloadOverWifiOnly);
      await prefs.setInt('cache_size', _cacheSize);

      // Notification preferences
      await prefs.setBool('notifications_enabled', _notificationsEnabled);
      await prefs.setBool(
          'new_episode_notifications', _newEpisodeNotifications);
      await prefs.setBool(
          'download_complete_notifications', _downloadCompleteNotifications);

      // Accessibility preferences
      await prefs.setDouble('text_scale_factor', _textScaleFactor);
      await prefs.setBool('high_contrast_mode', _highContrastMode);
      await prefs.setBool('reduced_motion', _reducedMotion);

      if (kDebugMode) {
        print('UserPreferencesService: Saved preferences successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('UserPreferencesService: Failed to save preferences: $e');
      }
    }
  }

  /// Set selected language filter
  @override
  Future<void> setLanguage(String language) async {
    if (_disposed) return;

    if (!ApiConfig.isValidLanguage(language)) {
      if (kDebugMode) {
        print('UserPreferencesService: Unsupported language: $language');
      }
      return;
    }

    if (_selectedLanguage != language) {
      _selectedLanguage = language;
      await _savePreferences();

      if (!_disposed) {
        notifyListeners();
      }

      if (kDebugMode) {
        print('UserPreferencesService: Language changed to $language');
      }
    }
  }

  /// Set selected category filter
  @override
  Future<void> setCategory(String category) async {
    if (_disposed) return;

    if (category != 'all' && !ApiConfig.isValidCategory(category)) {
      if (kDebugMode) {
        print('UserPreferencesService: Unsupported category: $category');
      }
      return;
    }

    if (_selectedCategory != category) {
      _selectedCategory = category;
      await _savePreferences();

      if (!_disposed) {
        notifyListeners();
      }

      if (kDebugMode) {
        print('UserPreferencesService: Category changed to $category');
      }
    }
  }

  /// Set search query (not persisted)
  void setSearchQuery(String query) {
    if (_disposed) return;

    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  /// Set sort order and persist
  @override
  Future<void> setSortOrder(String sortOrder) async {
    if (_disposed) return;

    if (!['newest', 'oldest', 'alphabetical'].contains(sortOrder)) {
      if (kDebugMode) {
        print('UserPreferencesService: Invalid sort order: $sortOrder');
      }
      return;
    }

    if (_sortOrder != sortOrder) {
      _sortOrder = sortOrder;
      await _savePreferences();

      if (!_disposed) {
        notifyListeners();
      }

      if (kDebugMode) {
        print('UserPreferencesService: Sort order changed to $sortOrder');
      }
    }
  }

  /// Set theme mode
  @override
  Future<void> setDarkMode(bool isDark) async {
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      await _savePreferences();
      notifyListeners();

      if (kDebugMode) {
        print(
            'UserPreferencesService: Dark mode ${isDark ? 'enabled' : 'disabled'}');
      }
    }
  }

  /// Set playback speed
  @override
  Future<void> setPlaybackSpeed(double speed) async {
    if (speed < 0.5 || speed > 3.0) {
      if (kDebugMode) {
        print('UserPreferencesService: Invalid playback speed: $speed');
      }
      return;
    }

    if (_playbackSpeed != speed) {
      _playbackSpeed = speed;
      await _savePreferences();
      notifyListeners();

      if (kDebugMode) {
        print('UserPreferencesService: Playback speed changed to ${speed}x');
      }
    }
  }

  /// Set autoplay enabled
  @override
  Future<void> setAutoplayEnabled(bool enabled) async {
    if (_autoplayEnabled != enabled) {
      _autoplayEnabled = enabled;
      await _savePreferences();
      notifyListeners();

      if (kDebugMode) {
        print(
            'UserPreferencesService: Autoplay ${enabled ? 'enabled' : 'disabled'}');
      }
    }
  }

  /// Set download over WiFi only
  Future<void> setDownloadOverWifiOnly(bool wifiOnly) async {
    if (_downloadOverWifiOnly != wifiOnly) {
      _downloadOverWifiOnly = wifiOnly;
      await _savePreferences();
      notifyListeners();

      if (kDebugMode) {
        print(
            'UserPreferencesService: Download over WiFi only ${wifiOnly ? 'enabled' : 'disabled'}');
      }
    }
  }

  /// Set cache size
  Future<void> setCacheSize(int size) async {
    if (size < 10 || size > 500) {
      if (kDebugMode) {
        print('UserPreferencesService: Invalid cache size: $size');
      }
      return;
    }

    if (_cacheSize != size) {
      _cacheSize = size;
      await _savePreferences();
      notifyListeners();

      if (kDebugMode) {
        print('UserPreferencesService: Cache size changed to $size episodes');
      }
    }
  }

  /// Set notifications enabled
  Future<void> setNotificationsEnabled(bool enabled) async {
    if (_notificationsEnabled != enabled) {
      _notificationsEnabled = enabled;
      await _savePreferences();
      notifyListeners();

      if (kDebugMode) {
        print(
            'UserPreferencesService: Notifications ${enabled ? 'enabled' : 'disabled'}');
      }
    }
  }

  /// Set new episode notifications
  Future<void> setNewEpisodeNotifications(bool enabled) async {
    if (_newEpisodeNotifications != enabled) {
      _newEpisodeNotifications = enabled;
      await _savePreferences();
      notifyListeners();

      if (kDebugMode) {
        print(
            'UserPreferencesService: New episode notifications ${enabled ? 'enabled' : 'disabled'}');
      }
    }
  }

  /// Set download complete notifications
  Future<void> setDownloadCompleteNotifications(bool enabled) async {
    if (_downloadCompleteNotifications != enabled) {
      _downloadCompleteNotifications = enabled;
      await _savePreferences();
      notifyListeners();

      if (kDebugMode) {
        print(
            'UserPreferencesService: Download complete notifications ${enabled ? 'enabled' : 'disabled'}');
      }
    }
  }

  /// Set text scale factor
  Future<void> setTextScaleFactor(double factor) async {
    if (factor < 0.8 || factor > 2.0) {
      if (kDebugMode) {
        print('UserPreferencesService: Invalid text scale factor: $factor');
      }
      return;
    }

    if (_textScaleFactor != factor) {
      _textScaleFactor = factor;
      await _savePreferences();
      notifyListeners();

      if (kDebugMode) {
        print(
            'UserPreferencesService: Text scale factor changed to ${factor}x');
      }
    }
  }

  /// Set high contrast mode
  Future<void> setHighContrastMode(bool enabled) async {
    if (_highContrastMode != enabled) {
      _highContrastMode = enabled;
      await _savePreferences();
      notifyListeners();

      if (kDebugMode) {
        print(
            'UserPreferencesService: High contrast mode ${enabled ? 'enabled' : 'disabled'}');
      }
    }
  }

  /// Set reduced motion
  Future<void> setReducedMotion(bool enabled) async {
    if (_reducedMotion != enabled) {
      _reducedMotion = enabled;
      await _savePreferences();
      notifyListeners();

      if (kDebugMode) {
        print(
            'UserPreferencesService: Reduced motion ${enabled ? 'enabled' : 'disabled'}');
      }
    }
  }

  /// Reset all preferences to defaults
  @override
  Future<void> resetToDefaults() async {
    _selectedLanguage = ApiConfig.defaultLanguage;
    _selectedCategory = 'all';
    _searchQuery = '';
    _sortOrder = 'newest';
    _isDarkMode = true;
    _playbackSpeed = 1.0;
    _autoplayEnabled = true;
    _downloadOverWifiOnly = true;
    _cacheSize = 100;
    _notificationsEnabled = true;
    _newEpisodeNotifications = true;
    _downloadCompleteNotifications = true;
    _textScaleFactor = 1.0;
    _highContrastMode = false;
    _reducedMotion = false;

    await _savePreferences();
    notifyListeners();

    if (kDebugMode) {
      print('UserPreferencesService: Reset all preferences to defaults');
    }
  }

  /// Export preferences as Map
  @override
  Map<String, dynamic> exportPreferences() {
    return {
      'selectedLanguage': _selectedLanguage,
      'selectedCategory': _selectedCategory,
      'sortOrder': _sortOrder,
      'isDarkMode': _isDarkMode,
      'playbackSpeed': _playbackSpeed,
      'autoplayEnabled': _autoplayEnabled,
      'downloadOverWifiOnly': _downloadOverWifiOnly,
      'cacheSize': _cacheSize,
      'notificationsEnabled': _notificationsEnabled,
      'newEpisodeNotifications': _newEpisodeNotifications,
      'downloadCompleteNotifications': _downloadCompleteNotifications,
      'textScaleFactor': _textScaleFactor,
      'highContrastMode': _highContrastMode,
      'reducedMotion': _reducedMotion,
    };
  }

  /// Import preferences from Map
  @override
  Future<void> importPreferences(Map<String, dynamic> preferences) async {
    try {
      _selectedLanguage = preferences['selectedLanguage'] as String? ??
          ApiConfig.defaultLanguage;
      _selectedCategory = preferences['selectedCategory'] as String? ?? 'all';
      _sortOrder = preferences['sortOrder'] as String? ?? 'newest';
      _isDarkMode = preferences['isDarkMode'] as bool? ?? true;
      _playbackSpeed =
          (preferences['playbackSpeed'] as num?)?.toDouble() ?? 1.0;
      _autoplayEnabled = preferences['autoplayEnabled'] as bool? ?? true;
      _downloadOverWifiOnly =
          preferences['downloadOverWifiOnly'] as bool? ?? true;
      _cacheSize = preferences['cacheSize'] as int? ?? 100;
      _notificationsEnabled =
          preferences['notificationsEnabled'] as bool? ?? true;
      _newEpisodeNotifications =
          preferences['newEpisodeNotifications'] as bool? ?? true;
      _downloadCompleteNotifications =
          preferences['downloadCompleteNotifications'] as bool? ?? true;
      _textScaleFactor =
          (preferences['textScaleFactor'] as num?)?.toDouble() ?? 1.0;
      _highContrastMode = preferences['highContrastMode'] as bool? ?? false;
      _reducedMotion = preferences['reducedMotion'] as bool? ?? false;

      await _savePreferences();
      notifyListeners();

      if (kDebugMode) {
        print('UserPreferencesService: Imported preferences successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('UserPreferencesService: Failed to import preferences: $e');
      }
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    super.dispose();
  }

  // Testing methods
  @visibleForTesting
  void setLanguageForTesting(String language) {
    _selectedLanguage = language;
    notifyListeners();
  }

  @visibleForTesting
  void setCategoryForTesting(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  @visibleForTesting
  void setSortOrderForTesting(String sortOrder) {
    _sortOrder = sortOrder;
    notifyListeners();
  }
}

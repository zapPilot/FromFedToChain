import 'dart:async';

/// Abstract repository interface for user preferences data access
/// Handles persistence and retrieval of user settings and preferences
abstract class PreferencesRepository {
  /// Initialize and load preferences
  Future<void> initialize();

  /// Get selected language
  String get selectedLanguage;

  /// Get selected category
  String get selectedCategory;

  /// Get current search query
  String get searchQuery;

  /// Get sort order
  String get sortOrder;

  /// Get theme mode
  bool get isDarkMode;

  /// Get playback speed
  double get playbackSpeed;

  /// Get autoplay setting
  bool get autoplayEnabled;

  /// Get download over WiFi only setting
  bool get downloadOverWifiOnly;

  /// Get cache size setting
  int get cacheSize;

  /// Get notifications enabled
  bool get notificationsEnabled;

  /// Get new episode notifications
  bool get newEpisodeNotifications;

  /// Get download complete notifications
  bool get downloadCompleteNotifications;

  /// Get text scale factor
  double get textScaleFactor;

  /// Get high contrast mode
  bool get highContrastMode;

  /// Get reduced motion setting
  bool get reducedMotion;

  /// Set selected language
  Future<void> setLanguage(String language);

  /// Set selected category
  Future<void> setCategory(String category);

  /// Set search query (not persisted)
  void setSearchQuery(String query);

  /// Set sort order
  Future<void> setSortOrder(String sortOrder);

  /// Set theme mode
  Future<void> setDarkMode(bool isDark);

  /// Set playback speed
  Future<void> setPlaybackSpeed(double speed);

  /// Set autoplay enabled
  Future<void> setAutoplayEnabled(bool enabled);

  /// Set download over WiFi only
  Future<void> setDownloadOverWifiOnly(bool wifiOnly);

  /// Set cache size
  Future<void> setCacheSize(int size);

  /// Set notifications enabled
  Future<void> setNotificationsEnabled(bool enabled);

  /// Set new episode notifications
  Future<void> setNewEpisodeNotifications(bool enabled);

  /// Set download complete notifications
  Future<void> setDownloadCompleteNotifications(bool enabled);

  /// Set text scale factor
  Future<void> setTextScaleFactor(double factor);

  /// Set high contrast mode
  Future<void> setHighContrastMode(bool enabled);

  /// Set reduced motion
  Future<void> setReducedMotion(bool enabled);

  /// Reset all preferences to defaults
  Future<void> resetToDefaults();

  /// Export preferences as Map
  Map<String, dynamic> exportPreferences();

  /// Import preferences from Map
  Future<void> importPreferences(Map<String, dynamic> preferences);

  /// Dispose of resources
  void dispose();
}

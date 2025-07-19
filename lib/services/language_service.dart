import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  static const String _defaultLanguage = 'en-US';
  
  String? _selectedLanguage;
  bool _isInitialized = false;
  
  // Available languages in the app
  final List<Map<String, String>> availableLanguages = [
    {'code': 'zh-TW', 'name': '繁體中文', 'flag': '🇹🇼'},
    {'code': 'en-US', 'name': 'English', 'flag': '🇺🇸'},
    {'code': 'ja-JP', 'name': '日本語', 'flag': '🇯🇵'},
    {'code': 'ko-KR', 'name': '한국어', 'flag': '🇰🇷'},
    {'code': 'es-ES', 'name': 'Español', 'flag': '🇪🇸'},
    {'code': 'fr-FR', 'name': 'Français', 'flag': '🇫🇷'},
    {'code': 'de-DE', 'name': 'Deutsch', 'flag': '🇩🇪'},
  ];
  
  // Getters
  String? get selectedLanguage => _selectedLanguage;
  bool get isInitialized => _isInitialized;
  bool get hasLanguageSelected => _selectedLanguage != null;
  
  String get currentLanguage => _selectedLanguage ?? _defaultLanguage;
  
  Map<String, String>? get currentLanguageInfo {
    if (_selectedLanguage == null) return null;
    return availableLanguages.firstWhere(
      (lang) => lang['code'] == _selectedLanguage,
      orElse: () => availableLanguages.first,
    );
  }
  
  /// Initialize the language service by loading saved preference
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey);
      
      if (savedLanguage != null && _isValidLanguage(savedLanguage)) {
        _selectedLanguage = savedLanguage;
        if (kDebugMode) {
          print('🌐 LanguageService: Loaded saved language: $savedLanguage');
        }
      } else {
        if (kDebugMode) {
          print('🌐 LanguageService: No saved language, using default: $_defaultLanguage');
        }
      }
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ LanguageService: Error initializing: $e');
      }
      _isInitialized = true;
      notifyListeners();
    }
  }
  
  /// Set the selected language and persist it
  Future<void> setLanguage(String languageCode) async {
    if (!_isValidLanguage(languageCode)) {
      throw ArgumentError('Invalid language code: $languageCode');
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      
      _selectedLanguage = languageCode;
      notifyListeners();
      
      if (kDebugMode) {
        print('🌐 LanguageService: Language set to: $languageCode');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ LanguageService: Error setting language: $e');
      }
      rethrow;
    }
  }
  
  /// Clear the selected language (for testing purposes)
  Future<void> clearLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_languageKey);
      
      _selectedLanguage = null;
      notifyListeners();
      
      if (kDebugMode) {
        print('🌐 LanguageService: Language preference cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ LanguageService: Error clearing language: $e');
      }
      rethrow;
    }
  }
  
  /// Check if a language code is valid
  bool _isValidLanguage(String languageCode) {
    return availableLanguages.any((lang) => lang['code'] == languageCode);
  }
  
  /// Get display name for a language code
  String getLanguageDisplayName(String languageCode) {
    final language = availableLanguages.firstWhere(
      (lang) => lang['code'] == languageCode,
      orElse: () => {'name': languageCode},
    );
    return language['name'] ?? languageCode;
  }
  
  /// Get flag emoji for a language code
  String getLanguageFlag(String languageCode) {
    final language = availableLanguages.firstWhere(
      (lang) => lang['code'] == languageCode,
      orElse: () => {'flag': '🌐'},
    );
    return language['flag'] ?? '🌐';
  }
  
  /// Check if first time opening the app (no language selected)
  bool get isFirstLaunch => !hasLanguageSelected && _isInitialized;
}
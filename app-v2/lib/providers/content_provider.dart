import 'package:flutter/foundation.dart';
import '../models/audio_content.dart';
import '../services/content_service.dart';
import '../config/app_config.dart';

/// Sort order options
enum SortOrder {
  newest,
  oldest,
}

/// Content provider managing language, category, search, and sort state
/// Replaces ContentFacadeService from v1
class ContentProvider with ChangeNotifier {
  final ContentService _contentService;

  // State
  String _selectedLanguage = AppConfig.defaultLanguage;
  String _selectedCategory = AppConfig.allCategoriesKey;
  SortOrder _sortOrder = SortOrder.newest;
  String _searchQuery = '';
  List<AudioContent> _content = [];
  bool _isLoading = false;
  String? _errorMessage;

  ContentProvider(this._contentService);

  // Getters
  String get selectedLanguage => _selectedLanguage;
  String get selectedCategory => _selectedCategory;
  SortOrder get sortOrder => _sortOrder;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Get filtered and sorted content
  List<AudioContent> get content {
    var filtered = List<AudioContent>.from(_content);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((c) {
        return c.title.toLowerCase().contains(query) ||
            (c.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Apply sort
    filtered.sort((a, b) {
      final comparison = a.date.compareTo(b.date);
      return _sortOrder == SortOrder.newest ? -comparison : comparison;
    });

    return filtered;
  }

  /// Load content for currently selected language and category
  Future<void> loadContent() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final category = _selectedCategory == AppConfig.allCategoriesKey
          ? null
          : _selectedCategory;

      _content = await _contentService.loadContent(
        language: _selectedLanguage,
        category: category,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set selected language and reload content
  Future<void> setLanguage(String language) async {
    if (_selectedLanguage != language &&
        AppConfig.isValidLanguage(language)) {
      _selectedLanguage = language;
      _searchQuery = ''; // Clear search when switching language
      await loadContent();
    }
  }

  /// Set selected category and reload content
  Future<void> setCategory(String category) async {
    if (_selectedCategory != category && AppConfig.isValidCategory(category)) {
      _selectedCategory = category;
      await loadContent();
    }
  }

  /// Set sort order
  void setSortOrder(SortOrder order) {
    if (_sortOrder != order) {
      _sortOrder = order;
      notifyListeners();
    }
  }

  /// Set search query
  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  /// Clear search query
  void clearSearch() {
    setSearchQuery('');
  }

  /// Refresh content (clear cache and reload)
  Future<void> refresh() async {
    _contentService.clearCache();
    await loadContent();
  }

  /// Get next episode in the current filtered list
  AudioContent? getNextEpisode(AudioContent current) {
    final currentList = content;
    final index = currentList.indexWhere((c) => c.id == current.id);

    if (index >= 0 && index < currentList.length - 1) {
      return currentList[index + 1];
    }

    return null;
  }

  /// Get previous episode in the current filtered list
  AudioContent? getPreviousEpisode(AudioContent current) {
    final currentList = content;
    final index = currentList.indexWhere((c) => c.id == current.id);

    if (index > 0) {
      return currentList[index - 1];
    }

    return null;
  }

  @override
  void dispose() {
    _contentService.dispose();
    super.dispose();
  }
}

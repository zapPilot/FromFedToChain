import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:from_fed_to_chain_app/core/services/logger_service.dart';

import 'package:from_fed_to_chain_app/core/config/api_config.dart';
import 'package:from_fed_to_chain_app/features/content/data/cache_service.dart';
import 'package:from_fed_to_chain_app/features/content/data/content_repository.dart';
import 'package:from_fed_to_chain_app/features/content/data/episode_repository.dart';
import 'package:from_fed_to_chain_app/features/content/data/episode_repository_impl.dart';
import 'package:from_fed_to_chain_app/features/content/data/preferences_repository.dart';
import 'package:from_fed_to_chain_app/features/content/data/progress_repository.dart';
import 'package:from_fed_to_chain_app/features/content/data/progress_tracking_service.dart';
import 'package:from_fed_to_chain_app/features/content/data/streaming_api_service.dart';
import 'package:from_fed_to_chain_app/features/content/data/user_preferences_service.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_content.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';

/// Primary content domain service for episodes, filters, and playlists.
///
/// This replaces the previous facade + factory layering and keeps
/// state, filtering, and playlist management in one place.
class ContentService extends ChangeNotifier {
  final EpisodeRepository _episodeRepository;
  final ContentRepository _contentRepository;
  final ProgressRepository _progressRepository;
  final PreferencesRepository _preferencesRepository;
  static final _log = LoggerService.getLogger('ContentService');

  // State
  List<AudioFile> _allEpisodes = [];
  List<AudioFile> _filteredEpisodes = [];

  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;

  // Search cache
  final Map<String, List<AudioFile>> _searchCache = {};
  final int _maxSearchCacheSize = 20;

  ContentService({
    EpisodeRepository? episodeRepository,
    ContentRepository? contentRepository,
    ProgressRepository? progressRepository,
    PreferencesRepository? preferencesRepository,
  })  : _episodeRepository = episodeRepository ?? EpisodeRepositoryImpl(),
        _contentRepository = contentRepository ?? CacheService(),
        _progressRepository = progressRepository ?? ProgressTrackingService(),
        _preferencesRepository =
            preferencesRepository ?? UserPreferencesService() {
    _initializeServices();
  }

  void _initializeServices() {
    _progressRepository.initialize();
    _preferencesRepository.initialize();
    _log.info('Initialized content dependencies');
  }

  // Getters
  List<AudioFile> get allEpisodes => _allEpisodes;
  List<AudioFile> get filteredEpisodes => _filteredEpisodes;

  String get selectedLanguage => _preferencesRepository.selectedLanguage;
  String get selectedCategory => _preferencesRepository.selectedCategory;
  String get searchQuery => _preferencesRepository.searchQuery;
  String get sortOrder => _preferencesRepository.sortOrder;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get hasEpisodes => _allEpisodes.isNotEmpty;
  bool get hasFilteredResults => _filteredEpisodes.isNotEmpty;

  // Listen history methods
  List<AudioFile> getListenHistoryEpisodes({int limit = 50}) {
    return _progressRepository.getListenHistoryEpisodes(allEpisodes,
        limit: limit);
  }

  Map<String, DateTime> get listenHistory => _progressRepository.listenHistory;

  bool isEpisodeFinished(String episodeId) =>
      _progressRepository.isEpisodeFinished(episodeId);

  bool isEpisodeUnfinished(String episodeId) =>
      _progressRepository.isEpisodeUnfinished(episodeId);

  Future<void> addToListenHistory(AudioFile episode, {DateTime? at}) async {
    await _progressRepository.addToListenHistory(episode, at: at);
    notifyListeners();
  }

  Future<void> removeFromListenHistory(String episodeId) async {
    await _progressRepository.removeFromListenHistory(episodeId);
    notifyListeners();
  }

  Future<void> clearListenHistory() async {
    await _progressRepository.clearListenHistory();
    notifyListeners();
  }

  // Content methods
  Future<AudioContent?> fetchContentById(
      String id, String language, String category) async {
    return await _contentRepository.fetchContentById(id, language, category);
  }

  Future<AudioContent?> getContentForAudioFile(AudioFile audioFile) async {
    return await _contentRepository.getContentForAudioFile(audioFile);
  }

  Future<AudioFile?> getAudioFileById(String contentId) async {
    // Search for the audio file by ID in the loaded episodes
    try {
      // First try exact match
      return allEpisodes.firstWhere((episode) => episode.id == contentId);
    } catch (_) {
      // If exact match fails, try date pattern matching
      try {
        // Extract date pattern from contentId (YYYY-MM-DD)
        final dateRegex = RegExp(r'(\d{4}-\d{2}-\d{2})');
        final match = dateRegex.firstMatch(contentId);

        if (match != null) {
          final dateStr = match.group(1)!;
          final searchDate = DateTime.parse(dateStr);

          // Find episode with matching date (either in ID or lastModified)
          return allEpisodes.firstWhere((episode) {
            if (episode.id.contains(dateStr)) {
              return true;
            }

            final episodeDate = episode.publishDate;
            return episodeDate.year == searchDate.year &&
                episodeDate.month == searchDate.month &&
                episodeDate.day == searchDate.day;
          });
        }
      } catch (_) {
        // Ignore and fall through
      }

      return null;
    }
  }

  Future<void> prefetchContent(List<AudioFile> audioFiles) async {
    await _contentRepository.prefetchContent(audioFiles);
  }

  void clearContentCache() {
    _contentRepository.clearContentCache();
  }

  // Progress tracking methods
  Future<void> updateEpisodeCompletion(
      String episodeId, double completion) async {
    await _progressRepository.updateEpisodeCompletion(episodeId, completion);
    notifyListeners();
  }

  Future<void> markEpisodeAsFinished(String episodeId) async {
    await _progressRepository.markEpisodeAsFinished(episodeId);
    notifyListeners();
  }

  double getEpisodeCompletion(String episodeId) {
    return _progressRepository.getEpisodeCompletion(episodeId);
  }

  List<AudioFile> getUnfinishedEpisodes() {
    return _progressRepository.getUnfinishedEpisodes(allEpisodes);
  }

  // Preferences methods
  Future<void> setSortOrder(String sortOrder) async {
    await _preferencesRepository.setSortOrder(sortOrder);
    _applyCurrentFilters();
    notifyListeners();
  }

  // Episode loading methods
  Future<void> loadAllEpisodes() async {
    _setLoading(true);
    _clearError();

    try {
      final episodes = await _episodeRepository.loadAllEpisodes();
      _allEpisodes = episodes;
      _applyCurrentFilters();

      _log.info('Loaded ${episodes.length} episodes');
    } catch (e) {
      _setError('Failed to load episodes: $e');
      _log.severe('Error loading episodes: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadEpisodesForLanguage(String language) async {
    _setLoading(true);
    _clearError();

    try {
      final episodes =
          await _episodeRepository.loadEpisodesForLanguage(language);
      _allEpisodes = episodes;
      _applyCurrentFilters();

      _log.info('Loaded ${episodes.length} episodes for $language');
    } catch (e) {
      _setError('Failed to load episodes for $language: $e');
      _log.severe('Error loading episodes for $language: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> setLanguage(String language) async {
    if (!ApiConfig.isValidLanguage(language)) {
      _errorMessage = 'Unsupported language: $language';
      notifyListeners();
      return;
    }

    _clearError();
    await _preferencesRepository.setLanguage(language);
    await loadEpisodesForLanguage(language);
    notifyListeners();
  }

  Future<void> setCategory(String category) async {
    if (category != 'all' && !ApiConfig.isValidCategory(category)) {
      _errorMessage = 'Unsupported category: $category';
      notifyListeners();
      return;
    }

    _clearError();
    await _preferencesRepository.setCategory(category);
    _applyCurrentFilters();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    if (_disposed) return;

    _preferencesRepository.setSearchQuery(query);
    _applyCurrentFilters();
    notifyListeners();
  }

  // Data access methods
  List<AudioFile> getEpisodesByLanguage(String language) {
    return _filterByLanguage(_allEpisodes, language);
  }

  List<AudioFile> getEpisodesByCategory(String category) {
    return _filterByCategory(_allEpisodes, category);
  }

  List<AudioFile> getEpisodesByLanguageAndCategory(
      String language, String category) {
    return advancedSearch(
      _allEpisodes,
      languages: [language],
      categories: [category],
    );
  }

  // Statistics and utility methods
  Map<String, dynamic> getStatistics() {
    return {
      'totalEpisodes': allEpisodes.length,
      'filteredEpisodes': filteredEpisodes.length,
      'selectedLanguage': selectedLanguage,
      'selectedCategory': selectedCategory,
      'searchQuery': searchQuery,
      'listeningStats': _progressRepository.getListeningStatistics(allEpisodes),
      'cacheStats': _contentRepository.getCacheStatistics(),
    };
  }

  Future<void> refresh() async {
    await loadAllEpisodes();
  }

  void clear() {
    _allEpisodes.clear();
    _filteredEpisodes.clear();
    _searchCache.clear();

    _contentRepository.clearContentCache();
    _clearError();
    notifyListeners();
  }

  Future<List<AudioFile>> searchEpisodes(String query) async {
    return _searchEpisodes(query, _allEpisodes);
  }

  Map<String, dynamic> getDebugInfo(AudioFile? audioFile) {
    if (audioFile == null) {
      return {'error': 'No audio file provided'};
    }

    return {
      'id': audioFile.id,
      'title': audioFile.title,
      'language': audioFile.language,
      'category': audioFile.category,
      'streamingUrl': audioFile.streamingUrl,
      'totalEpisodes': allEpisodes.length,
      'filteredEpisodes': filteredEpisodes.length,
      'selectedLanguage': selectedLanguage,
      'selectedCategory': selectedCategory,
      'isLoading': isLoading,
      'hasError': hasError,
      'content_service': 'ContentService',
      'episode_count': allEpisodes.length,
      'filtered_count': filteredEpisodes.length,
      'search_query': searchQuery,
      'error_message': errorMessage,
      'audio_file': audioFile.toJson(),
    };
  }

  Future<void> setEpisodeCompletion(String episodeId, double completion) async {
    await updateEpisodeCompletion(episodeId, completion);
  }

  void cacheContent(
      String id, String language, String category, AudioContent content) {
    _contentRepository.cacheContent(id, language, category, content);
  }

  AudioContent? getCachedContent(String id, String language, String category) {
    return _contentRepository.getCachedContent(id, language, category);
  }

  List<AudioFile> getFilteredEpisodes() => filteredEpisodes;

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Apply current filters
  void _applyCurrentFilters() {
    _filteredEpisodes = _applyFilters(
      _allEpisodes,
      selectedLanguage: selectedLanguage,
      selectedCategory: selectedCategory,
      searchQuery: searchQuery,
      sortOrder: _preferencesRepository.sortOrder,
    );
  }

  List<AudioFile> _applyFilters(
    List<AudioFile> allEpisodes, {
    required String selectedLanguage,
    required String selectedCategory,
    required String searchQuery,
    required String sortOrder,
  }) {
    var filtered = List<AudioFile>.from(allEpisodes);

    filtered = _filterByLanguage(filtered, selectedLanguage);

    if (selectedCategory != 'all') {
      filtered = _filterByCategory(filtered, selectedCategory);
    }

    if (searchQuery.trim().isNotEmpty) {
      filtered = _filterBySearchQuery(filtered, searchQuery);
    }

    filtered = _applySorting(filtered, sortOrder);

    return filtered;
  }

  List<AudioFile> _filterByLanguage(List<AudioFile> episodes, String language) {
    if (language == 'all') {
      return episodes;
    }
    return episodes.where((episode) => episode.language == language).toList();
  }

  List<AudioFile> _filterByCategory(List<AudioFile> episodes, String category) {
    return episodes.where((episode) => episode.category == category).toList();
  }

  List<AudioFile> _filterBySearchQuery(List<AudioFile> episodes, String query) {
    if (query.trim().isEmpty) return episodes;

    final lowerQuery = query.toLowerCase();
    return episodes.where((episode) {
      return episode.title.toLowerCase().contains(lowerQuery) ||
          episode.id.toLowerCase().contains(lowerQuery) ||
          episode.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  List<AudioFile> _applySorting(List<AudioFile> episodes, String sortOrder) {
    final sortedEpisodes = List<AudioFile>.from(episodes);

    switch (sortOrder) {
      case 'oldest':
        sortedEpisodes.sort((a, b) => a.publishDate.compareTo(b.publishDate));
        break;
      case 'alphabetical':
        sortedEpisodes.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case 'newest':
      default:
        sortedEpisodes.sort((a, b) => b.publishDate.compareTo(a.publishDate));
        break;
    }

    return sortedEpisodes;
  }

  Future<List<AudioFile>> _searchEpisodes(
    String query,
    List<AudioFile> localEpisodes,
  ) async {
    if (query.trim().isEmpty) {
      return localEpisodes;
    }

    final cacheKey = query.toLowerCase().trim();
    if (_searchCache.containsKey(cacheKey)) {
      _log.fine('Returning cached results for "$query"');
      return _searchCache[cacheKey]!;
    }

    try {
      final localResults = _filterBySearchQuery(localEpisodes, query);

      if (localResults.isNotEmpty) {
        _cacheSearchResult(cacheKey, localResults);
        return localResults;
      }

      _log.fine('Searching API for "$query"');
      final apiResults = await StreamingApiService.searchEpisodes(query);
      _cacheSearchResult(cacheKey, apiResults);

      return apiResults;
    } catch (e) {
      _log.warning('Search failed for "$query": $e');
      return [];
    }
  }

  void _cacheSearchResult(String cacheKey, List<AudioFile> results) {
    if (_searchCache.length >= _maxSearchCacheSize) {
      final firstKey = _searchCache.keys.first;
      _searchCache.remove(firstKey);
    }
    _searchCache[cacheKey] = results;
  }

  List<AudioFile> advancedSearch(
    List<AudioFile> episodes, {
    String? query,
    List<String>? languages,
    List<String>? categories,
    DateTime? dateFrom,
    DateTime? dateTo,
    Duration? minDuration,
    Duration? maxDuration,
    String sortOrder = 'newest',
  }) {
    var results = List<AudioFile>.from(episodes);

    if (query != null && query.trim().isNotEmpty) {
      results = _filterBySearchQuery(results, query);
    }

    if (languages != null && languages.isNotEmpty) {
      results = results
          .where((episode) => languages.contains(episode.language))
          .toList();
    }

    if (categories != null && categories.isNotEmpty) {
      results = results
          .where((episode) => categories.contains(episode.category))
          .toList();
    }

    if (dateFrom != null) {
      results = results
          .where((episode) =>
              episode.publishDate.isAfter(dateFrom) ||
              episode.publishDate.isAtSameMomentAs(dateFrom))
          .toList();
    }
    if (dateTo != null) {
      results = results
          .where((episode) =>
              episode.publishDate.isBefore(dateTo.add(const Duration(days: 1))))
          .toList();
    }

    if (minDuration != null) {
      results = results
          .where((episode) =>
              episode.duration != null && episode.duration! >= minDuration)
          .toList();
    }
    if (maxDuration != null) {
      results = results
          .where((episode) =>
              episode.duration != null && episode.duration! <= maxDuration)
          .toList();
    }

    results = _applySorting(results, sortOrder);

    return results;
  }

  // Testing methods
  @visibleForTesting
  void setEpisodesForTesting(List<AudioFile> episodes) {
    _allEpisodes = episodes;
    _applyCurrentFilters();
    notifyListeners();
  }

  @visibleForTesting
  void setLoadingForTesting(bool loading) {
    _setLoading(loading);
  }

  @visibleForTesting
  void setErrorForTesting(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  @visibleForTesting
  void setSelectedLanguage(String language) {
    _preferencesRepository.setLanguage(language);
    _applyCurrentFilters();
    notifyListeners();
  }

  @visibleForTesting
  void setSelectedCategory(String category) {
    _preferencesRepository.setCategory(category);
    _applyCurrentFilters();
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    _contentRepository.dispose();
    _progressRepository.dispose();
    _preferencesRepository.dispose();
    super.dispose();
  }
}

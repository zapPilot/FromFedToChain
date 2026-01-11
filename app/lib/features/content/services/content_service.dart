import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:from_fed_to_chain_app/core/services/logger_service.dart';

import 'package:from_fed_to_chain_app/core/config/api_config.dart';
import 'package:from_fed_to_chain_app/features/content/data/cache_service.dart';
import 'package:from_fed_to_chain_app/features/content/data/content_repository.dart';
import 'package:from_fed_to_chain_app/features/content/data/preferences_repository.dart';
import 'package:from_fed_to_chain_app/features/content/data/progress_repository.dart';
import 'package:from_fed_to_chain_app/features/content/data/progress_tracking_service.dart';
import 'package:from_fed_to_chain_app/features/content/data/user_preferences_service.dart';
import 'package:from_fed_to_chain_app/core/di/service_locator.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_content.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/features/content/domain/use_cases/use_cases.dart';

/// Primary content domain service for episodes, filters, and playlists.
///
/// This replaces the previous facade + factory layering and keeps
/// state, filtering, and playlist management in one place.
class ContentService extends ChangeNotifier {
  final LoadEpisodesUseCase _loadEpisodesUseCase;
  final FilterEpisodesUseCase _filterEpisodesUseCase;
  final SearchEpisodesUseCase _searchEpisodesUseCase;

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

  ContentService({
    LoadEpisodesUseCase? loadEpisodesUseCase,
    FilterEpisodesUseCase? filterEpisodesUseCase,
    SearchEpisodesUseCase? searchEpisodesUseCase,
    ContentRepository? contentRepository,
    ProgressRepository? progressRepository,
    PreferencesRepository? preferencesRepository,
  })  : _loadEpisodesUseCase = loadEpisodesUseCase ?? sl<LoadEpisodesUseCase>(),
        _filterEpisodesUseCase =
            filterEpisodesUseCase ?? sl<FilterEpisodesUseCase>(),
        _searchEpisodesUseCase =
            searchEpisodesUseCase ?? sl<SearchEpisodesUseCase>(),
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
  /// Returns the complete list of loaded audio files.
  List<AudioFile> get allEpisodes => _allEpisodes;

  /// Returns the list of audio files after applying current filters.
  List<AudioFile> get filteredEpisodes => _filteredEpisodes;

  /// The currently selected language filter code (e.g., 'en-US').
  String get selectedLanguage => _preferencesRepository.selectedLanguage;

  /// The currently selected category slug (e.g., 'daily-news').
  String get selectedCategory => _preferencesRepository.selectedCategory;

  /// The current search query string.
  String get searchQuery => _preferencesRepository.searchQuery;

  /// The current sort order (e.g., 'newest', 'oldest').
  String get sortOrder => _preferencesRepository.sortOrder;

  /// Whether the service is currently loading data.
  bool get isLoading => _isLoading;

  /// The current error message, if any.
  String? get errorMessage => _errorMessage;

  /// Whether an error has occurred.
  bool get hasError => _errorMessage != null;

  /// Whether any episodes have been loaded.
  bool get hasEpisodes => _allEpisodes.isNotEmpty;

  /// Whether the current filters resulted in any matches.
  bool get hasFilteredResults => _filteredEpisodes.isNotEmpty;

  /// Retrieves a list of recently listened episodes.
  ///
  /// Returns episodes ordered by listen time, limited to [limit] items.
  List<AudioFile> getListenHistoryEpisodes({int limit = 50}) {
    return _progressRepository.getListenHistoryEpisodes(allEpisodes,
        limit: limit);
  }

  /// Returns a map of episode IDs to their last listen timestamp.
  Map<String, DateTime> get listenHistory => _progressRepository.listenHistory;

  /// Checks if an episode has been marked as finished.
  bool isEpisodeFinished(String episodeId) =>
      _progressRepository.isEpisodeFinished(episodeId);

  /// Checks if an episode has started but is not yet finished.
  bool isEpisodeUnfinished(String episodeId) =>
      _progressRepository.isEpisodeUnfinished(episodeId);

  /// Adds an episode to the listen history.
  ///
  /// [at] - Optional timestamp for when the listen occurred. Defaults to now.
  Future<void> addToListenHistory(AudioFile episode, {DateTime? at}) async {
    await _progressRepository.addToListenHistory(episode, at: at);
    notifyListeners();
  }

  /// Removes an episode from the listen history.
  Future<void> removeFromListenHistory(String episodeId) async {
    await _progressRepository.removeFromListenHistory(episodeId);
    notifyListeners();
  }

  /// Clears the entire listen history.
  Future<void> clearListenHistory() async {
    await _progressRepository.clearListenHistory();
    notifyListeners();
  }

  /// Fetches detailed content metadata for a specific episode.
  ///
  /// [id] - Episode ID; [language] - Language code; [category] - Category slug.
  /// Returns [AudioContent] or null if not found.
  Future<AudioContent?> fetchContentById(
      String id, String language, String category) async {
    return await _contentRepository.fetchContentById(id, language, category);
  }

  /// Retrieves detailed content metadata for a given [AudioFile].
  Future<AudioContent?> getContentForAudioFile(AudioFile audioFile) async {
    return await _contentRepository.getContentForAudioFile(audioFile);
  }

  /// Finds an [AudioFile] by its ID with fuzzy date matching.
  ///
  /// First tries exact ID match, then falls back to date-based matching.
  /// Returns null if no match is found.
  Future<AudioFile?> getAudioFileById(String contentId) async {
    // 1. Try exact ID match first (fastest)
    try {
      return allEpisodes.firstWhere((episode) => episode.id == contentId);
    } catch (_) {
      // 2. Fall back to fuzzy date matching
      return _findEpisodeByFuzzyDate(contentId);
    }
  }

  /// Helper to find an episode by extracting a date from the contentId.
  AudioFile? _findEpisodeByFuzzyDate(String contentId) {
    try {
      // Extract date pattern (YYYY-MM-DD)
      final dateRegex = RegExp(r'(\d{4}-\d{2}-\d{2})');
      final match = dateRegex.firstMatch(contentId);

      if (match == null) return null;

      final dateStr = match.group(1)!;
      final searchDate = DateTime.parse(dateStr);

      // Find episode with matching date (either in ID or publishDate)
      return allEpisodes.firstWhere((episode) {
        if (episode.id.contains(dateStr)) return true;

        final episodeDate = episode.publishDate;
        return episodeDate.year == searchDate.year &&
            episodeDate.month == searchDate.month &&
            episodeDate.day == searchDate.day;
      });
    } catch (_) {
      return null;
    }
  }

  /// Prefetches content metadata for a list of audio files to improve performance.
  Future<void> prefetchContent(List<AudioFile> audioFiles) async {
    await _contentRepository.prefetchContent(audioFiles);
  }

  /// Clears the content metadata cache.
  void clearContentCache() {
    _contentRepository.clearContentCache();
  }

  // Progress tracking methods
  /// Updates the playback completion percentage for an episode.
  ///
  /// [completion] should be a value between 0.0 and 1.0.
  Future<void> updateEpisodeCompletion(
      String episodeId, double completion) async {
    await _progressRepository.updateEpisodeCompletion(episodeId, completion);
    notifyListeners();
  }

  /// Marks an episode as completely finished.
  Future<void> markEpisodeAsFinished(String episodeId) async {
    await _progressRepository.markEpisodeAsFinished(episodeId);
    notifyListeners();
  }

  /// Retrieves the current completion percentage for an episode.
  double getEpisodeCompletion(String episodeId) {
    return _progressRepository.getEpisodeCompletion(episodeId);
  }

  /// Returns a list of episodes that have been started but not finished.
  List<AudioFile> getUnfinishedEpisodes() {
    return _progressRepository.getUnfinishedEpisodes(allEpisodes);
  }

  // Preferences methods
  /// Sets the sort order for episodes and reapplies filters.
  ///
  /// [sortOrder] can be 'newest', 'oldest', or 'alphabetical'.
  Future<void> setSortOrder(String sortOrder) async {
    await _preferencesRepository.setSortOrder(sortOrder);
    _applyCurrentFilters();
    notifyListeners();
  }

  /// Loads all available episodes from the repository.
  ///
  /// Updates [allEpisodes] and applies current filters. Sets loading state
  /// and error message appropriately.
  Future<void> loadAllEpisodes() async {
    _setLoading(true);
    _clearError();

    try {
      final episodes = await _loadEpisodesUseCase.loadAll();
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

  /// Loads episodes for a specific [language].
  ///
  /// Updates [allEpisodes] and applies current filters.
  Future<void> loadEpisodesForLanguage(String language) async {
    _setLoading(true);
    _clearError();

    try {
      final episodes = await _loadEpisodesUseCase.loadForLanguage(language);
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

  /// Sets the active language filter and reloads episodes.
  ///
  /// Validates [language] against supported languages. Updates preferences
  /// and triggers episode reload for the new language.
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

  /// Sets the active category filter and updates the view.
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

  /// Updates the search query and filters the episode list accordingly.
  void setSearchQuery(String query) {
    if (_disposed) return;

    _preferencesRepository.setSearchQuery(query);
    _applyCurrentFilters();
    notifyListeners();
  }

  // Data access methods
  /// Filters current episodes by [language].
  List<AudioFile> getEpisodesByLanguage(String language) {
    return _filterEpisodesUseCase.filterByLanguage(_allEpisodes, language);
  }

  /// Filters current episodes by [category].
  List<AudioFile> getEpisodesByCategory(String category) {
    return _filterEpisodesUseCase.filterByCategory(_allEpisodes, category);
  }

  /// Filters current episodes by both [language] and [category].
  List<AudioFile> getEpisodesByLanguageAndCategory(
      String language, String category) {
    return advancedSearch(
      _allEpisodes,
      languages: [language],
      categories: [category],
    );
  }

  // Statistics and utility methods
  /// Returns a map of statistics about the current content and usage.
  Map<String, dynamic> getStatistics() {
    return {
      'totalEpisodes': allEpisodes.length,
      'filteredEpisodes': filteredEpisodes.length,
      'selectedLanguage': selectedLanguage,
      'selectedCategory': selectedCategory,
      'searchQuery': searchQuery,
      'listeningStats': _progressRepository.getListeningStatistics(allEpisodes),
      'cacheStats': {'searchCache': _searchEpisodesUseCase.cacheSize},
      'contentCacheStats': _contentRepository.getCacheStatistics(),
    };
  }

  /// Refreshes all episodes from the API.
  ///
  /// Alias for [loadAllEpisodes], useful for pull-to-refresh patterns.
  Future<void> refresh() async {
    await loadAllEpisodes();
  }

  /// Clears all loaded episodes and caches.
  void clear() {
    _allEpisodes.clear();
    _filteredEpisodes.clear();
    _searchEpisodesUseCase.clearCache();

    _contentRepository.clearContentCache();
    _clearError();
    notifyListeners();
  }

  /// Searches for episodes using the streaming API if not found locally.
  Future<List<AudioFile>> searchEpisodes(String query) async {
    return _searchEpisodesUseCase(query: query, localEpisodes: _allEpisodes);
  }

  /// Returns debug information for a specific [AudioFile], including service state.
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

  /// Sets the completion status for an episode. Alias for [updateEpisodeCompletion].
  Future<void> setEpisodeCompletion(String episodeId, double completion) async {
    await updateEpisodeCompletion(episodeId, completion);
  }

  /// Caches the [content] object for a specific ID, language, and category.
  void cacheContent(
      String id, String language, String category, AudioContent content) {
    _contentRepository.cacheContent(id, language, category, content);
  }

  /// Retrieves cached content if available.
  AudioContent? getCachedContent(String id, String language, String category) {
    return _contentRepository.getCachedContent(id, language, category);
  }

  /// Returns the current list of filtered episodes.
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
    return _filterEpisodesUseCase(
      episodes: allEpisodes,
      language: selectedLanguage,
      category: selectedCategory,
      searchQuery: searchQuery,
      sortOrder: sortOrder,
    );
  }

  /// Performs an advanced search with multiple filter criteria.
  ///
  /// Supports filtering by [query], [languages], [categories], date range,
  /// and duration constraints. Returns sorted results based on [sortOrder].
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
    return _filterEpisodesUseCase.advancedFilter(
      episodes,
      query: query,
      languages: languages,
      categories: categories,
      dateFrom: dateFrom,
      dateTo: dateTo,
      minDuration: minDuration,
      maxDuration: maxDuration,
      sortOrder: sortOrder,
    );
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

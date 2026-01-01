import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/audio_file.dart';
import '../models/audio_content.dart';
import '../models/playlist.dart';
import '../repositories/repository_factory.dart';
import '../repositories/episode_repository.dart';
import '../repositories/content_repository.dart';
import '../repositories/progress_repository.dart';
import '../repositories/preferences_repository.dart';
import '../config/api_config.dart';
import 'playlist_service.dart';
import 'search_service.dart';

/// Facade service that bridges the old ContentService interface with new modular services
/// This maintains backward compatibility while using the improved architecture internally
class ContentFacadeService extends ChangeNotifier {
  // New modular services
  late final EpisodeRepository _episodeRepository;
  late final ContentRepository _contentRepository;
  late final ProgressRepository _progressRepository;
  late final PreferencesRepository _preferencesRepository;
  late final PlaylistService _playlistService;
  late final SearchService _searchService;

  // State management - ContentFacadeService manages state, SearchService is utility
  List<AudioFile> _allEpisodes = [];
  List<AudioFile> _filteredEpisodes = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;

  // Constructor - initialize all services
  ContentFacadeService() {
    _initializeServices();
  }

  void _initializeServices() {
    final factory = RepositoryFactory.instance;

    // Get repositories from factory
    _episodeRepository = factory.episodeRepository;
    _contentRepository = factory.contentRepository;
    _progressRepository = factory.progressRepository;
    _preferencesRepository = factory.preferencesRepository;

    // Create services
    _playlistService = PlaylistService();
    _searchService = SearchService();

    // Set up listeners to relay state changes
    _playlistService.addListener(_onServiceChange);

    // Initialize repositories
    _progressRepository.initialize();
    _preferencesRepository.initialize();

    if (kDebugMode) {
      print('ContentFacadeService: Initialized all modular services');
    }
  }

  void _onServiceChange() {
    if (_disposed) return;
    notifyListeners();
  }

  // Getters - maintain same interface as ContentService
  List<AudioFile> get allEpisodes => _allEpisodes;
  List<AudioFile> get filteredEpisodes => _filteredEpisodes;
  Playlist? get currentPlaylist => _playlistService.currentPlaylist;
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
    } catch (e) {
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
            // Check if episode ID contains the date
            if (episode.id.contains(dateStr)) {
              return true;
            }

            // Check if episode's publishDate matches
            final episodeDate = episode.publishDate;
            return episodeDate.year == searchDate.year &&
                episodeDate.month == searchDate.month &&
                episodeDate.day == searchDate.day;
          });
        }
      } catch (e) {
        // If date pattern matching also fails, return null
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

      if (kDebugMode) {
        print('ContentFacadeService: Loaded ${episodes.length} episodes');
      }
    } catch (e) {
      _setError('Failed to load episodes: $e');
      if (kDebugMode) {
        print('ContentFacadeService: Error loading episodes: $e');
      }
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

      if (kDebugMode) {
        print(
            'ContentFacadeService: Loaded ${episodes.length} episodes for $language');
      }
    } catch (e) {
      _setError('Failed to load episodes for $language: $e');
      if (kDebugMode) {
        print('ContentFacadeService: Error loading episodes for $language: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> setLanguage(String language) async {
    // Validate language
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
    // Validate category
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

  // Playlist methods
  void createPlaylistFromFiltered(String? name) {
    final playlistName = name ?? 'Filtered Episodes';
    _playlistService.createPlaylist(playlistName, filteredEpisodes);
  }

  void createPlaylist(String name, List<AudioFile> episodes) {
    _playlistService.createPlaylist(name, episodes);
  }

  void addToCurrentPlaylist(AudioFile episode) {
    _playlistService.addToCurrentPlaylist(episode);
  }

  void removeFromCurrentPlaylist(AudioFile episode) {
    _playlistService.removeFromCurrentPlaylist(episode);
  }

  void clearCurrentPlaylist() {
    _playlistService.clearCurrentPlaylist();
  }

  // Data access methods
  List<AudioFile> getEpisodesByLanguage(String language) {
    return _searchService.searchByLanguage(_allEpisodes, language);
  }

  List<AudioFile> getEpisodesByCategory(String category) {
    return _searchService.searchByCategory(_allEpisodes, category);
  }

  List<AudioFile> getEpisodesByLanguageAndCategory(
      String language, String category) {
    return _searchService.advancedSearch(
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
      'currentPlaylist': currentPlaylist?.toJson(),
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
    _searchService.clearSearchCache();
    _playlistService.clearCurrentPlaylist();
    _contentRepository.clearContentCache();
    _clearError();
    notifyListeners();
  }

  Future<List<AudioFile>> searchEpisodes(String query) async {
    return _searchService.searchEpisodes(query, _allEpisodes);
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
      'facade_service': 'ContentFacadeService',
      'episode_count': allEpisodes.length,
      'filtered_count': filteredEpisodes.length,
      'current_playlist': currentPlaylist?.name,
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

  AudioFile? getNextEpisode(AudioFile currentEpisode) {
    final currentIndex =
        filteredEpisodes.indexWhere((e) => e.id == currentEpisode.id);
    if (currentIndex >= 0 && currentIndex < filteredEpisodes.length - 1) {
      return filteredEpisodes[currentIndex + 1];
    }
    return null;
  }

  AudioFile? getPreviousEpisode(AudioFile currentEpisode) {
    final currentIndex =
        filteredEpisodes.indexWhere((e) => e.id == currentEpisode.id);
    if (currentIndex > 0) {
      return filteredEpisodes[currentIndex - 1];
    }
    return null;
  }

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

  /// Apply current filters using SearchService
  void _applyCurrentFilters() {
    _filteredEpisodes = _searchService.applyFilters(
      _allEpisodes,
      selectedLanguage: selectedLanguage,
      selectedCategory: selectedCategory,
      searchQuery: searchQuery,
      sortOrder: _preferencesRepository.sortOrder,
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

    _playlistService.removeListener(_onServiceChange);
    _playlistService.dispose();
    _contentRepository.dispose();
    _progressRepository.dispose();
    _preferencesRepository.dispose();
    super.dispose();
  }
}

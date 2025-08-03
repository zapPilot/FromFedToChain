import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/audio_file.dart';
import '../models/audio_content.dart';
import '../models/playlist.dart';
import '../config/api_config.dart';
import 'streaming_api_service.dart';

/// Service for managing audio content, playlists, and episode navigation
class ContentService extends ChangeNotifier {
  List<AudioFile> _allEpisodes = [];
  List<AudioFile> _filteredEpisodes = [];
  Playlist? _currentPlaylist;
  String _selectedLanguage = 'zh-TW';
  String _selectedCategory = 'all';
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;
  
  // Content cache for language learning scripts
  final Map<String, AudioContent> _contentCache = {};
  static final _httpClient = http.Client();

  // Getters
  List<AudioFile> get allEpisodes => _allEpisodes;
  List<AudioFile> get filteredEpisodes => _filteredEpisodes;
  Playlist? get currentPlaylist => _currentPlaylist;
  String get selectedLanguage => _selectedLanguage;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  ContentService() {
    _loadPreferences();
  }

  /// Load user preferences
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedLanguage = prefs.getString('selected_language') ?? 'zh-TW';
      _selectedCategory = prefs.getString('selected_category') ?? 'all';

      // Validate loaded language
      if (!ApiConfig.isValidLanguage(_selectedLanguage)) {
        _selectedLanguage = 'zh-TW';
      }

      notifyListeners();
    } catch (e) {
      print('ContentService: Failed to load preferences: $e');
    }
  }

  /// Save user preferences
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_language', _selectedLanguage);
      await prefs.setString('selected_category', _selectedCategory);
    } catch (e) {
      print('ContentService: Failed to save preferences: $e');
    }
  }

  /// Fetch content/script for a specific episode from Cloudflare API
  /// This provides the actual content text for language learning
  Future<AudioContent?> fetchContentById(String id, String language, String category) async {
    final cacheKey = '$language/$category/$id';
    
    // Return cached content if available
    if (_contentCache.containsKey(cacheKey)) {
      if (kDebugMode) {
        print('ContentService: Returning cached content for $cacheKey');
      }
      return _contentCache[cacheKey];
    }

    try {
      if (kDebugMode) {
        print('ContentService: Fetching content for $cacheKey from API');
      }
      
      // DEBUG: Hardcoded URL for testing
      final url = Uri.parse('https://signed-url.davidtnfsh.workers.dev/api/content/zh-TW/startup/2025-07-05-blockchain-private-equity-tokenization');
      
      final response = await _httpClient.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'User-Agent': 'FromFedToChain/1.0.0 (Flutter)',
        },
      ).timeout(ApiConfig.apiTimeout);
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final content = AudioContent.fromJson(jsonData);
        
        // Cache the content
        _contentCache[cacheKey] = content;
        
        if (kDebugMode) {
          print('ContentService: Successfully fetched and cached content for $cacheKey');
        }
        
        return content;
      } else {
        if (kDebugMode) {
          print('ContentService: Failed to fetch content - HTTP ${response.statusCode}');
          print('ContentService: Response body: ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('ContentService: Error fetching content for $cacheKey: $e');
      }
      return null;
    }
  }

  /// Get content for an audio file with lazy loading
  /// This is the main method for getting content/scripts for language learning
  Future<AudioContent?> getContentForAudioFile(AudioFile audioFile) async {
    return await fetchContentById(audioFile.id, audioFile.language, audioFile.category);
  }

  /// Get cached content without fetching (synchronous)
  AudioContent? getCachedContent(String id, String language, String category) {
    final cacheKey = '$language/$category/$id';
    return _contentCache[cacheKey];
  }

  /// Pre-fetch content for multiple episodes (useful for preloading)
  Future<void> prefetchContent(List<AudioFile> audioFiles) async {
    if (audioFiles.isEmpty) return;
    
    if (kDebugMode) {
      print('ContentService: Pre-fetching content for ${audioFiles.length} episodes');
    }
    
    final futures = audioFiles.map((audioFile) => 
      fetchContentById(audioFile.id, audioFile.language, audioFile.category)
    );
    
    try {
      await Future.wait(futures);
      if (kDebugMode) {
        print('ContentService: Pre-fetch completed, cached ${_contentCache.length} content items');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ContentService: Pre-fetch failed: $e');
      }
    }
  }

  /// Clear content cache
  void clearContentCache() {
    _contentCache.clear();
    if (kDebugMode) {
      print('ContentService: Content cache cleared');
    }
  }

  /// Load all episodes from the streaming API
  Future<void> loadAllEpisodes() async {
    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      print('ContentService: Loading all episodes...');
      _allEpisodes = await StreamingApiService.getAllEpisodes();

      if (_allEpisodes.isEmpty) {
        _setError('No episodes found. Please check your internet connection.');
      } else {
        print('ContentService: Loaded ${_allEpisodes.length} episodes');
        _applyFilters();
      }
    } catch (e) {
      print('ContentService: Failed to load episodes: $e');
      _setError('Failed to load episodes: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load episodes for specific language
  Future<void> loadEpisodesForLanguage(String language) async {
    if (!ApiConfig.isValidLanguage(language)) {
      _setError('Unsupported language: $language');
      return;
    }

    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      print('ContentService: Loading episodes for language: $language');
      final episodes =
          await StreamingApiService.getAllEpisodesForLanguage(language);

      // Update or merge with existing episodes
      _updateEpisodesForLanguage(language, episodes);
      _applyFilters();

      print('ContentService: Loaded ${episodes.length} episodes for $language');
    } catch (e) {
      print('ContentService: Failed to load episodes for $language: $e');
      _setError('Failed to load episodes for $language: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Update episodes for a specific language
  void _updateEpisodesForLanguage(
      String language, List<AudioFile> newEpisodes) {
    // Remove existing episodes for this language
    _allEpisodes.removeWhere((episode) => episode.language == language);

    // Add new episodes
    _allEpisodes.addAll(newEpisodes);

    // Sort by date (newest first)
    _allEpisodes.sort((a, b) => b.lastModified.compareTo(a.lastModified));
  }

  /// Set selected language filter
  Future<void> setLanguage(String language) async {
    if (!ApiConfig.isValidLanguage(language)) {
      _setError('Unsupported language: $language');
      return;
    }

    if (_selectedLanguage != language) {
      _selectedLanguage = language;
      _applyFilters();
      await _savePreferences();
      notifyListeners();

      // Load episodes for new language if not already loaded
      final hasEpisodesForLanguage =
          _allEpisodes.any((episode) => episode.language == language);

      if (!hasEpisodesForLanguage) {
        await loadEpisodesForLanguage(language);
      }
    }
  }

  /// Set selected category filter
  Future<void> setCategory(String category) async {
    if (category != 'all' && !ApiConfig.isValidCategory(category)) {
      _setError('Unsupported category: $category');
      return;
    }

    if (_selectedCategory != category) {
      _selectedCategory = category;
      _applyFilters();
      await _savePreferences();
      notifyListeners();
    }
  }

  /// Set search query
  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      _applyFilters();
      notifyListeners();
    }
  }

  /// Apply current filters to episodes
  void _applyFilters() {
    var filtered = List<AudioFile>.from(_allEpisodes);

    // Filter by language
    if (_selectedLanguage != 'all') {
      filtered = filtered
          .where((episode) => episode.language == _selectedLanguage)
          .toList();
    }

    // Filter by category
    if (_selectedCategory != 'all') {
      filtered = filtered
          .where((episode) => episode.category == _selectedCategory)
          .toList();
    }

    // Filter by search query
    if (_searchQuery.trim().isNotEmpty) {
      final lowerQuery = _searchQuery.toLowerCase();
      filtered = filtered.where((episode) {
        return episode.title.toLowerCase().contains(lowerQuery) ||
            episode.id.toLowerCase().contains(lowerQuery) ||
            episode.category.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    _filteredEpisodes = filtered;
  }

  /// Create playlist from current filtered episodes
  void createPlaylistFromFiltered(String? name) {
    final playlistName = name ?? 'Current Selection';
    _currentPlaylist = Playlist.fromEpisodes(playlistName, _filteredEpisodes);
    notifyListeners();
  }

  /// Create playlist from specific episodes
  void createPlaylist(String name, List<AudioFile> episodes) {
    _currentPlaylist = Playlist.fromEpisodes(name, episodes);
    notifyListeners();
  }

  /// Add episode to current playlist
  void addToCurrentPlaylist(AudioFile episode) {
    if (_currentPlaylist == null) {
      createPlaylist('My Playlist', [episode]);
    } else {
      _currentPlaylist = _currentPlaylist!.addEpisode(episode);
      notifyListeners();
    }
  }

  /// Remove episode from current playlist
  void removeFromCurrentPlaylist(AudioFile episode) {
    if (_currentPlaylist != null) {
      _currentPlaylist = _currentPlaylist!.removeEpisode(episode);
      notifyListeners();
    }
  }

  /// Get next episode for playback
  AudioFile? getNextEpisode(AudioFile currentEpisode) {
    // If we have a current playlist, use playlist navigation
    if (_currentPlaylist != null) {
      final currentInPlaylist = _currentPlaylist!.episodes
          .any((episode) => episode.id == currentEpisode.id);

      if (currentInPlaylist) {
        final currentPlaylist = _currentPlaylist!.moveToEpisode(currentEpisode);
        return currentPlaylist.nextEpisode;
      }
    }

    // Fallback to filtered episodes navigation
    final currentIndex = _filteredEpisodes
        .indexWhere((episode) => episode.id == currentEpisode.id);

    if (currentIndex >= 0 && currentIndex < _filteredEpisodes.length - 1) {
      return _filteredEpisodes[currentIndex + 1];
    }

    return null;
  }

  /// Get previous episode for playback
  AudioFile? getPreviousEpisode(AudioFile currentEpisode) {
    // If we have a current playlist, use playlist navigation
    if (_currentPlaylist != null) {
      final currentInPlaylist = _currentPlaylist!.episodes
          .any((episode) => episode.id == currentEpisode.id);

      if (currentInPlaylist) {
        final currentPlaylist = _currentPlaylist!.moveToEpisode(currentEpisode);
        return currentPlaylist.previousEpisode;
      }
    }

    // Fallback to filtered episodes navigation
    final currentIndex = _filteredEpisodes
        .indexWhere((episode) => episode.id == currentEpisode.id);

    if (currentIndex > 0) {
      return _filteredEpisodes[currentIndex - 1];
    }

    return null;
  }

  /// Get episodes by language
  List<AudioFile> getEpisodesByLanguage(String language) {
    return _allEpisodes
        .where((episode) => episode.language == language)
        .toList();
  }

  /// Get episodes by category
  List<AudioFile> getEpisodesByCategory(String category) {
    return _allEpisodes
        .where((episode) => episode.category == category)
        .toList();
  }

  /// Get episodes by language and category
  List<AudioFile> getEpisodesByLanguageAndCategory(
      String language, String category) {
    return _allEpisodes
        .where((episode) =>
            episode.language == language && episode.category == category)
        .toList();
  }

  /// Get episode statistics
  Map<String, dynamic> getStatistics() {
    final stats = <String, dynamic>{
      'totalEpisodes': _allEpisodes.length,
      'filteredEpisodes': _filteredEpisodes.length,
      'languages': <String, int>{},
      'categories': <String, int>{},
    };

    // Count by language
    for (final episode in _allEpisodes) {
      final languageStats = stats['languages'] as Map<String, int>;
      languageStats[episode.language] =
          (languageStats[episode.language] ?? 0) + 1;
    }

    // Count by category
    for (final episode in _allEpisodes) {
      final categoryStats = stats['categories'] as Map<String, int>;
      categoryStats[episode.category] =
          (categoryStats[episode.category] ?? 0) + 1;
    }

    return stats;
  }

  /// Refresh content (reload from API)
  Future<void> refresh() async {
    _allEpisodes.clear();
    _filteredEpisodes.clear();
    await loadAllEpisodes();
  }

  /// Clear all content
  void clear() {
    _allEpisodes.clear();
    _filteredEpisodes.clear();
    _currentPlaylist = null;
    _clearError();
    notifyListeners();
  }

  /// Search episodes across all content
  Future<List<AudioFile>> searchEpisodes(String query) async {
    if (query.trim().isEmpty) {
      return _filteredEpisodes;
    }

    try {
      // Search within already loaded episodes first
      final localResults = _allEpisodes.where((episode) {
        final lowerQuery = query.toLowerCase();
        return episode.title.toLowerCase().contains(lowerQuery) ||
            episode.id.toLowerCase().contains(lowerQuery) ||
            episode.category.toLowerCase().contains(lowerQuery);
      }).toList();

      // If we have good local results, return them
      if (localResults.isNotEmpty) {
        return localResults;
      }

      // Otherwise, search via API
      return await StreamingApiService.searchEpisodes(query);
    } catch (e) {
      print('ContentService: Search failed: $e');
      return [];
    }
  }

  /// Check if service has episodes loaded
  bool get hasEpisodes => _allEpisodes.isNotEmpty;

  /// Check if current filter has results
  bool get hasFilteredResults => _filteredEpisodes.isNotEmpty;

  /// Get debug information for an audio file
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
      'totalEpisodes': _allEpisodes.length,
      'filteredEpisodes': _filteredEpisodes.length,
      'selectedLanguage': _selectedLanguage,
      'selectedCategory': _selectedCategory,
      'searchQuery': _searchQuery,
      'isLoading': _isLoading,
      'hasError': _errorMessage != null,
      'errorMessage': _errorMessage,
    };
  }

  // Helper methods
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
  }

  @override
  void dispose() {
    StreamingApiService.dispose();
    _httpClient.close();
    _contentCache.clear();
    super.dispose();
  }
}

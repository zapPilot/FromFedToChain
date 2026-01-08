import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:from_fed_to_chain_app/features/content/models/audio_file.dart';
import 'package:from_fed_to_chain_app/core/config/api_config.dart';
import 'package:from_fed_to_chain_app/features/content/data/streaming_api_service.dart';
import 'package:from_fed_to_chain_app/features/content/data/episode_repository.dart';
import 'package:from_fed_to_chain_app/core/services/logger_service.dart';

/// Concrete implementation of EpisodeRepository
/// Handles all episode data access operations
class EpisodeRepositoryImpl implements EpisodeRepository {
  static final _log = LoggerService.getLogger('EpisodeRepositoryImpl');

  /// StreamingApiService instance for API calls (injected)
  final StreamingApiService _apiService;

  List<AudioFile> _allEpisodes = [];
  bool _isLoading = false;
  String? _errorMessage;

  /// Create an EpisodeRepositoryImpl with optional StreamingApiService injection.
  ///
  /// [apiService] - Optional StreamingApiService instance. If not provided,
  ///                uses the singleton instance for backward compatibility.
  EpisodeRepositoryImpl({StreamingApiService? apiService})
      : _apiService = apiService ?? StreamingApiService.instance;

  // Getters for current state
  List<AudioFile> get allEpisodes => List.unmodifiable(_allEpisodes);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get hasEpisodes => _allEpisodes.isNotEmpty;

  @override
  Future<List<AudioFile>> loadAllEpisodes() async {
    if (_isLoading) return _allEpisodes;

    _setLoading(true);
    _clearError();

    try {
      _log.info('Loading all episodes...');
      _allEpisodes = await _apiService.fetchAllEpisodes();

      if (_allEpisodes.isEmpty) {
        _setError('No episodes found. Please check your internet connection.');
      } else {
        _log.info('Loaded ${_allEpisodes.length} episodes');
      }
    } catch (e) {
      _log.severe('Failed to load episodes: $e');
      _setError('Failed to load episodes: $e');
    } finally {
      _setLoading(false);
    }

    return _allEpisodes;
  }

  @override
  Future<List<AudioFile>> loadEpisodesForLanguage(String language) async {
    if (!ApiConfig.isValidLanguage(language)) {
      _setError('Unsupported language: $language');
      return [];
    }

    if (_isLoading) return getEpisodesByLanguage(_allEpisodes, language);

    _setLoading(true);
    _clearError();

    try {
      _log.info('Loading episodes for language: $language');
      final episodes = await _apiService.fetchAllEpisodesForLanguage(language);

      // Update or merge with existing episodes
      _updateEpisodesForLanguage(language, episodes);

      _log.info('Loaded ${episodes.length} episodes for $language');

      return episodes;
    } catch (e) {
      _log.severe('Failed to load episodes for $language: $e');
      _setError('Failed to load episodes for $language: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  @override
  Future<List<AudioFile>> searchEpisodes(String query) async {
    if (query.trim().isEmpty) {
      return _allEpisodes;
    }

    try {
      // Search within already loaded episodes first
      final localResults = filterEpisodesByQuery(_allEpisodes, query);

      // If we have good local results, return them
      if (localResults.isNotEmpty) {
        return localResults;
      }

      // Otherwise, search via API
      return await _apiService.fetchSearchEpisodes(query);
    } catch (e) {
      _log.severe('Search failed: $e');
      return [];
    }
  }

  @override
  Future<AudioFile?> getEpisodeById(String contentId,
      {String? preferredLanguage}) async {
    // Check if contentId contains language and split if needed
    final languageSuffixes = ['zh-TW', 'en-US', 'ja-JP'];
    String? requestedLanguage = preferredLanguage;
    String baseContentId = contentId;

    for (final suffix in languageSuffixes) {
      if (contentId.endsWith('-$suffix')) {
        requestedLanguage = suffix;
        baseContentId =
            contentId.substring(0, contentId.length - suffix.length - 1);
        break;
      }
    }

    return await _findEpisodeByIdAndLanguage(
        contentId, baseContentId, requestedLanguage);
  }

  @override
  List<AudioFile> getEpisodesByLanguage(
      List<AudioFile> episodes, String language) {
    return episodes.where((episode) => episode.language == language).toList();
  }

  @override
  List<AudioFile> getEpisodesByCategory(
      List<AudioFile> episodes, String category) {
    return episodes.where((episode) => episode.category == category).toList();
  }

  @override
  List<AudioFile> getEpisodesByLanguageAndCategory(
    List<AudioFile> episodes,
    String language,
    String category,
  ) {
    return episodes
        .where((episode) =>
            episode.language == language && episode.category == category)
        .toList();
  }

  @override
  List<AudioFile> filterEpisodesByQuery(
      List<AudioFile> episodes, String query) {
    if (query.trim().isEmpty) return episodes;

    final lowerQuery = query.toLowerCase();
    return episodes.where((episode) {
      return episode.title.toLowerCase().contains(lowerQuery) ||
          episode.id.toLowerCase().contains(lowerQuery) ||
          episode.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  @override
  Map<String, dynamic> getEpisodeStatistics(List<AudioFile> episodes) {
    final stats = <String, dynamic>{
      'totalEpisodes': episodes.length,
      'languages': <String, int>{},
      'categories': <String, int>{},
    };

    // Count by language
    for (final episode in episodes) {
      final languageStats = stats['languages'] as Map<String, int>;
      languageStats[episode.language] =
          (languageStats[episode.language] ?? 0) + 1;
    }

    // Count by category
    for (final episode in episodes) {
      final categoryStats = stats['categories'] as Map<String, int>;
      categoryStats[episode.category] =
          (categoryStats[episode.category] ?? 0) + 1;
    }

    return stats;
  }

  /// Update episodes for a specific language
  void _updateEpisodesForLanguage(
      String language, List<AudioFile> newEpisodes) {
    // Remove existing episodes for this language
    _allEpisodes.removeWhere((episode) => episode.language == language);

    // Add new episodes
    _allEpisodes.addAll(newEpisodes);

    // Sort by date (newest first)
    _allEpisodes.sort((a, b) => b.publishDate.compareTo(a.publishDate));
  }

  /// Find episode by base ID and language preference
  Future<AudioFile?> _findEpisodeByIdAndLanguage(
    String fullContentId,
    String baseContentId,
    String? preferredLanguage,
  ) async {
    // Ensure episodes are loaded
    if (_allEpisodes.isEmpty) {
      await loadAllEpisodes();
    }

    if (_allEpisodes.isEmpty) {
      return null;
    }

    // Strategy 1: Try exact match with full content ID (includes language suffix)
    try {
      final exactMatch = _allEpisodes.firstWhere(
        (episode) => episode.id == fullContentId,
      );
      return exactMatch;
    } catch (e) {
      // Continue to next strategy
    }

    // Strategy 2: If preferred language is specified, look for baseContentId with that language
    if (preferredLanguage != null) {
      final languageSpecificId = '$baseContentId-$preferredLanguage';
      try {
        final languageMatch = _allEpisodes.firstWhere(
          (episode) => episode.id == languageSpecificId,
        );
        return languageMatch;
      } catch (e) {
        // Continue to next approach
      }

      // Also try finding episodes with base ID and matching language
      final episodesWithBaseId = _allEpisodes.where((episode) {
        // Check if episode ID starts with baseContentId and has the preferred language
        return episode.id.startsWith(baseContentId) &&
            episode.language == preferredLanguage;
      }).toList();

      if (episodesWithBaseId.isNotEmpty) {
        return episodesWithBaseId.first;
      }
    }

    // Strategy 3: Fuzzy matching with date extraction from baseContentId
    final dateMatch = RegExp(r'(\d{4}-\d{2}-\d{2})').firstMatch(baseContentId);
    if (dateMatch != null) {
      final date = dateMatch.group(1)!;
      final episodesWithDate =
          _allEpisodes.where((episode) => episode.id.contains(date)).toList();

      if (episodesWithDate.isNotEmpty) {
        // If preferred language specified, prioritize episodes with that language
        if (preferredLanguage != null) {
          final languageMatches = episodesWithDate
              .where((episode) => episode.language == preferredLanguage)
              .toList();

          if (languageMatches.isNotEmpty) {
            return languageMatches.first;
          }
        }

        // Fallback: use any episode with the date, prioritizing those that match more of the baseContentId
        final bestMatch = episodesWithDate.firstWhere(
          (episode) => episode.id
              .toLowerCase()
              .contains(baseContentId.toLowerCase().replaceAll('$date-', '')),
          orElse: () => episodesWithDate.first,
        );

        return bestMatch;
      }
    }

    return null;
  }

  /// Refresh episodes (reload from API)
  Future<void> refresh() async {
    _allEpisodes.clear();
    await loadAllEpisodes();
  }

  /// Clear all episodes
  void clear() {
    _allEpisodes.clear();
    _clearError();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
  }

  void _setError(String error) {
    _errorMessage = error;
  }

  void _clearError() {
    _errorMessage = null;
  }

  @override
  void dispose() {
    _allEpisodes.clear();
    _clearError();
  }

  // Testing methods
  @visibleForTesting
  void setEpisodesForTesting(List<AudioFile> episodes) {
    _allEpisodes = List<AudioFile>.from(episodes);
  }

  @visibleForTesting
  void setLoadingForTesting(bool loading) {
    _setLoading(loading);
  }

  @visibleForTesting
  void setErrorForTesting(String? error) {
    if (error == null) {
      _clearError();
    } else {
      _setError(error);
    }
  }
}

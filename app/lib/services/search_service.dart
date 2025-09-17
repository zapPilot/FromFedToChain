import 'package:flutter/foundation.dart';
import '../models/audio_file.dart';
import '../services/streaming_api_service.dart';

/// Service for searching and filtering episodes
/// Handles search queries, filtering by language/category, and sorting operations
class SearchService {
  // Search cache for performance
  final Map<String, List<AudioFile>> _searchCache = {};
  final int _maxCacheSize = 20;

  // Getters
  int get cacheSize => _searchCache.length;
  List<String> get cachedQueries => _searchCache.keys.toList();

  /// Apply filters to episodes based on language, category, and search query
  List<AudioFile> applyFilters(
    List<AudioFile> allEpisodes, {
    required String selectedLanguage,
    required String selectedCategory,
    required String searchQuery,
    required String sortOrder,
  }) {
    var filtered = List<AudioFile>.from(allEpisodes);

    // Filter by language
    filtered = _filterByLanguage(filtered, selectedLanguage);

    // Filter by category
    if (selectedCategory != 'all') {
      filtered = _filterByCategory(filtered, selectedCategory);
    }

    // Filter by search query
    if (searchQuery.trim().isNotEmpty) {
      filtered = _filterBySearchQuery(filtered, searchQuery);
    }

    // Apply sorting
    filtered = _applySorting(filtered, sortOrder);

    return filtered;
  }

  /// Filter episodes by language
  List<AudioFile> _filterByLanguage(List<AudioFile> episodes, String language) {
    return episodes.where((episode) => episode.language == language).toList();
  }

  /// Filter episodes by category
  List<AudioFile> _filterByCategory(List<AudioFile> episodes, String category) {
    return episodes.where((episode) => episode.category == category).toList();
  }

  /// Filter episodes by search query
  List<AudioFile> _filterBySearchQuery(List<AudioFile> episodes, String query) {
    if (query.trim().isEmpty) return episodes;

    final lowerQuery = query.toLowerCase();
    return episodes.where((episode) {
      return episode.title.toLowerCase().contains(lowerQuery) ||
          episode.id.toLowerCase().contains(lowerQuery) ||
          episode.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Apply sorting to episodes list
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

  /// Search episodes across all content with caching
  Future<List<AudioFile>> searchEpisodes(
    String query,
    List<AudioFile> localEpisodes,
  ) async {
    if (query.trim().isEmpty) {
      return localEpisodes;
    }

    // Check cache first
    final cacheKey = query.toLowerCase().trim();
    if (_searchCache.containsKey(cacheKey)) {
      if (kDebugMode) {
        print('SearchService: Returning cached results for "$query"');
      }
      return _searchCache[cacheKey]!;
    }

    try {
      // Search within already loaded episodes first
      final localResults = _filterBySearchQuery(localEpisodes, query);

      // If we have good local results, cache and return them
      if (localResults.isNotEmpty) {
        _cacheSearchResult(cacheKey, localResults);
        return localResults;
      }

      // Otherwise, search via API
      if (kDebugMode) {
        print('SearchService: Searching API for "$query"');
      }
      final apiResults = await StreamingApiService.searchEpisodes(query);
      _cacheSearchResult(cacheKey, apiResults);

      return apiResults;
    } catch (e) {
      if (kDebugMode) {
        print('SearchService: Search failed for "$query": $e');
      }
      return [];
    }
  }

  /// Advanced search with multiple criteria
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

    // Filter by text query
    if (query != null && query.trim().isNotEmpty) {
      results = _filterBySearchQuery(results, query);
    }

    // Filter by languages
    if (languages != null && languages.isNotEmpty) {
      results = results
          .where((episode) => languages.contains(episode.language))
          .toList();
    }

    // Filter by categories
    if (categories != null && categories.isNotEmpty) {
      results = results
          .where((episode) => categories.contains(episode.category))
          .toList();
    }

    // Filter by date range
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
              episode.publishDate.isBefore(dateTo.add(Duration(days: 1))))
          .toList();
    }

    // Filter by duration
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

    // Apply sorting
    results = _applySorting(results, sortOrder);

    return results;
  }

  /// Search by category with fuzzy matching
  List<AudioFile> searchByCategory(
      List<AudioFile> episodes, String categoryQuery) {
    if (categoryQuery.trim().isEmpty) return episodes;

    final lowerQuery = categoryQuery.toLowerCase();
    return episodes.where((episode) {
      return episode.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Search by language with fuzzy matching
  List<AudioFile> searchByLanguage(
      List<AudioFile> episodes, String languageQuery) {
    if (languageQuery.trim().isEmpty) return episodes;

    final lowerQuery = languageQuery.toLowerCase();
    return episodes.where((episode) {
      return episode.language.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Search by date range
  List<AudioFile> searchByDateRange(
    List<AudioFile> episodes,
    DateTime? from,
    DateTime? to,
  ) {
    var results = episodes;

    if (from != null) {
      results = results
          .where((episode) =>
              episode.publishDate.isAfter(from) ||
              episode.publishDate.isAtSameMomentAs(from))
          .toList();
    }

    if (to != null) {
      results = results
          .where((episode) =>
              episode.publishDate.isBefore(to.add(Duration(days: 1))))
          .toList();
    }

    return results;
  }

  /// Search by duration range
  List<AudioFile> searchByDuration(
    List<AudioFile> episodes,
    Duration? minDuration,
    Duration? maxDuration,
  ) {
    return episodes.where((episode) {
      if (episode.duration == null) return false;

      final duration = episode.duration!;
      bool withinMin = minDuration == null || duration >= minDuration;
      bool withinMax = maxDuration == null || duration <= maxDuration;

      return withinMin && withinMax;
    }).toList();
  }

  /// Get search suggestions based on input
  List<String> getSearchSuggestions(List<AudioFile> episodes, String input) {
    if (input.trim().isEmpty) return [];

    final lowerInput = input.toLowerCase();
    final suggestions = <String>{};

    for (final episode in episodes) {
      // Add title matches
      if (episode.title.toLowerCase().contains(lowerInput)) {
        suggestions.add(episode.title);
      }

      // Add category matches
      if (episode.category.toLowerCase().contains(lowerInput)) {
        suggestions.add(episode.category);
      }

      // Add ID-based suggestions (for specific dates or topics)
      final idParts = episode.id.split('-');
      for (final part in idParts) {
        if (part.toLowerCase().contains(lowerInput) && part.length > 2) {
          suggestions.add(part.replaceAll('-', ' '));
        }
      }
    }

    // Limit suggestions
    return suggestions.take(10).toList()..sort();
  }

  /// Get trending search terms (based on episode titles and categories)
  List<String> getTrendingSearchTerms(List<AudioFile> episodes) {
    final termFrequency = <String, int>{};

    for (final episode in episodes) {
      // Analyze recent episodes (last 30 days)
      final isRecent =
          DateTime.now().difference(episode.publishDate).inDays <= 30;
      if (!isRecent) continue;

      // Extract words from title
      final words = episode.title.toLowerCase().split(RegExp(r'\W+'));
      for (final word in words) {
        if (word.length > 3) {
          termFrequency[word] = (termFrequency[word] ?? 0) + 1;
        }
      }

      // Include category
      termFrequency[episode.category] =
          (termFrequency[episode.category] ?? 0) + 2;
    }

    // Return most frequent terms
    final sortedTerms = termFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedTerms.take(5).map((e) => e.key).toList();
  }

  /// Filter episodes that match any of the provided tags/keywords
  List<AudioFile> filterByTags(List<AudioFile> episodes, List<String> tags) {
    if (tags.isEmpty) return episodes;

    return episodes.where((episode) {
      final lowerTitle = episode.title.toLowerCase();
      final lowerCategory = episode.category.toLowerCase();
      final lowerId = episode.id.toLowerCase();

      return tags.any((tag) {
        final lowerTag = tag.toLowerCase();
        return lowerTitle.contains(lowerTag) ||
            lowerCategory.contains(lowerTag) ||
            lowerId.contains(lowerTag);
      });
    }).toList();
  }

  /// Cache search result with LRU eviction
  void _cacheSearchResult(String query, List<AudioFile> results) {
    // Remove oldest entry if cache is full
    if (_searchCache.length >= _maxCacheSize) {
      final oldestKey = _searchCache.keys.first;
      _searchCache.remove(oldestKey);
    }

    _searchCache[query] = results;

    if (kDebugMode) {
      print(
          'SearchService: Cached search results for "$query" (${results.length} results)');
    }
  }

  /// Clear search cache
  void clearSearchCache() {
    final previousSize = _searchCache.length;
    _searchCache.clear();

    if (kDebugMode) {
      print('SearchService: Cleared search cache (was $previousSize entries)');
    }
  }

  /// Remove specific search from cache
  void removeFromCache(String query) {
    final removed = _searchCache.remove(query.toLowerCase().trim()) != null;

    if (kDebugMode && removed) {
      print('SearchService: Removed search "$query" from cache');
    }
  }

  /// Get search cache statistics
  Map<String, dynamic> getCacheStatistics() {
    return {
      'cacheSize': _searchCache.length,
      'maxCacheSize': _maxCacheSize,
      'cachedQueries': _searchCache.keys.toList(),
      'totalCachedResults': _searchCache.values
          .fold<int>(0, (sum, results) => sum + results.length),
    };
  }

  /// Warm up cache with common searches
  Future<void> warmUpSearchCache(List<AudioFile> episodes) async {
    final commonQueries = ['bitcoin', 'ethereum', 'defi', 'ai', 'macro'];

    for (final query in commonQueries) {
      final results = _filterBySearchQuery(episodes, query);
      if (results.isNotEmpty) {
        _cacheSearchResult(query, results);
      }
    }

    if (kDebugMode) {
      print(
          'SearchService: Warmed up search cache with ${commonQueries.length} common queries');
    }
  }

  /// Dispose of resources
  void dispose() {
    _searchCache.clear();
  }

  // Testing methods
  @visibleForTesting
  void setCacheForTesting(Map<String, List<AudioFile>> cache) {
    _searchCache.clear();
    _searchCache.addAll(cache);
  }

  @visibleForTesting
  Map<String, List<AudioFile>> getCacheForTesting() {
    return Map.unmodifiable(_searchCache);
  }

  @visibleForTesting
  void clearCacheForTesting() {
    _searchCache.clear();
  }
}

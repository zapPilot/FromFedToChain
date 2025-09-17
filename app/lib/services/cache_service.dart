import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/audio_file.dart';
import '../models/audio_content.dart';
import '../repositories/api_repository.dart';
import '../repositories/content_repository.dart';

/// Service for managing content caching and fetching
/// Handles content fetching, caching, and prefetching operations
class CacheService implements ContentRepository {
  // Content cache for language learning scripts
  final Map<String, AudioContent> _contentCache = {};

  CacheService();

  // Getters
  int get cacheSize => _contentCache.length;
  bool get hasCachedContent => _contentCache.isNotEmpty;
  List<String> get cachedContentKeys => _contentCache.keys.toList();

  /// Fetch content/script for a specific episode from API
  /// This provides the actual content text for language learning
  @override
  Future<AudioContent?> fetchContentById(
      String id, String language, String category) async {
    final cacheKey = '$language/$category/$id';

    // Return cached content if available
    if (_contentCache.containsKey(cacheKey)) {
      if (kDebugMode) {
        print('CacheService: Returning cached content for $cacheKey');
      }
      return _contentCache[cacheKey];
    }

    try {
      if (kDebugMode) {
        print('CacheService: Fetching content for $cacheKey from API');
      }

      final content =
          await ApiRepository.instance.fetchContent(id, language, category);

      if (content != null) {
        // Cache the content
        _contentCache[cacheKey] = content;

        if (kDebugMode) {
          print(
              'CacheService: Successfully fetched and cached content for $cacheKey');
        }

        return content;
      } else {
        if (kDebugMode) {
          print('CacheService: Failed to fetch content for $cacheKey');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('CacheService: Error fetching content for $cacheKey: $e');
      }
      return null;
    }
  }

  /// Get content for an audio file with lazy loading
  /// This is the main method for getting content/scripts for language learning
  @override
  Future<AudioContent?> getContentForAudioFile(AudioFile audioFile) async {
    return await fetchContentById(
        audioFile.id, audioFile.language, audioFile.category);
  }

  /// Get cached content without fetching (synchronous)
  @override
  AudioContent? getCachedContent(String id, String language, String category) {
    final cacheKey = '$language/$category/$id';
    return _contentCache[cacheKey];
  }

  /// Get content by ID, searching across all languages and categories
  /// Used for deep linking when we only have the content ID
  @override
  Future<AudioContent?> getContentById(
      String contentId, List<AudioFile> allEpisodes) async {
    AudioFile audioFile;
    try {
      audioFile = allEpisodes.firstWhere(
        (episode) => episode.id == contentId,
        orElse: () => throw StateError('Content not found'),
      );
    } catch (e) {
      if (kDebugMode) {
        print('CacheService: Content not found for ID: $contentId');
      }
      return null;
    }

    try {
      // Found the audio file, now fetch its content
      return await fetchContentById(
        audioFile.id,
        audioFile.language,
        audioFile.category,
      );
    } catch (e) {
      if (kDebugMode) {
        print('CacheService: Content not found for ID: $contentId');
      }
      return null;
    }
  }

  /// Pre-fetch content for multiple episodes (useful for preloading)
  @override
  Future<void> prefetchContent(List<AudioFile> audioFiles) async {
    if (audioFiles.isEmpty) return;

    if (kDebugMode) {
      print(
          'CacheService: Pre-fetching content for ${audioFiles.length} episodes');
    }

    final futures = audioFiles.map((audioFile) =>
        fetchContentById(audioFile.id, audioFile.language, audioFile.category));

    try {
      await Future.wait(futures);
      if (kDebugMode) {
        print(
            'CacheService: Pre-fetch completed, cached ${_contentCache.length} content items');
      }
    } catch (e) {
      if (kDebugMode) {
        print('CacheService: Pre-fetch failed: $e');
      }
    }
  }

  /// Pre-fetch content for episodes in a specific language
  @override
  Future<void> prefetchContentForLanguage(
      List<AudioFile> audioFiles, String language) async {
    final episodesForLanguage =
        audioFiles.where((episode) => episode.language == language).toList();

    if (episodesForLanguage.isEmpty) return;

    if (kDebugMode) {
      print(
          'CacheService: Pre-fetching content for ${episodesForLanguage.length} episodes in $language');
    }

    await prefetchContent(episodesForLanguage);
  }

  /// Pre-fetch content for episodes in a specific category
  @override
  Future<void> prefetchContentForCategory(
      List<AudioFile> audioFiles, String category) async {
    final episodesForCategory =
        audioFiles.where((episode) => episode.category == category).toList();

    if (episodesForCategory.isEmpty) return;

    if (kDebugMode) {
      print(
          'CacheService: Pre-fetching content for ${episodesForCategory.length} episodes in $category');
    }

    await prefetchContent(episodesForCategory);
  }

  /// Cache content manually (for testing or offline scenarios)
  void cacheContent(
      String id, String language, String category, AudioContent content) {
    final cacheKey = '$language/$category/$id';
    _contentCache[cacheKey] = content;

    if (kDebugMode) {
      print('CacheService: Manually cached content for $cacheKey');
    }
  }

  /// Remove specific content from cache
  @override
  bool removeFromCache(String id, String language, String category) {
    final cacheKey = '$language/$category/$id';
    final removed = _contentCache.remove(cacheKey) != null;

    if (kDebugMode && removed) {
      print('CacheService: Removed content from cache: $cacheKey');
    }

    return removed;
  }

  /// Clear content cache
  void clearContentCache() {
    final previousSize = _contentCache.length;
    _contentCache.clear();

    if (kDebugMode) {
      print('CacheService: Content cache cleared (was $previousSize items)');
    }
  }

  /// Clear cache for specific language
  @override
  void clearCacheForLanguage(String language) {
    final keysToRemove = _contentCache.keys
        .where((key) => key.startsWith('$language/'))
        .toList();

    for (final key in keysToRemove) {
      _contentCache.remove(key);
    }

    if (kDebugMode) {
      print(
          'CacheService: Cleared ${keysToRemove.length} cached items for language $language');
    }
  }

  /// Clear cache for specific category
  @override
  void clearCacheForCategory(String category) {
    final keysToRemove =
        _contentCache.keys.where((key) => key.contains('/$category/')).toList();

    for (final key in keysToRemove) {
      _contentCache.remove(key);
    }

    if (kDebugMode) {
      print(
          'CacheService: Cleared ${keysToRemove.length} cached items for category $category');
    }
  }

  /// Get cache statistics
  @override
  Map<String, dynamic> getCacheStatistics() {
    final stats = <String, dynamic>{
      'totalItems': _contentCache.length,
      'languages': <String, int>{},
      'categories': <String, int>{},
      'cacheKeys': _contentCache.keys.toList(),
    };

    // Analyze cache distribution
    for (final key in _contentCache.keys) {
      final parts = key.split('/');
      if (parts.length >= 3) {
        final language = parts[0];
        final category = parts[1];

        final languageStats = stats['languages'] as Map<String, int>;
        languageStats[language] = (languageStats[language] ?? 0) + 1;

        final categoryStats = stats['categories'] as Map<String, int>;
        categoryStats[category] = (categoryStats[category] ?? 0) + 1;
      }
    }

    return stats;
  }

  /// Check if content is cached
  @override
  bool isContentCached(String id, String language, String category) {
    final cacheKey = '$language/$category/$id';
    return _contentCache.containsKey(cacheKey);
  }

  /// Get cache memory usage estimate (in bytes)
  @override
  int getEstimatedCacheSize() {
    int totalSize = 0;
    for (final content in _contentCache.values) {
      // Rough estimate: title + description + references
      totalSize += (content.title.length +
              (content.description?.length ?? 0) +
              content.references.join('').length) *
          2; // UTF-16 encoding
    }
    return totalSize;
  }

  /// Clean up old cache entries (LRU-style cleanup)
  @override
  void cleanupCache({int maxItems = 100}) {
    if (_contentCache.length <= maxItems) return;

    final itemsToRemove = _contentCache.length - maxItems;
    final keysToRemove = _contentCache.keys.take(itemsToRemove).toList();

    for (final key in keysToRemove) {
      _contentCache.remove(key);
    }

    if (kDebugMode) {
      print('CacheService: Cleaned up $itemsToRemove old cache entries');
    }
  }

  /// Warm up cache with commonly accessed content
  @override
  Future<void> warmUpCache(List<AudioFile> priorityEpisodes) async {
    if (priorityEpisodes.isEmpty) return;

    if (kDebugMode) {
      print(
          'CacheService: Warming up cache with ${priorityEpisodes.length} priority episodes');
    }

    // Take only first few to avoid overwhelming the API
    final episodesToWarmUp = priorityEpisodes.take(10).toList();
    await prefetchContent(episodesToWarmUp);
  }

  /// Dispose of resources
  @override
  void dispose() {
    _contentCache.clear();
  }

  @visibleForTesting
  void setCacheForTesting(Map<String, AudioContent> cache) {
    _contentCache.clear();
    _contentCache.addAll(cache);
  }

  @visibleForTesting
  Map<String, AudioContent> getCacheForTesting() {
    return Map.unmodifiable(_contentCache);
  }
}

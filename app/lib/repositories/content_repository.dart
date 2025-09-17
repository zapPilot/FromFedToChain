import 'dart:async';
import '../models/audio_content.dart';
import '../models/audio_file.dart';

/// Abstract repository interface for content data access
/// Handles content fetching, caching, and management operations
abstract class ContentRepository {
  /// Fetch content by ID, language, and category
  Future<AudioContent?> fetchContentById(
      String id, String language, String category);

  /// Get content for an audio file
  Future<AudioContent?> getContentForAudioFile(AudioFile audioFile);

  /// Get cached content without fetching
  AudioContent? getCachedContent(String id, String language, String category);

  /// Get content by ID across all languages and categories
  Future<AudioContent?> getContentById(
      String contentId, List<AudioFile> allEpisodes);

  /// Pre-fetch content for multiple episodes
  Future<void> prefetchContent(List<AudioFile> audioFiles);

  /// Pre-fetch content for episodes in a specific language
  Future<void> prefetchContentForLanguage(
      List<AudioFile> audioFiles, String language);

  /// Pre-fetch content for episodes in a specific category
  Future<void> prefetchContentForCategory(
      List<AudioFile> audioFiles, String category);

  /// Cache content manually
  void cacheContent(
      String id, String language, String category, AudioContent content);

  /// Remove specific content from cache
  bool removeFromCache(String id, String language, String category);

  /// Clear content cache
  void clearContentCache();

  /// Clear cache for specific language
  void clearCacheForLanguage(String language);

  /// Clear cache for specific category
  void clearCacheForCategory(String category);

  /// Get cache statistics
  Map<String, dynamic> getCacheStatistics();

  /// Check if content is cached
  bool isContentCached(String id, String language, String category);

  /// Get cache memory usage estimate
  int getEstimatedCacheSize();

  /// Clean up old cache entries
  void cleanupCache({int maxItems = 100});

  /// Warm up cache with commonly accessed content
  Future<void> warmUpCache(List<AudioFile> priorityEpisodes);

  /// Dispose of resources
  void dispose();
}
